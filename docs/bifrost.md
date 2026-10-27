# Bifrost on the Raspberry Pi

- The UI and the OpenAI-compatible API listen on `127.0.0.1:8080`. The port is
  not opened in the firewall.
- State, including the SQLite databases, is in `/var/lib/bifrost`.
- Secrets are in `/var/lib/secrets/bifrost.env` (root, 0600), which the service
  reads at start. Never put secrets in `hosts/raspberrypi.nix`, because the Nix
  store is world-readable.
- The upstream flake is pinned in `flake.lock`. Only the Pi imports its module.

## First deployment

1. Create the env file on the Pi:

   ```sh
   sudo install -d -m 0700 /var/lib/secrets
   sudo install -m 0600 /dev/null /var/lib/secrets/bifrost.env
   sudoedit /var/lib/secrets/bifrost.env   # OPENAI_API_KEY=<key>
   ```

   Type the key in the editor; don't paste it into a shell command.

2. Deploy from WSL with the command in
   [Deploy changes from WSL](raspberrypi.md#deploy-changes-from-wsl). Run it
   with `build` first and then `switch`.

3. Create the admin account. Until one exists, `/api` is locked.
   1. Generate a setup token on the Pi:
      `head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n'; echo`
   2. Add `BIFROST_SETUP_TOKEN=<token>` with `sudoedit`, then run
      `sudo systemctl restart bifrost`.
   3. Wait for startup (about 40 s). The log should no longer say "no setup
      token is configured".
   4. In the UI (see below), enter the token under **Setup token**, create the
      admin, and enable authentication. The password needs 12+ characters, with
      upper- and lowercase letters, a digit and a special character.
   5. Keep the token in the env file. It is the recovery credential if
      authentication is ever disabled; without it `/api` rejects every request.

## Use

On the PC, keep a tunnel open:

```sh
ssh -N -L 127.0.0.1:8080:127.0.0.1:8080 vili@raspberrypi.local
```

- UI: `http://127.0.0.1:8080`
- API base URL: `http://127.0.0.1:8080/v1`, for example with model
  `openai/gpt-4o-mini`. The `openai-primary` key allows all models.
- Providers are declared in `hosts/raspberrypi.nix`
  (`source_of_truth = "config.json"`). UI changes to them are overwritten on
  restart.

## Operate

```sh
sudo systemctl status bifrost --no-pager
sudo journalctl -u bifrost -n 100 --no-pager
```

- To rotate a key, `sudoedit` the env file, then
  `sudo systemctl restart bifrost`.
- To back up:
  1. Stop bifrost.
  2. Copy the real state directory, `/var/lib/private/bifrost`. Don't copy the
     `/var/lib/bifrost` symlink; it doesn't include the data. Also copy the env
     file.
  3. Start bifrost again.

  Stopping first avoids copying SQLite while it is being written. Restore only
  while stopped, and keep ownership and permissions.
- `nixos-rebuild switch --rollback` doesn't roll back state or secrets. An
  older Bifrost may need its matching state backup.
