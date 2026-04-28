{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
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
    let
      allowedUnfreePackages = [
        "claude-code"
        "confluent-cli"
        "github-copilot-cli"
        "kiro-cli"
      ];
      mkPkgs =
        system:
        import unstable {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (unstable.lib.getName pkg) allowedUnfreePackages;
        };
      aarch64-darwin-pkgs = mkPkgs "aarch64-darwin";
      aarch64-linux-pkgs = mkPkgs "aarch64-linux";
      x86_64-linux-pkgs = mkPkgs "x86_64-linux";
    in
    {
      # Define unique configurations per system
      homeConfigurations."vililahtevanoja@vili-rmbp" = home-manager.lib.homeManagerConfiguration {
        pkgs = aarch64-darwin-pkgs;
        modules = [
          ./home/shared.nix
          ./home/aarch64-darwin.nix
          {
            programs.home-manager.enable = true;
            programs.zsh.shellAliases = {
              k = "kiro-cli";
              ka = "kiro-cli --agent";
              kp = "kiro-cli --agent plan";
            };

            home = {
              username = "vililahtevanoja";
              homeDirectory = "/Users/vililahtevanoja";
              stateVersion = "25.05"; # Please read the comment before changing.
              packages = with aarch64-darwin-pkgs; [
                terraform-ls
                confluent-cli
              ];
            };
          }
        ];
      };
      homeConfigurations."vili@ViliPC" = home-manager.lib.homeManagerConfiguration {
        pkgs = x86_64-linux-pkgs;
        modules = [
          ./home/shared.nix
          ./home/shared-linux.nix
          ./home/x86_64-linux.nix
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
        pkgs = aarch64-linux-pkgs;
        modules = [
          ./home/shared.nix
          ./home/shared-linux.nix
          ./home/aarch64-linux.nix
          {
            programs.home-manager.enable = true;

            programs.zsh.enable = true;
            programs.fish.enable = true;
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
