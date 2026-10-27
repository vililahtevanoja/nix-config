# Raspberry Pi 4: NixOS

`nixosConfigurations.raspberrypi` is an AArch64 SD image (from the locked
`unstable` input) with firmware, U-Boot, Ethernet DHCP and `raspberrypi.local`
discovery.

- SSH: only as `vili`, using the public key in `hosts/raspberrypi.nix`. Password
  and root login are disabled.
- `vili` has passwordless sudo and is a trusted Nix user, so that key grants
  admin access.
- Home Manager is not included; the `vili@raspberrypi` profile is separate.
- Services: [Bifrost](bifrost.md).

## Install from Raspberry Pi OS

Requires Nix and a 64-bit userspace on the Pi. Nothing is reformatted until
step 5.

1. Get the config on the Pi. Commit and push from the PC first, then on the Pi:

   ```sh
   git clone https://github.com/vililahtevanoja/nix-config.git ~/nix-config
   # or, in an existing checkout: git pull --ff-only
   ```

2. Build the image on the Pi. Use `tmux`/`screen` so an SSH drop doesn't kill
   it, and keep `flake.lock` unchanged:

   ```sh
   cd ~/nix-config
   nix --extra-experimental-features 'nix-command flakes' build \
     'path:.#nixosConfigurations.raspberrypi.config.system.build.sdImage' \
     --out-link result-sd --max-jobs 2 --cores 2 -L
   sha256sum result-sd/sd-image/nixos-raspberrypi.img > ~/nixos-raspberrypi.img.sha256
   ```

3. Copy the image to WSL and verify it. The check should print
   `nixos-raspberrypi.img: OK`:

   ```sh
   mkdir -p ~/Downloads/nixos-raspberrypi && cd ~/Downloads/nixos-raspberrypi
   scp vili@raspberrypi.local:nix-config/result-sd/sd-image/nixos-raspberrypi.img .
   scp vili@raspberrypi.local:nixos-raspberrypi.img.sha256 .
   sha256sum -c nixos-raspberrypi.img.sha256
   explorer.exe .   # copy the .img to Windows Downloads
   ```

4. Back up everything you need from Raspberry Pi OS. The NixOS image is not a
   backup; a full card image (taken with the Pi powered off) lets you restore
   the old OS.

5. Flash the card:
   - Shut down with `sudo poweroff`, wait for it to finish, then unplug.
   - In Raspberry Pi Imager on Windows, choose **Use custom** and select the
     `.img`.
   - Double-check the target card, because it will be erased.
   - Skip OS customization.

6. Boot with Ethernet. The root filesystem expands on first boot. Then run
   `ssh vili@raspberrypi.local`.
   - "Host identity changed": this is expected because the host keys are new.
     Check the Pi's address in your router, then run
     `ssh-keygen -R raspberrypi.local`.
   - If `.local` doesn't resolve, use the DHCP address from your router.

7. Verify on the Pi:

   ```sh
   cat /etc/os-release                                   # NixOS
   sudo -n true && echo 'Passwordless sudo: OK'
   df -h /                                               # ~118G on the current card
   systemctl --failed --no-pager                         # none
   ```

   There is no console password. To set one, run `sudo passwd vili`; SSH
   password login stays disabled.

## Deploy changes from WSL

Edit `hosts/raspberrypi.nix`, then:

```sh
cd /home/vili/dev/nix-config
nix shell --inputs-from path:. unstable#nixos-rebuild-ng --command \
  nixos-rebuild switch --flake 'path:.#raspberrypi' \
  --build-host vili@raspberrypi.local \
  --target-host vili@raspberrypi.local --sudo --max-jobs 2 --cores 2
```

- The PC evaluates the config, the Pi builds it, and the result is activated on
  the Pi. You don't need to reflash or keep a checkout on the Pi.
- It deploys the WSL working tree, including uncommitted changes and the
  current `flake.lock`. Updating the lock updates the Pi.
- Use `build` instead of `switch` to build without activating.
- Keep an SSH session open until a fresh connection works:
  `ssh vili@raspberrypi.local 'nixos-version; systemctl --failed --no-pager'`.
- For SSH or network changes, run `test` first and confirm a second SSH
  connection works. `test` doesn't change the boot default, but it won't undo a
  lost connection.
- Keep physical access available for boot-related changes.
- Keep `system.stateVersion` at `26.05`.
- To roll back, run `sudo nixos-rebuild switch --rollback` on the Pi.
