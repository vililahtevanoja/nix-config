{ pkgs, lib, ... }:
{
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
}
