{
  config,
  pkgs,
  lib,
  common-shell-aliases,
  ...
}:

let
  zshDotDir = "${config.xdg.configHome}/zsh";
  zsh-patina = pkgs.rustPlatform.buildRustPackage rec {
    pname = "zsh-patina";
    version = "1.8.0"; # Check for latest version on crates.io
    src = pkgs.fetchCrate {
      inherit pname version;
      hash = "sha256-bG6nw4pZoSnPCkHWPb/cu8lEH55uoAd2uq9HKwuoKEc=";
    };
    cargoHash = "sha256-4Meb4BDV/Um8/YMA5DkeNDcgCMS5cA8olKhOIq9coIU=";
    useNextest = true;
    meta = {
      description = "Zsh plugin for fast syntax highlighting";
      mainProgram = "zsh-patina";
    };
  };
in
{
  home.sessionVariables = {
    ZDOTDIR = zshDotDir;
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
        # Reference the executable directly
        eval "$(${lib.getExe zsh-patina} activate)"
      ''
      ''
        path+=("${config.home.homeDirectory}/.local/bin")
      ''
    ];
  };
}
