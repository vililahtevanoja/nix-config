{ bifrost, pkgs, ... }:

let
  bifrostPackages = bifrost.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  nixpkgs.hostPlatform = "aarch64-linux";

  boot.zfs.forceImportRoot = false;

  networking = {
    hostName = "raspberrypi";
    useDHCP = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Keep raspberrypi.local discoverable after replacing Raspberry Pi OS.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  services.bifrost = {
    enable = true;
    # The pinned upstream release still has stale npm/vendor hashes and the pre-Vite Next.js patch.
    package =
      (bifrostPackages.bifrost-http.override {
        bifrost-ui = bifrostPackages.bifrost-ui.overrideAttrs (previous: {
          npmDeps = previous.npmDeps.overrideAttrs {
            outputHash = "sha256-sH7vaaCBRLSwDUNj/C1mwQtaQ+1Ft8AJkILHnugkceQ=";
          };
          postPatch = "";
        });
      }).overrideAttrs
        { vendorHash = "sha256-+hoVvwoG3AV0QzqFfIvcPFwy6yd1T4Wuv+6TwY02tmk="; };
    host = "127.0.0.1";
    port = 8080;
    openFirewall = false;
    stateDir = "/var/lib/bifrost";
    # Keep credentials out of the Nix store; systemd reads this at service start.
    environmentFile = "/var/lib/secrets/bifrost.env";
    settings = {
      source_of_truth = "config.json";
      providers.openai.keys = [
        {
          name = "openai-primary";
          value = "env.OPENAI_API_KEY";
          models = [ "*" ];
          weight = 1.0;
        }
      ];
    };
  };

  systemd.services.bifrost.serviceConfig.Restart = "on-failure";

  users.users.vili = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJX79fSTodkgMfE7rOlcboCmcb/+EVRrarLL9PU77DtN"
    ];
  };

  # This key-only administrator needs sudo for remote system activation.
  security.sudo.extraRules = [
    {
      users = [ "vili" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Remote deployments can upload locally built store paths as this administrator.
    trusted-users = [
      "root"
      "vili"
    ];
  };

  environment.systemPackages = [ pkgs.git ];

  image.baseName = "nixos-raspberrypi";
  # Produce a plain .img that Windows Raspberry Pi Imager can write directly.
  sdImage.compressImage = false;

  # Compatibility baseline for the first installation; do not bump on upgrades.
  system.stateVersion = "26.05";
}
