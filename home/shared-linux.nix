{
  config,
  pkgs,
  lib,
  ...
}:

# path to home-manager-managed zsh binary
let
  zshBin = "${config.home.profileDirectory}/bin/zsh";
in
{
  home.packages = with pkgs; [

  ];

  home.sessionVariables = {
    # Keep child processes aligned with the Home Manager-managed zsh binary.
    SHELL = zshBin;
  };

  home.sessionPath = [
    "/snap/bin"
    "${config.home.profileDirectory}/bin"
    "/usr/local/bin"
  ];

  programs.zsh.initContent = lib.mkBefore ''
    # Re-exec into the Nix-managed zsh before loading native plugins.
    if [[ -z ''${ZSH_NIX_REEXEC-} && -x ${zshBin} ]]; then
      current_zsh=$(readlink -f /proc/$$/exe 2>/dev/null || true)
      if [[ $current_zsh != ${zshBin} ]]; then
        export ZSH_NIX_REEXEC=1
        exec ${zshBin}
      fi
    fi
  '';
}
