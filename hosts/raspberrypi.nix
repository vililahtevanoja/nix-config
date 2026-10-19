{ pkgs, ... }:

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
