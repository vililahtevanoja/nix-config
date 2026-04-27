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
      path+=("/opt/homebrew/bin" "/opt/homebrew/sbin")
    '';
  };

  programs.fish = {
    interactiveShellInit = lib.mkAfter ''
      fish_add_path --append --path --move /opt/homebrew/bin /opt/homebrew/sbin
    '';
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "kiro-cli"
    ];

  # 1.24.0 hash is invalid, use newer 1.24.1 with correct hash for now
  nixpkgs.overlays = [
    # Temporary workaround: cli-helpers tests currently fail on Darwin/Python 3.13,
    # which breaks pgcli transitively during Home Manager builds.
    (final: prev: {
      python3Packages = prev.python3Packages.overrideScope (
        pyFinal: pyPrev: {
          cli-helpers = pyPrev.cli-helpers.overridePythonAttrs (_: {
            doCheck = false;
          });
          # Temporary workaround: aioboto3 test suite currently fails with
          # "Duplicate 'Server' header found" on Darwin/Python 3.13.
          aioboto3 = pyPrev.aioboto3.overridePythonAttrs (_: {
            doCheck = false;
          });
        }
      );
      pgcli = final.python3Packages.pgcli;
      # fix for zsh hangs on Darwin, e.g. direnv tests would hang without this
      # ref: https://github.com/NixOS/nixpkgs/issues/513019 & https://github.com/NixOS/nixpkgs/issues/513543
      # fixed in:  https://github.com/NixOS/nixpkgs/pull/513971 (https://nixpk.gs/pr-tracker.html?pr=513971)
      zsh = prev.zsh.overrideAttrs (
        old:
        prev.lib.optionalAttrs prev.stdenv.isDarwin {
          preConfigure = (old.preConfigure or "") + ''
            export zsh_cv_sys_sigsuspend=yes
          '';
        }
      );
    })
  ];

  # macOS (Apple Silicon) specific packages
  home.packages = with pkgs; [
    colima

    # LLM
    # kiro-cli # hold off for now
  ];

  programs.zsh.shellAliases = common-shell-aliases;

  programs.fish.shellAliases = common-shell-aliases;

}
