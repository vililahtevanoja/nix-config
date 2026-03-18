{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [

  ];

  home.sessionVariables = {
    # Keep child processes aligned with the Home Manager-managed zsh binary.
    SHELL = "${config.home.profileDirectory}/bin/zsh";
  };

  home.sessionPath = [
    "/snap/bin"
    "$home/bin"
    "/usr/local/bin"
  ];

  programs.zsh.initContent = lib.mkBefore ''
    # Re-exec into the Nix-managed zsh before loading native plugins.
    if [[ -z ''${ZSH_NIX_REEXEC-} && -x ${config.home.profileDirectory}/bin/zsh ]]; then
      current_zsh=$(readlink -f /proc/$$/exe 2>/dev/null || true)
      if [[ $current_zsh != ${config.home.profileDirectory}/bin/zsh ]]; then
        export ZSH_NIX_REEXEC=1
        exec ${config.home.profileDirectory}/bin/zsh
      fi
    fi
  '';
}
