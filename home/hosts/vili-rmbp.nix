{ pkgs, ... }:
{
  programs.zsh.shellAliases = {
    k = "kiro-cli";
    ka = "kiro-cli --agent";
    kp = "kiro-cli --agent plan";
  };

  home.packages = with pkgs; [
    terraform-ls
    confluent-cli
  ];
}
