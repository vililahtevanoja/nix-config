#!/usr/bin/env python3
"""Download configured documentation subpaths from GitHub repositories."""

from __future__ import annotations

import argparse
import os
import shutil
import sys
import tarfile
import tempfile
import time
import urllib.error
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


DOC_SOURCES = (
    DocSource(repo="ghostty-org/website", subpath="docs", alias="ghostty"),
    DocSource(repo="zellij-org/zellij-org.github.io", subpath="docs/src", alias="zellij")
)


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT_DIR = REPO_ROOT / ".local" / "docs"


def parse_args() -> DownloadDocsArgs:
    parser = argparse.ArgumentParser(
        description="Download configured documentation folders from GitHub."
    )
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


def github_tarball_url(source: DocSource) -> str:
    if source.ref:
        return f"https://api.github.com/repos/{source.repo}/tarball/{source.ref}"

    return f"https://api.github.com/repos/{source.repo}/tarball"


def request_headers() -> dict[str, str]:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "nix-config-doc-downloader",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"

    return headers


def validate_source(source: DocSource) -> None:
    if "/" not in source.repo or source.repo.startswith("/") or source.repo.endswith("/"):
        raise ValueError(f"{source.alias}: repo must look like 'owner/name'")

    alias_path = PurePosixPath(source.alias)
    if alias_path.is_absolute() or ".." in alias_path.parts or len(alias_path.parts) != 1:
        raise ValueError(f"{source.alias}: alias must be a single path segment")

    subpath = PurePosixPath(source.subpath)
    if (
        not source.subpath
        or subpath.is_absolute()
        or ".." in subpath.parts
        or "." in subpath.parts
    ):
        raise ValueError(f"{source.alias}: subpath must be a relative repository path")


def destination_for(output_dir: Path, source: DocSource) -> Path:
    destination = (output_dir / source.alias).resolve()
    output_root = output_dir.resolve()
    if destination.parent != output_root:
        raise ValueError(f"{source.alias}: destination escapes output directory")

    return destination


def extract_source(source: DocSource, output_dir: Path) -> None:
    started_at = time.perf_counter()
    validate_source(source)
    output_dir.mkdir(parents=True, exist_ok=True)

    destination = destination_for(output_dir, source)
    tmp_parent = tempfile.mkdtemp(prefix=f".{source.alias}-", dir=output_dir)
    tmp_destination = Path(tmp_parent) / source.alias
    tmp_destination.mkdir()

    matched = False
    request = urllib.request.Request(github_tarball_url(source), headers=request_headers())

    try:
        with urllib.request.urlopen(request) as response:
            with tarfile.open(fileobj=response, mode="r|gz") as archive:
                for member in archive:
                    relative_path = member_relative_path(member.name, source.subpath)
                    if relative_path is None:
                        continue

                    matched = True
                    extract_member(archive, member, tmp_destination, relative_path)

        if not matched:
            raise RuntimeError(f"{source.repo}: subpath '{source.subpath}' was not found")

        if destination.exists():
            shutil.rmtree(destination)
        tmp_destination.replace(destination)
        elapsed = time.perf_counter() - started_at
        print(
            f"{source.alias}: downloaded {source.repo}/{source.subpath} -> "
            f"{destination} ({elapsed:.2f}s)"
        )
    except urllib.error.HTTPError as error:
        message = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{source.alias}: GitHub returned HTTP {error.code}: {message}") from error
    finally:
        shutil.rmtree(tmp_parent, ignore_errors=True)


def member_relative_path(member_name: str, subpath: str) -> PurePosixPath | None:
    path = PurePosixPath(member_name)
    parts_without_archive_root = path.parts[1:]
    if not parts_without_archive_root:
        return None

    path_without_archive_root = PurePosixPath(*parts_without_archive_root)
    subpath_parts = PurePosixPath(subpath).parts
    if path_without_archive_root.parts[: len(subpath_parts)] != subpath_parts:
        return None

    relative_parts = path_without_archive_root.parts[len(subpath_parts) :]
    return PurePosixPath(*relative_parts) if relative_parts else PurePosixPath(".")


def extract_member(
    archive: tarfile.TarFile,
    member: tarfile.TarInfo,
    destination: Path,
    relative_path: PurePosixPath,
) -> None:
    target = (destination / Path(*relative_path.parts)).resolve()
    if destination.resolve() not in (target, *target.parents):
        raise RuntimeError(f"refusing to extract path outside destination: {member.name}")

    if member.isdir():
        target.mkdir(parents=True, exist_ok=True)
        return

    if not member.isfile():
        return

    target.parent.mkdir(parents=True, exist_ok=True)
    file_obj = archive.extractfile(member)
    if file_obj is None:
        raise RuntimeError(f"could not read archive member: {member.name}")

    with file_obj, target.open("wb") as output:
        shutil.copyfileobj(file_obj, output)


def main() -> int:
    args = parse_args()
    sources = [
        source
        for source in DOC_SOURCES
        if args.source is None or source.alias in args.source
    ]

    for source in sources:
        extract_source(source, args.output_dir)

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
