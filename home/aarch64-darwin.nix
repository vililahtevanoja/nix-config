{
  nixpkgs,
  pkgs,
  lib,
  ...
}:
let
  common-shell-aliases = {
    bubu = "brew update && brew upgrade";
  };
in
{
  programs.zsh = {
    initContent = lib.mkAfter ''
      path+=("$HOME/homebrew/bin" "$HOME/homebrew/sbin")
    '';
  };

  programs.fish = {
    interactiveShellInit = lib.mkAfter ''
      fish_add_path --append --path --move $HOME/homebrew/bin $HOME/homebrew/sbin
    '';
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "kiro-cli"
    ];

  # 1.24.0 hash is invalid, use newer 1.24.1 with correct hash for now
  nixpkgs.overlays = [
    (final: prev: {
      kiro-cli = prev.kiro-cli.overrideAttrs (old: {
        version = "1.24.1";
        src = prev.fetchurl {
          url = "https://desktop-release.q.us-east-1.amazonaws.com/1.24.1/Kiro%20CLI.dmg";
          sha256 = "sha256-1jCw2Ae53FVLJb8RpGX7GlSNybtkLqZ6plAy+zGJMSQ=";
        };
      });
    })
  ];

  # macOS (Apple Silicon) specific settings
  home.packages = with pkgs; [
    colima

    # LLM
    # kiro-cli # hold off for now
  ];

  programs.zsh.shellAliases = common-shell-aliases;

  programs.fish.shellAliases = common-shell-aliases;

  # Shared settings for darwin (e.g., macOS)
}
