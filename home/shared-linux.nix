{ pkgs, ... }:
{
  home.packages = with pkgs; [

  ];

  home.sessionPath = [
    "/snap/bin"
    "$home/bin"
    "/usr/local/bin"
  ];
}
