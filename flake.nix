{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    bifrost.url = "github:maximhq/bifrost?ref=transports/v2.3.2";
  };

  outputs =
    {
      self,
      nixpkgs,
      unstable,
      home-manager,
      flake-utils,
      bifrost,
      ...
    }:
    let
      allowedUnfreePackages = [
        "claude-code"
        "confluent-cli"
        "github-copilot-cli"
      ];
      mkPkgs =
        system:
        import unstable {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (unstable.lib.getName pkg) allowedUnfreePackages;
        };
      mkHome =
        {
          system,
          username,
          homeDirectory,
          modules,
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          modules = modules ++ [
            {
              programs.home-manager.enable = true;

              home = {
                inherit username homeDirectory;
                stateVersion = "25.05"; # Please read the comment before changing.
              };
            }
          ];
        };
    in
    {
      nixosConfigurations.raspberrypi = unstable.lib.nixosSystem {
        specialArgs = { inherit bifrost; };
        modules = [
          "${unstable}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          bifrost.nixosModules.bifrost
          ./hosts/raspberrypi.nix
        ];
      };

      homeConfigurations."vililahtevanoja@vili-rmbp" = mkHome {
        system = "aarch64-darwin";
        username = "vililahtevanoja";
        homeDirectory = "/Users/vililahtevanoja";
        modules = [
          ./home/shared.nix
          ./home/platforms/darwin.nix
          ./home/hosts/vili-rmbp.nix
        ];
      };
      homeConfigurations."vili@ViliPC" = mkHome {
        system = "x86_64-linux";
        username = "vili";
        homeDirectory = "/home/vili";
        modules = [
          ./home/shared.nix
          ./home/platforms/linux.nix
          ./home/hosts/vili-pc.nix
        ];
      };
      homeConfigurations."vili@raspberrypi" = mkHome {
        system = "aarch64-linux";
        username = "vili";
        homeDirectory = "/home/vili";
        modules = [
          ./home/shared.nix
          ./home/platforms/linux.nix
          ./home/hosts/raspberrypi.nix
        ];
      };
    };
}
