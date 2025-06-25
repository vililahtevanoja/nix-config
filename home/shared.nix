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

    # nix
    nixfmt-rfc-style
    nh
  ];

  programs.git = {
    enable = true;
    extraConfig = {
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
        all = true;
      };
      merge.conflictstyle = "zdiff3";
      gc.writecommitGraph = true;
      alias."local-branches" =
        "!git branch --format '%(refname:short) %(upstream:short)' | awk '{if (!$2) print $1;}'";
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
        "git"
        "fzf"
        "direnv"
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
    };
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
    ];
  };

  programs.direnv = {
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
