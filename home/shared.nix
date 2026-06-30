{ pkgs, lib, ... }:

let
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
in
{
  imports = [
    ./modules/git.nix
    ./modules/jujutsu.nix
    ./modules/starship.nix
    ./modules/zsh.nix
  ];

  _module.args = {
    inherit common-shell-aliases;
  };

  fonts.fontconfig.enable = true;

  xdg.enable = true;
  xdg.configFile."glow/glow.yml".source = ../files/glow.yml;
  xdg.configFile."ghostty/config.ghostty".source = ../files/ghostty-config;

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

    # languages
    go
    rustup
    nodejs_24
    pnpm
    typescript-go
    python314
    uv
    ruff

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
