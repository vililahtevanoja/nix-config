{ pkgs, ... }:
{
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

    # containers
    docker
    docker-compose

    # shell
    oh-my-zsh

    # languages
    go
  ];
  programs.git = {
    enable = true;
    extraConfig = {
      user =  {
        name = "Vili Lähtevänoja";
        email = "vili.lahtevanoja@gmail.com";
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
      alias."local-branches" = "!git branch --format '%(refname:short) %(upstream:short)' | awk '{if (!$2) print $1;}'";
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
      ];
      theme = "robbyrussell";
    };
    shellAliases = {
      bubu = "brew update && brew upgrade";
      pn = "pnpm";
      vim = "nvim";
      reload = "source ~/.zshrc";
      zshrc = "nvim ~/.zshrc; reload";
      weather = "curl 'wttr.in?M'";
      kalasatama = "curl 'wttr.in/~Kalasatama?M'";
      ".." = "cd ..";
      "..." = "cd ../.."; 
    };
    initContent = ''
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
    '';

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
  };
}