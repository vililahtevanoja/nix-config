# nix-config

Personal nix setup for different systems.

## Installation

- Install nix, e.g. with [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer).

- Install [Home Manager with flake setup](https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone)

## Commands

### Build

```home-manager build --flake .#<profile>```
->
```home-manager build --flake .#vili-rmbp```

### Switch

```home-manager switch --flake .#<profile>```
->
```home-manager switch --flake .#vili-rmbp```

### Update flake

```nix flake update```
