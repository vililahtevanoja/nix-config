# AGENTS.md

This file defines guidance for AI agents working in this repository.

## Repo context

- Primary language/config: Nix (flakes, Home Manager, and related modules).
- Workspace root: repository root
- `TODO.md` contains a list of todos that we want to tackle in the future

## Goals

- Keep changes minimal and scoped by default. However, if a larger refactoring significantly improves structure, maintainability, or clarity, propose it to the user rather than working around it.
- Preserve existing conventions and formatting.
- Prefer idempotent, declarative Nix patterns.
- Document non-obvious behavior with concise comments.

## Working agreements

- Read existing modules before introducing new ones.
- Prefer editing existing modules over adding new files unless it improves structure.
- Avoid non-ASCII characters unless the file already uses them.
- If a change affects multiple hosts or profiles, call that out explicitly.
- Do not remove user-specific settings without confirmation.

## Nix-specific guidance

- Keep attribute ordering consistent with nearby code.
- Use `lib` helpers already in the repo when available.
- Avoid duplicate definitions; factor shared logic into common modules.
- Prefer `mkIf`/`mkMerge` patterns for conditional config.
- Keep derivations pinned; avoid introducing unpinned sources.
- Avoid hard-coding references to binaries, and prefer using programmatic references to them. (e.g. `lib.getExe pkgs.jujutsu` vs. `jj`)

## Testing/verification

- Always run `nix flake check`.
- Always run `nh home build .`.
- Always run `nixfmt **/*.nix` after any changes to files.
- If Home Manager changes, suggest running `home-manager switch` for relevant profile.
- If tests fail, inform the user of the error, investigate the cause, and suggest mitigations before proceeding.

## Communication

- Summarize changes and note impacted files.
- Ask for confirmation before destructive actions.
- When goals conflict or priorities are unclear, ask the user for guidance rather than making assumptions.

## GitHub nixpkgs exploration

- Use GitHub MCP to find information about the NixOS/nixpkgs repository
- Dependency updates go through NixOS/nixpkgs pull requests with PR naming `<dependency name>: <old version> -> <new version>`
