---
name: vps-ops
description: >-
  Operate the live Dedicated-server VPS: SSH, git push then pull, Valheim
  systemd, Steam and Hexium mod updates. Use when deploying, updating, or
  restarting the Valheim server, touching /opt/Dedicated-server, vps.md, or
  asking how clients join the live world.
---

# Live VPS

Secrets stay in gitignored `vps.md` at the repo root. Read it when connecting. Do not copy passwords, passphrases, or private keys into commits, chat, or this skill.

`vps.md` keys: `IP`, `USERNAME`, `PASSWORD`, `PASSPHASE` (spelled that way), `SSH` (private key path).

## Access

- SSH is **publickey only**. `PASSWORD` does not log in.
- Key path and passphrase are the `SSH` and `PASSPHASE` lines. The key is encrypted, so `BatchMode` fails until the passphrase unlocks it.
- Same key pushes to GitHub as `risky2k1`. `ssh -T git@github.com` prints a greeting and exits 1. That exit code means auth succeeded.
- The VPS itself has **no GitHub SSH key**. Do not `git fetch git@github.com` on the server.

## Layout

| Item | Value |
| --- | --- |
| Git root on VPS | `/opt/Dedicated-server` |
| Upstream | `https://github.com/risky2k1/Dedicated-server.git` branch `main` |
| Game tree | `/opt/Dedicated-server/Valheim` |
| Process | systemd unit `valheim` (native SteamCMD, not docker compose) |
| Stop | `systemctl stop valheim` sends SIGINT and saves the world (`TimeoutStopSec=120`) |
| Live world | `GAYLANDS`, crossplay on, ServerCharacters off |

`.env`, `Valheim/server/` (Steam install), and `config/bepinex/plugins/*.dll` are gitignored. They live only on the VPS.

## Deploy repo files

Do not scp or sftp tracked files. Commit on the workstation (Windows `git`, not WSL — WSL has no commit identity), push `main`, then on the VPS update **only the paths in that commit**.

```bash
cd /opt/Dedicated-server
git fetch origin
git checkout origin/main -- path/to/changed-file
```

The worktree is dirty on purpose: git still lists old worlds (`SuperSeed2`) and character backups that are **not** on disk, plus local edits to README and similar. `git pull` is fine only when `git status` shows no local edits to files that commit touches. Otherwise checkout those paths explicitly.

Never on the VPS:

- `git checkout -- .`
- `git reset --hard`
- `git clean`

Those commands restore stale saves over the live world and character files.

## Game and mods are not in git

A fetch does not change the Valheim build or plugin DLLs.

1. `systemctl stop valheim` and wait until inactive.
2. `./native/backup-world.sh`
3. Game: `./native/update-server.sh` (Steam app `896660`). It refuses to run while `valheim` is active.
4. Mods: the matching `./native/install-*.sh` (BepInEx, modpack, or a single mod such as AzuCraftyBoxes).
5. `systemctl start valheim`. Confirm the version in `journalctl -u valheim` before editing `Valheim/public/index.html`.

`update-server.sh` stops if the unit or `valheim_server.x86_64` is still running. If SteamCMD fails, start the old unit again so the world is not left offline.

AzuCraftyBoxes on this server is **not** the older copy locked inside TuanPM-MyModPack. The version that runs is the default in `Valheim/native/install-azucraftyboxes.sh`. Clients on Gale must install that same version.

BepInEx version comes from `BEPINEX_PACK_VERSION` or the default in `Valheim/native/install-bepinex.sh`.
