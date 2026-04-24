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
      direnv = prev.direnv.overrideAttrs (_: {
        doCheck = false;
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
