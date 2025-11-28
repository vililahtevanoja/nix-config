{
  pkgs,
  unstable,
  lib,
  ...
}:
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

    # shell
    oh-my-zsh
    zsh-powerlevel10k

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
      # Powerlevel10k instant prompt
      ''
        # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
        # Initialization code that may require console input (password prompts, [y/n]
        # confirmations, etc.) must go above this block; everything else may go below.
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      ''
      # Powerlevel10k instantiation
      "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh"
      "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
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
