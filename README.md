# nix-config

Personal Home Manager flake setup for multiple machines (macOS + Linux), plus a
NixOS system and SD image for a Raspberry Pi 4.

## What's inside

- Home Manager configurations for systems in personal use:
  - macOS (Apple Silicon): `vililahtevanoja@vili-rmbp`
  - Linux x86_64: `vili@ViliPC`
  - Linux aarch64 (Raspberry Pi): `vili@raspberrypi`
- Shared user tooling and shell setup in `home/shared.nix`
- Program modules in `home/modules/`
- OS-specific additions in `home/platforms/`
- Host-specific additions in `home/hosts/`
- Dev flake examples under `dev-flakes/`
- Raspberry Pi 4 NixOS configuration in `hosts/raspberrypi.nix`

## Layout

```text
.
├─ flake.nix
├─ home/
│  ├─ shared.nix                # shared config and module imports
│  ├─ modules/
│  │  ├─ git.nix
│  │  ├─ jujutsu.nix
│  │  ├─ starship.nix
│  │  └─ zsh.nix
│  ├─ platforms/
│  │  ├─ darwin.nix
│  │  └─ linux.nix
│  └─ hosts/
│     ├─ raspberrypi.nix
│     ├─ vili-pc.nix
│     └─ vili-rmbp.nix
├─ hosts/
│  └─ raspberrypi.nix         # NixOS system and SD image settings
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

## Raspberry Pi 4: install NixOS from Raspberry Pi OS

The `nixosConfigurations.raspberrypi` output uses the existing locked `unstable`
input's AArch64 SD image module, including Raspberry Pi firmware and U-Boot.
It enables Ethernet DHCP, `raspberrypi.local` discovery, and SSH access as `vili`
using the public key in `hosts/raspberrypi.nix`. Password and root SSH login are
disabled. The `vili` account has passwordless sudo and is a trusted Nix user for
remote deployments; this key therefore grants administrator access.

The existing Home Manager profiles remain separate. This initial image contains
the operating system and access tools; it does not install the Home Manager
package collection or copy data from Raspberry Pi OS.

### Get the configuration on the Pi

After committing and pushing changes from the PC, clone the repository on the Pi:

```sh
git clone https://github.com/vililahtevanoja/nix-config.git ~/nix-config-nixos
```

For an existing checkout, run `git pull --ff-only` inside it instead.

### Build on the Pi, while it still runs Raspberry Pi OS

Run as `vili` on the Pi, which must already have Nix and a 64-bit userspace:

```sh
cd ~/nix-config-nixos
nix --extra-experimental-features 'nix-command flakes' build \
  'path:.#nixosConfigurations.raspberrypi.config.system.build.sdImage' \
  --out-link result-sd --max-jobs 2 --cores 2 -L
```

`path:.` also includes newly added files when working in an uncommitted Git
checkout. Keep `flake.lock` unchanged to build the validated dependency versions.
Run the build in `tmux` or `screen` if available so an SSH disconnect does not
interrupt it. No disk is reformatted by this build.

The output is `result-sd/sd-image/nixos-raspberrypi.img`. Record a checksum:

```sh
cd ~/nix-config-nixos/result-sd/sd-image
sha256sum nixos-raspberrypi.img > ~/nixos-raspberrypi.img.sha256
```

### Copy the image back before removing the SD card

On the WSL PC:

```sh
mkdir -p ~/Downloads/nixos-raspberrypi
cd ~/Downloads/nixos-raspberrypi
scp vili@raspberrypi.local:nix-config-nixos/result-sd/sd-image/nixos-raspberrypi.img .
scp vili@raspberrypi.local:nixos-raspberrypi.img.sha256 .
sha256sum -c nixos-raspberrypi.img.sha256
```

Back up any files, service data, and credentials you need from Raspberry Pi OS to
the PC. With only one SD card, a full card backup made while the Pi is shut down
also provides a way to restore the previous OS. The generated NixOS image is not
a backup of Raspberry Pi OS.

After verifying the image and backups, shut the Pi down with `sudo poweroff`.
Remove its SD card and connect it to the Windows PC. Copy the `.img` from WSL to
a Windows folder, then use Windows Raspberry Pi Imager's **Use custom** option
to select it. Select the SD card carefully: writing the image erases its contents.
Skip Imager's OS customization; the NixOS image already defines networking and SSH.

Insert the card into the Pi, connect Ethernet, and power it on. The root filesystem
expands to fill the card on first boot. Connect with:

```sh
ssh vili@raspberrypi.local
sudo -n true
```

The new OS generates new SSH host keys, so SSH may report that the host identity
changed. Confirm the Pi's address in your router (or verify its new host-key
fingerprint from a local console), then remove the old entry with
`ssh-keygen -R raspberrypi.local` and reconnect. If `.local` discovery fails, use
the DHCP address shown by your router. There is no initial console password;
after connecting by key, `sudo passwd vili` can set one without enabling SSH
password authentication.

### Manage NixOS remotely from WSL

From this repository on WSL, use `nixos-rebuild` from the same pinned input:

```sh
nix shell --inputs-from path:. unstable#nixos-rebuild-ng --command \
  nixos-rebuild switch --flake 'path:.#raspberrypi' \
  --build-host vili@raspberrypi.local \
  --target-host vili@raspberrypi.local --sudo
```

The PC evaluates the configuration, the Pi builds ARM packages, and the result
is activated on the Pi. Future changes do not require reflashing the SD card.
For changes to SSH or networking, use `test` in place of `switch` first and check
a second SSH connection before deploying with `switch`. `test` does not change
the next boot's default generation, but it does not automatically undo a lost
connection either. Keep physical recovery available for boot-related changes.

If the Pi remains reachable, revert the last system deployment on the Pi with:

```sh
sudo nixos-rebuild switch --rollback
```
