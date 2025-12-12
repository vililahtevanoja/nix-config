{
  pkgs,
  unstable,
  lib,
  ...
}:

let
  starship-jj = pkgs.rustPlatform.buildRustPackage rec {
    pname = "starship-jj";
    version = "0.7.0"; # Check for latest version on crates.io

    src = pkgs.fetchCrate {
      inherit pname version;
      hash = "sha256-oisz3V3UDHvmvbA7+t5j7waN9NykMUWGOpEB5EkmYew";
    };

    cargoHash = "sha256-NNeovW27YSK/fO2DjAsJqBvebd43usCw7ni47cgTth8";

  };
in
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # general tools
    git
    jujutsu # git alternative
    lazyjj # jujutsu TUI
    jq
    yq
    curl
    wget
    ripgrep
    fzf
    btop
    direnv
    hyperfine
    zstd
    parallel

    # database
    pgcli

    # containers
    docker
    docker-compose
    lazydocker

    # shell
    starship
    starship-jj

    # languages
    go
    rustup

    # nix
    nixfmt-rfc-style
    nh

    # zsh
    zsh-fzf-tab

    # LLM
    amazon-q-cli
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Vili Lähtevänoja";
        email = "3448875+vililahtevanoja@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      core = {
        editor = "nvim";
        commitGraph = true;
      };
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = true;
        renames = true;
      };
      column.ui = "auto";
      branch = {
        sort = "-committerdate";
      };
      tag.sort = "version:refname";
      push.autoSetupRemote = true;
      fetch = {
        prune = true;
        pruneTags = true;
        all = false;
      };
      merge.conflictstyle = "zdiff3";
      gc.writecommitGraph = true;
      alias."local-branches" =
        "!git branch --format '%(refname:short) %(upstream:short)' | awk '{if (!$2) print $1;}'";
    };
  };
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Vili Lähtevänoja";
        email = "3448875+vililahtevanoja@users.noreply.github.com";
      };
      ui = {
        editor = "nvim";
        default-command = "log";
      };
    };
  };
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "aws"
        "git"
        "fzf"
        "direnv"
        "jj"
      ];
    };
    shellAliases = {
      bubu = "brew update && brew upgrade";
      pn = "pnpm";
      vim = "nvim";
      weather = "curl 'wttr.in?M'";
      kalasatama = "curl 'wttr.in/~Kalasatama?M'";
      ".." = "cd ..";
      "..." = "cd ../..";
      q = "amazon-q";
      reload = ". ~/.zshrc";
    };
    # setup .zshrc contents
    initContent = lib.mkMerge [
      # Prettified `time` command output
      ''
        if [[ `uname` == Darwin ]]; then
          MAX_MEMORY_UNITS=KB
        else
          MAX_MEMORY_UNITS=MB
        fi

        TIMEFMT='%J   %U  user %S system %P cpu %*E total'$'\n'\
        'avg shared (code):         %X KB'$'\n'\
        'avg unshared (data/stack): %D KB'$'\n'\
        'total (sum):               %K KB'$'\n'\
        'max memory:                %M '$MAX_MEMORY_UNITS''$'\n'\
        'page faults from disk:     %F'$'\n'\
        'other page faults:         %R'
      ''
      "source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
      # setting to help with history
      ''
        export HISTSIZE=1000000
        export SAVEHIST=1000000
        setopt HIST_IGNORE_ALL_DUPS
        setopt HIST_FIND_NO_DUPS
        setopt HIST_REDUCE_BLANKS
      ''
      "ulimit -n 10240" # max is 10240
      # jujutsu autocompletion
      ''
        autoload -U compinit
        compinit
        source <(jj util completion zsh)
      ''
    ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
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
            "starship-jj"
            "--ignore-working-copy"
            "starship"
          ];
          use_stdin = false;
          format = "$output";
        };
        git_status = {
          when = "! jj --ignore-working-copy root";
          command = "starship module git_status";
          style = "";
          description = "Only show git_status if we're not in a jj repo";
        };
        git_state = {
          when = "! jj --ignore-working-copy root";
          command = "starship module git_state";
          style = "";
          description = "Only show git_state if we're not in a jj repo";
        };
        git_commit = {
          when = "! jj --ignore-working-copy root";
          command = "starship module git_commit";
          style = "";
          description = "Only show git_commit if we're not in a jj repo";
        };
        git_metrics = {
          when = "! jj --ignore-working-copy root";
          command = "starship module git_metrics";
          style = "";
          description = "Only show git_metrics if we're not in a jj repo";
        };
        git_branch = {
          when = "! jj --ignore-working-copy root";
          command = "starship module git_branch";
          style = "";
          description = "Only show git_branch if we're not in a jj repo";
        };

      };
      # based on https://starship.rs/config/#default-prompt-format
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$localip"
        "$shlvl"
        #"$singularity"
        "$kubernetes"
        "$directory"
        #"$vcsh"
        #"$fossil_branch"
        #"$fossil_metrics"
        "\${custom.jj}"
        "\${custom.git_branch}"
        "\${custom.git_commit}"
        "\${custom.git_state}"
        "\${custom.git_metrics}"
        "\${custom.git_status}"
        #"$hg_branch"
        #"$hg_state"
        #"$pijul_channel"
        "$docker_context"
        "$package"
        "$c"
        #"$cmake"
        #"$cobol"
        #"$daml"
        #"$dart"
        #"$deno"
        #"$dotnet"
        #"$elixir"
        #"$elm"
        #"$erlang"
        #"$fennel"
        #"$fortran"
        #"$gleam"
        "$golang"
        #"$guix_shell"
        "$haskell"
        #"$haxe"
        "$helm"
        "$java"
        #"$julia"
        "$kotlin"
        "$gradle"
        #"$lua"
        #"$nim"
        "$nodejs"
        #"$ocaml"
        #"$opa"
        #"$perl"
        #"$php"
        "$pulumi"
        #"$purescript"
        "$python"
        #"$quarto"
        #"$raku"
        #"$rlang"
        #"$red"
        #"$ruby"
        "$rust"
        "$scala"
        #"$solidity"
        "$swift"
        "$terraform"
        "$typst"
        #"$vlang"
        #"$vagrant"
        "$zig"
        "$buf"
        "$nix_shell"
        #"$conda"
        #"$meson"
        #"$spack"
        "$memory_usage"
        "$aws"
        #"$gcloud"
        #"$openstack"
        #"$azure"
        "$nats"
        "$direnv"
        "$env_var"
        "$mise"
        #"$crystal"
        "$custom"
        "$sudo"
        "$cmd_duration"
        "$line_break"
        "$jobs"
        "$battery"
        "$time"
        "$status"
        "$os"
        "$container"
        "$netns"
        "$shell"
        "$character"
      ];

    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraConfig = ''
      set tabstop=2
      set shiftwidth=2
      set expandtab
      set smartindent
    '';
  };
}
