{ pkgs, lib, ... }:
{
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
}
