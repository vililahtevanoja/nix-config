# nix-config

Personal Home Manager flake setup for multiple machines (macOS + Linux).

## What's inside

- Home Manager configurations for systems in personal use:
  - macOS (Apple Silicon): `vililahtevanoja@vili-rmbp`
  - Linux x86_64: `vili@ViliPC`
  - Linux aarch64 (Raspberry Pi): `vili@raspberrypi`
- Shared user tooling and shell setup in `home/shared.nix`
- OS-specific additions in `home/aarch64-darwin.nix`, `home/x86_64-linux.nix`, `home/aarch64-linux.nix`
- Dev flake examples under `dev-flakes/`

## Layout

```text
.
├─ flake.nix
├─ home/
│  ├─ shared.nix                # shared config for all environments
│  ├─ shared-linux.nix          # linux specific
│  ├─ aarch64-darwin.nix        # MacOS specific
│  ├─ x86_64-linux.nix          
│  └─ aarch64-linux.nix
└─ dev-flakes/
   └─ nodejs-version-pinned.nix
```

## Installation

1. Install Nix, e.g. with the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer).
2. Install [Home Manager with flake setup](https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone).

## Usage

### For current system

Assumes that you are running in system for which there is a configuration here.

#### Build

```
nh build .
```

#### Switch (apply)

```
nh switch .
```

## Update inputs

```
nix flake update
```

## Home Manager profiles

For building a specific profile, pick a profile from `flake.nix` and apply it directly, e.g.:

```
home-manager build --flake .#vililahtevanoja@vili-rmbp
```

## Shared configuration highlights

- Tooling: git, jujutsu, lazyjj, fzf, ripgrep, direnv, btop, docker, pgcli, etc.
- Languages: Go, Rust (via rustup), Node.js 24, TypeScript (tsgo)
- Shell: Zsh with antidote plugins, aliases, history settings, fzf-tab, jj completion
- Prompt: Starship with jj-aware git status modules
- Editor: Neovim defaults (2-space indent, expandtab)

## Dev flakes

Contains examples for use in dev-flakes for different usecases.

### Node.js pinned shell

`dev-flakes/nodejs-version-pinned.nix` provides a `nix shell` with a prebuilt, pinned Node.js version.

```
nix develop ./dev-flakes/nodejs-version-pinned.nix
```
