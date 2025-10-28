{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devenv.url = "github:cachix/devenv/latest";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs =
    {
      self,
      nixpkgs,
      unstable,
      home-manager,
      flake-utils,
      ...
    }:
    {
      # Define unique configurations per system
      homeConfigurations."vililahtevanoja@vili-rmbp" = home-manager.lib.homeManagerConfiguration {
        pkgs = unstable.legacyPackages.aarch64-darwin;
        modules = [
          ./home/shared.nix
          ./home/aarch64-darwin.nix
          ./home/local.nix
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
      homeConfigurations."vili@ViliPC" = home-manager.lib.homeManagerConfiguration {
        pkgs = unstable.legacyPackages.x86_64-linux;
        modules = [
          ./home/shared.nix
          ./home/shared-linux.nix
          ./home/x86_64-linux.nix
          ./home/local.nix
          {
            programs.home-manager.enable = true;

            programs.zsh.enable = true;
            programs.git.enable = true;

            home = {
              username = "vili";
              homeDirectory = "/home/vili";
              stateVersion = "25.05"; # Please read the comment before changing.
            };
          }
        ];
      };
      homeConfigurations."vili@raspberrypi" = home-manager.lib.homeManagerConfiguration {
        pkgs = unstable.legacyPackages.aarch64-linux;
        modules = [
          ./home/shared.nix
          ./home/shared-linux.nix
          ./home/aarch64-linux.nix
          ./home/local.nix
          {
            programs.home-manager.enable = true;

            programs.zsh.enable = true;
            programs.git.enable = true;

            home = {
              username = "vili";
              homeDirectory = "/home/vili";
              stateVersion = "25.05"; # Please read the comment before changing.
            };
          }
        ];
      };
    };
}
