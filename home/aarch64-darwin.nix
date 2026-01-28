{
  nixpkgs,
  pkgs,
  lib,
  ...
}:
{
  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.local/bin"
  ];

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
    amazon-q-cli
    # kiro-cli # hold off for now
  ];

  # Shared settings for darwin (e.g., macOS)
}
