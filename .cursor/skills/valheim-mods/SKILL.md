---
name: valheim-mods
description: >-
  Valheim dedicated server mod workflow: Hexium platform, Gale client manager,
  TuanPM-MyModPack instead of per-mod installs, and CROSSPLAY for Valheim 1.0.
  Use when installing/updating Valheim mods, writing player docs, setup scripts,
  or advising how clients join the server.
---

# Valheim mods (Hexium + Gale + modpack)

## Defaults

| Item | Value |
| --- | --- |
| Mod site | Hexium — https://valheim.hexium.gg |
| Client manager | Gale — not r2modman |
| Client install | Modpack `TuanPM-MyModPack` **1.0.1** (`TuanPM-MyModPack-1.0.1`) |
| Game | Valheim **1.0** |
| Crossplay | **Required** on dedicated: `CROSSPLAY=true` |

## Do / Don't

- **Do** tell players: install Gale → search/install **TuanPM-MyModPack** 1.0.1 → launch via Gale.
- **Do** keep server plugins in sync via `native/install-*.sh` + Hexium API (BepInExPack, ServerCharacters, optional admin mods).
- **Don't** recommend r2modman or Thunderstore as the primary client path for this server.
- **Don't** list/install the 6 QoL mods one-by-one — use the modpack.
- **Don't** ship a Valheim 1.0 dedicated without `-crossplay` / `CROSSPLAY=true`.

## Server download helper

```bash
# from Valheim/
source native/lib/common.sh
hexium_resolve_download_url OWNER PackageName [VERSION]
```

## Player-facing copy

- Gale download (Windows MSI example): keep versioned GitHub release link if needed.
- Mod names only (no per-mod Hexium URLs) — Gale has search.
- Join: launch game from Gale → Join IP.
