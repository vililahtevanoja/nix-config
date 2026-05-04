{
  config,
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
    doCheck = false; # the tests are quite limited so not critical, but double the already long compilation time
    meta = {
      description = "Starship module to show the current status of a jj repository";
      mainProgram = "starship-jj";
    };
  };
  zsh-patina = pkgs.rustPlatform.buildRustPackage rec {
    pname = "zsh-patina";
    version = "1.5.1"; # Check for latest version on crates.io
    src = pkgs.fetchCrate {
      inherit pname version;
      hash = "sha256-Gd4nW1a6OmRWtSeE9vQ+H1Y1oyG6/fE7wFO90Z+kGjE=";
    };
    cargoHash = "sha256-bhkiSSe/z1ms6hcIU5BAczPywTmSnXhtIdKxKXyTU30=";
    useNextest = true;
    meta = {
      description = "Zsh plugin for fast syntax highlighting";
      mainProgram = "zsh-patina";
    };
  };
  common-shell-aliases = {
    pn = "pnpm";
    ll = "ls -lh";
    l = "ls -alh";
    vim = "nvim";
    weather = "curl 'wttr.in?M'";
    kalasatama = "curl 'wttr.in/~Kalasatama?M'";
    ".." = "cd ..";
    "..." = "cd ../..";

    # Nix Home Manager aliases
    nhb = "nh home build .";
    nhs = "nh home switch .";
    nfc = "nix flake check";
    nfu = "nix flake update";
  };
  zshDotDir = "${config.xdg.configHome}/zsh";
in
{
  fonts.fontconfig.enable = true;

  xdg.enable = true;
  xdg.configFile."ghostty/config.ghostty".source = ../files/ghostty-config;

  home.sessionVariables = {
    ZDOTDIR = zshDotDir;
  };

  nixpkgs.overlays = [
    # Temporary workaround: cli-helpers tests currently fail on Python 3.13,
    # which breaks pgcli transitively during Home Manager builds.
    (final: prev: {
      python3Packages = prev.python3Packages.overrideScope (
        pyFinal: pyPrev: {
          cli-helpers = pyPrev.cli-helpers.overridePythonAttrs (_: {
            doCheck = false;
          });
          # Temporary workaround: aioboto3 test suite currently fails with
          # "Duplicate 'Server' header found" on Python 3.13.
          aioboto3 = pyPrev.aioboto3.overridePythonAttrs (_: {
            doCheck = false;
          });
        }
      );
      pgcli = final.python3Packages.pgcli;
    })
  ];

  home.packages = with pkgs; [
    # general tools
    git
    jujutsu # git alternative
    lazyjj # jujutsu TUI
    jq # command-line JSON processor
    yq # command-line YAML processor
    curl
    wget
    ripgrep # fast search tool
    fzf # fuzzy finder
    btop # resource monitor
    direnv
    hyperfine # benchmarking tool
    zstd # powerful compression
    parallel # run commands in parallel
    duf
    oxfmt # formatter
    glow # CLI markdown viewer
    bat
    tree
    htop

    # editors
    helix

    # diff tools
    delta
    difftastic
    diff-so-fancy

    # reproducible development environments
    devenv

    # multiplexing
    zellij
    tmux

    # VCS provider clients
    gh
    glab

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
    nodejs_24
    pnpm
    typescript-go
    python314
    uv

    # nix
    nixfmt
    nh
    # mcp-nixos # currently not working, try again later

    # zsh
    zsh-fzf-tab

    # LLM
    opencode
    codex
    claude-code
    github-copilot-cli
    gemini-cli-bin

    # document tools
    pandoc
    typst
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
        external = (lib.getExe pkgs.difftastic);
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
      alias = {
        "local-branches" =
          "!git branch --format '%(refname:short) %(upstream:short)' | awk '{if (!$2) print $1;}'";
      };
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
        # using difftastic for now
        diff-formatter = [
          (lib.getExe pkgs.difftastic)
          "--color=always"
          "$left"
          "$right"
        ];

        # delta option
        # pager = "delta";
        # diff-formatter = ":git";

        # diff-so-fancy option
        # pager = ["sh" "-c" "diff-so-fancy | less -RFX"];
      };
      aliases = {
        tug = [
          "bookmark"
          "move"
          "--from"
          "heads(::@- & bookmarks())"
          "--to"
          "@-"
        ];
        # print the name of the current git branch
        current-git-branch = [
          "log"
          "-r"
          "heads(bookmarks() & ::@)"
          "-n"
          "1"
          "--no-graph"
          "--no-pager"
          "-T"
          "bookmarks"
        ];
        # abandon dangling bookmarks and working copies that are not reachable from any heads or tags
        abandon-dangling = [
          "abandon"
          "-r"
          "mutable() ~ ::bookmarks() ~ ::working_copies()"
        ];
      };
    };
  };
  programs.zsh = {
    enable = true;
    dotDir = zshDotDir;
    syntaxHighlighting.enable = false;
    autosuggestion.enable = true;
    historySubstringSearch.enable = true;
    enableCompletion = true;
    antidote = {
      enable = true;
      plugins = [
        ''
          mattmc3/ez-compinit
          zsh-users/zsh-autosuggestions
          ohmyzsh/ohmyzsh path:lib/git.zsh
          ohmyzsh/ohmyzsh path:plugins/git
          ohmyzsh/ohmyzsh path:plugins/fzf
          ohmyzsh/ohmyzsh path:plugins/direnv
        ''
      ];
    };
    shellAliases = common-shell-aliases // {
      zshrc = "${lib.getExe pkgs.bat} ${zshDotDir}/.zshrc";
      reload = ". ${zshDotDir}/.zshrc";
    };
    history = {
      size = 1000000;
      save = 1000000;
      ignoreAllDups = true;
      findNoDups = true;
      ignoreSpace = true;
    };
    # setup .zshrc contents
    initContent = lib.mkMerge [
      # ensure stale starship keymap widget wrappers are removed before starship init
      # ref: https://github.com/starship/starship/issues/3418
      # potential fix: https://github.com/starship/starship/pull/6398
      (lib.mkBefore ''
        if [[ "''${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select" || \
              "''${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select-wrapped" ]]; then
          zle -N zle-keymap-select ""
        fi
      '')
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
        setopt HIST_REDUCE_BLANKS
      ''
      # increase ulimit to reduce errors from too many open files
      "ulimit -n 10240" # max is 10240
      # enable dynamic completions for jj (jujutsu). ref: https://docs.jj-vcs.dev/latest/install-and-setup/#dynamic-completions
      ''
        source <(COMPLETE=zsh ${lib.getExe pkgs.jujutsu})
      ''
      # fix Home and End button behavior
      ''
        bindkey '^[[H' beginning-of-line
        bindkey '^[[F' end-of-line
      ''
      # utility functions
      ''
        # make directory and move there
        mkcd() {
          mkdir -p "$1" && cd "$1"
        }
        # find files fast
        # e.g. `ff .md` to find markdown files
        ff() {
          ${lib.getExe pkgs.ripgrep} --files -g "*$1*" -i
        }
        # view file tree
        tre() {
          ${lib.getExe pkgs.tree} -aC -I '.git|.jj|.turbo|.terraform|.idea|node_modules|vendor|__pycache__|cdk.out|coverage|.tanstack|temp|.cache|.direnv' --dirsfirst "$@" | less -FRNX
        }
      ''
      # enable zsh-patina (fast zsh highlighter)
      ''
        # Reference the executable direcly
        eval "$(${lib.getExe zsh-patina} activate)"
      ''
    ];
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
    shellAliases = common-shell-aliases;
    plugins = with pkgs; [
      # Fish function making it easy to use utilities written for Bash in Fish shell
      {
        name = "bass";
        src = fishPlugins.bass.src;
      }
    ];
  };

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
            "starship-jj"
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = false;
    withRuby = false;

    plugins = with pkgs.vimPlugins; [
      nui-nvim
      hardtime-nvim
    ];

    initLua = ''
      require("hardtime").setup({})
    '';

    extraConfig = ''
      set tabstop=2
      set shiftwidth=2
      set expandtab
      set smartindent
    '';
  };

  programs.helix = {
    enable = true;

    languages.language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = lib.getExe pkgs.nixfmt;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }
    ];
  };

  programs.zellij = {
    enable = true;
    layouts = {
      three-pane = ''
        layout {
            default_tab_template {
                pane size=1 borderless=true {
                    plugin location="zellij:tab-bar"
                }
                children
                pane size=2 borderless=true {
                    plugin location="zellij:status-bar"
                }
            }
            tab {
                pane split_direction="vertical" {
                    pane
                    pane split_direction="horizontal" {
                        pane
                        pane
                    }
                }
            }
        }
      '';
    };
    extraConfig = ''
      default_shell "${lib.getExe pkgs.zsh}"
      keybinds {
          unbind "Ctrl q"
          shared_except "locked" {
              bind "Ctrl Shift q" { Quit; }
          }
      }
    '';
    enableZshIntegration = false;
  };
}
