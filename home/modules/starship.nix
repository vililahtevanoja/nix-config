{ pkgs, lib, ... }:
{
  programs.starship = {
    enable = true;
    package = pkgs.starship;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = {
      direnv = {
        disabled = true; # pending https://github.com/starship/starship/pull/6389
        loaded_msg = "[✓](green)";
        allowed_msg = "[✓](green)";
      };
      vcs = {
        order = ["jj" "git"];
        jj_modules = "$jj_bookmark$jj_change$jj_metrics$jj_status";
      };
      # based on https://starship.rs/config/#default-prompt-format
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$kubernetes"
        "$directory"
        "$vcs"
        "$docker_context"
        "$package"
        "$c"
        "$helm"
        "$java"
        "$kotlin"
        "$gradle"
        "$nodejs"
        "$pulumi"
        "$python"
        "$rust"
        "$scala"
        "$swift"
        "$terraform"
        "$typst"
        "$zig"
        "$buf"
        "$nix_shell"
        "$aws"
        "$direnv"
        "$env_var"
        "$mise"
        "$custom"
        "$sudo"
        "$cmd_duration"
        "$line_break"
        "$time"
        "$status"
        "$container"
        "$shell"
        "$character"
      ];
    };
  };
}
