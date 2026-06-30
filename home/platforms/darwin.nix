{
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
      path+=("/opt/homebrew/bin" "/opt/homebrew/sbin")
    '';
  };

  programs.fish = {
    interactiveShellInit = lib.mkAfter ''
      fish_add_path --append --path --move /opt/homebrew/bin /opt/homebrew/sbin
    '';
  };

  # macOS (Apple Silicon) specific packages
  home.packages = with pkgs; [
    colima
  ];

  programs.zsh.shellAliases = common-shell-aliases;

  programs.fish.shellAliases = common-shell-aliases;

}
