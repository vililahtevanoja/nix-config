{ pkgs, lib, ... }:

let
  starship-jj = pkgs.rustPlatform.buildRustPackage rec {
    pname = "starship-jj";
    version = "0.7.0"; # Check for latest version on crates.io
    src = pkgs.fetchCrate {
      inherit pname version;
      hash = "sha256-oisz3V3UDHvmvbA7+t5j7waN9NykMUWGOpEB5EkmYew";
    };
    cargoHash = "sha256-NNeovW27YSK/fO2DjAsJqBvebd43usCw7ni47cgTth8";
    doCheck = false; # the tests are quite limited so not critical, but double the already long compilation time
    meta = {
      description = "Starship module to show the current status of a jj repository";
      mainProgram = "starship-jj";
    };
  };
in
{
  home.packages = [
    starship-jj
  ];

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = {
      direnv = {
        disabled = true; # pending https://github.com/starship/starship/pull/6389
        loaded_msg = "[✓](green)";
        allowed_msg = "[✓](green)";
      };
      custom = {
        jj = {
          description = "The current jj status";
          when = true;
          ignore_timeout = true;
          command = "prompt";
          shell = [
            (lib.getExe starship-jj)
            "--ignore-working-copy"
            "starship"
          ];
          use_stdin = false;
          format = "$output";
        };
        git_status = {
          when = "! ${lib.getExe starship-jj} --ignore-working-copy root";
          command = "starship module git_status";
          style = "";
          description = "Only show git_status if we're not in a jj repo";
        };
        git_state = {
          when = "! ${lib.getExe starship-jj} --ignore-working-copy root";
          command = "starship module git_state";
          style = "";
          description = "Only show git_state if we're not in a jj repo";
        };
        git_commit = {
          when = "! ${lib.getExe starship-jj} --ignore-working-copy root";
          command = "starship module git_commit";
          style = "";
          description = "Only show git_commit if we're not in a jj repo";
        };
        git_metrics = {
          when = "! ${lib.getExe starship-jj} --ignore-working-copy root";
          command = "starship module git_metrics";
          style = "";
          description = "Only show git_metrics if we're not in a jj repo";
        };
        git_branch = {
          when = "! ${lib.getExe starship-jj} --ignore-working-copy root";
          command = "starship module git_branch";
          style = "";
          description = "Only show git_branch if we're not in a jj repo";
        };
      };
      # based on https://starship.rs/config/#default-prompt-format
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$kubernetes"
        "$directory"
        "\${custom.jj}"
        "\${custom.git_branch}"
        "\${custom.git_commit}"
        "\${custom.git_state}"
        "\${custom.git_metrics}"
        "\${custom.git_status}"
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
