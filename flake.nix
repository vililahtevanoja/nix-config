{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devenv.url = "github:cachix/devenv/latest";
    home-manager.url = "github:nix-community/home-manager";
  };
  outputs = { self, nixpkgs, home-manager, flake-utils, ... }:
    {
      # Define unique configurations per system
      homeConfigurations.vili-rmbp =  home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          modules = [
            ./home/shared.nix
            ./home/aarch64-darwin.nix
            {
              programs.home-manager.enable = true;
          
              programs.zsh.enable = true;
              programs.git.enable = true;

              home = {
                username = "vililahtevanoja";
                homeDirectory = "/Users/vililahtevanoja";
                stateVersion = "25.05"; # Please read the comment before changing. 
              };
            }
          ];
      }; 
  };
}
