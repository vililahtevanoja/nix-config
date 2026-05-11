#!/usr/bin/env python3
"""Download configured documentation subpaths from GitHub repositories."""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import shutil
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path, PurePosixPath


@dataclass(frozen=True)
class DocSource:
    repo: str
    subpath: str
    alias: str
    ref: str | None = None


@dataclass(frozen=True)
class DownloadDocsArgs:
    output_dir: Path
    source: list[str] | None


@dataclass(frozen=True)
class GitTreeEntry:
    path: PurePosixPath
    type: str


DOC_SOURCES = (
    # Keep each source scoped to the public docs subtree so the local cache stays
    # small and avoids copying unrelated repository content.
    DocSource(repo="ghostty-org/website", subpath="docs", alias="ghostty"),
    DocSource(repo="zellij-org/zellij-org.github.io", subpath="docs/src", alias="zellij"),
)


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT_DIR = REPO_ROOT / ".local" / "docs"
MAX_DOWNLOAD_WORKERS = 16


def parse_args() -> DownloadDocsArgs:
    parser = argparse.ArgumentParser(description="Download configured documentation folders from GitHub.")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"directory for downloaded docs (default: {DEFAULT_OUTPUT_DIR})",
    )
    parser.add_argument(
        "--source",
        action="append",
        choices=[source.alias for source in DOC_SOURCES],
        help="alias to download; may be passed more than once (default: all)",
    )
    args = parser.parse_args()
    return DownloadDocsArgs(output_dir=args.output_dir, source=args.source)


def request_headers() -> dict[str, str]:
    # GitHub allows unauthenticated requests, but a token raises the rate limit
    # for repeated doc refreshes.
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "nix-config-doc-downloader",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"

    return headers


def github_api_json(url: str) -> object:
    request = urllib.request.Request(url, headers=request_headers())
    try:
        with urllib.request.urlopen(request) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        message = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"GitHub returned HTTP {error.code}: {message}") from error
    except urllib.error.URLError as error:
        raise RuntimeError(f"could not read GitHub API URL {url}: {error.reason}") from error


def github_default_branch(source: DocSource) -> str:
    url = f"https://api.github.com/repos/{source.repo}"
    data = github_api_json(url)
    if not isinstance(data, dict) or not isinstance(data.get("default_branch"), str):
        raise RuntimeError(f"{source.alias}: could not determine default branch")

    return data["default_branch"]


def source_ref(source: DocSource) -> str:
    return source.ref if source.ref else github_default_branch(source)


def github_tree_entries(source: DocSource, ref: str) -> list[GitTreeEntry]:
    quoted_ref = urllib.parse.quote(ref, safe="")
    url = f"https://api.github.com/repos/{source.repo}/git/trees/{quoted_ref}?recursive=1"
    data = github_api_json(url)
    if not isinstance(data, dict) or not isinstance(data.get("tree"), list):
        raise RuntimeError(f"{source.alias}: could not read repository tree")

    if data.get("truncated"):
        raise RuntimeError(f"{source.alias}: GitHub tree response was truncated")

    subpath = PurePosixPath(source.subpath)
    entries = []
    for item in data["tree"]:
        # The recursive tree contains every repository path. Keep only entries
        # beneath the configured docs subpath, then strip that prefix so writes
        # are relative to the local alias directory.
        if not isinstance(item, dict):
            continue

        item_path = item.get("path")
        item_type = item.get("type")
        if not isinstance(item_path, str) or not isinstance(item_type, str):
            continue

        path = PurePosixPath(item_path)
        if path.parts[: len(subpath.parts)] != subpath.parts:
            continue

        relative_parts = path.parts[len(subpath.parts) :]
        if not relative_parts:
            continue

        entries.append(GitTreeEntry(path=PurePosixPath(*relative_parts), type=item_type))

    return entries


def validate_source(source: DocSource) -> None:
    # Sources are static today, but validation keeps future additions from
    # accidentally writing outside the intended output layout.
    if "/" not in source.repo or source.repo.startswith("/") or source.repo.endswith("/"):
        raise ValueError(f"{source.alias}: repo must look like 'owner/name'")

    alias_path = PurePosixPath(source.alias)
    if alias_path.is_absolute() or ".." in alias_path.parts or len(alias_path.parts) != 1:
        raise ValueError(f"{source.alias}: alias must be a single path segment")

    subpath = PurePosixPath(source.subpath)
    if not source.subpath or subpath.is_absolute() or ".." in subpath.parts or "." in subpath.parts:
        raise ValueError(f"{source.alias}: subpath must be a relative repository path")


def destination_for(output_dir: Path, source: DocSource) -> Path:
    destination = (output_dir / source.alias).resolve()
    output_root = output_dir.resolve()
    # The alias must map to a direct child of the output directory.
    if destination.parent != output_root:
        raise ValueError(f"{source.alias}: destination escapes output directory")

    return destination


def target_for(destination: Path, relative_path: PurePosixPath) -> Path:
    target = (destination / Path(*relative_path.parts)).resolve()
    # Resolve the final path before writing so odd paths cannot escape the
    # temporary destination through traversal or symlinks.
    if destination.resolve() not in (target, *target.parents):
        raise RuntimeError(f"refusing to write path outside destination: {relative_path}")

    return target


def raw_github_url(source: DocSource, ref: str, relative_path: PurePosixPath) -> str:
    file_path = source_file_path(source, relative_path)
    quoted_ref = urllib.parse.quote(ref, safe="")
    quoted_path = urllib.parse.quote(file_path.as_posix(), safe="/")
    return f"https://raw.githubusercontent.com/{source.repo}/{quoted_ref}/{quoted_path}"


def source_file_path(source: DocSource, relative_path: PurePosixPath) -> PurePosixPath:
    return PurePosixPath(source.subpath, *relative_path.parts)


def download_file(source: DocSource, ref: str, destination: Path, relative_path: PurePosixPath) -> None:
    target = target_for(destination, relative_path)
    target.parent.mkdir(parents=True, exist_ok=True)

    url = raw_github_url(source, ref, relative_path)
    request = urllib.request.Request(url, headers=request_headers())
    try:
        with urllib.request.urlopen(request) as response:
            with target.open("wb") as output:
                shutil.copyfileobj(response, output)
    except urllib.error.HTTPError as error:
        message = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(
            f"{source.alias}: failed to download {source.repo}/"
            f"{source_file_path(source, relative_path)}: "
            f"HTTP {error.code}: {message}"
        ) from error
    except urllib.error.URLError as error:
        raise RuntimeError(
            f"{source.alias}: failed to download {source.repo}/"
            f"{source_file_path(source, relative_path)} from {url}: {error.reason}"
        ) from error


def extract_source(source: DocSource, output_dir: Path) -> None:
    started_at = time.perf_counter()
    validate_source(source)
    output_dir.mkdir(parents=True, exist_ok=True)

    destination = destination_for(output_dir, source)
    # Download into a hidden sibling first. The final replace leaves either the
    # previous cache or the completed new cache on disk if a download fails.
    tmp_parent = tempfile.mkdtemp(prefix=f".{source.alias}-", dir=output_dir)
    tmp_destination = Path(tmp_parent) / source.alias
    tmp_destination.mkdir()

    try:
        ref = source_ref(source)
        entries = github_tree_entries(source, ref)
        directories = [entry.path for entry in entries if entry.type == "tree"]
        files = [entry.path for entry in entries if entry.type == "blob"]

        if not directories and not files:
            raise RuntimeError(f"{source.repo}: subpath '{source.subpath}' was not found")

        for directory in directories:
            target_for(tmp_destination, directory).mkdir(parents=True, exist_ok=True)

        # File downloads are independent; parallelism keeps full doc refreshes
        # fast while still capping worker count for small sources.
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=min(MAX_DOWNLOAD_WORKERS, max(len(files), 1))
        ) as executor:
            futures = [executor.submit(download_file, source, ref, tmp_destination, file_path) for file_path in files]
            for future in concurrent.futures.as_completed(futures):
                future.result()

        if destination.exists():
            shutil.rmtree(destination)
        tmp_destination.replace(destination)
        elapsed = time.perf_counter() - started_at
        print(
            f"{source.alias}: downloaded {source.repo}/{source.subpath} -> "
            f"{destination} ({len(files)} files, {elapsed:.2f}s)"
        )
    except urllib.error.HTTPError as error:
        message = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{source.alias}: GitHub returned HTTP {error.code}: {message}") from error
    finally:
        shutil.rmtree(tmp_parent, ignore_errors=True)


def main() -> int:
    args = parse_args()
    sources = [source for source in DOC_SOURCES if args.source is None or source.alias in args.source]

    for source in sources:
        extract_source(source, args.output_dir)

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
