{ pkgs, ... }:
{
  home.sessionPath = [
    "$HOME/bin"
  ];

  # macOS (Apple Silicon) specific settings
  home.packages = with pkgs; [
    colima
  ];

  # Shared settings for darwin (e.g., macOS)
}
