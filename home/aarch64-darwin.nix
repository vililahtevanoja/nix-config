{ nixpkgs, pkgs, lib, ... }:
{
  home.sessionPath = [
    "$HOME/bin"
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "kiro-cli"
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
