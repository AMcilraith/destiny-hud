# Destiny HUD 1.3.0 (English translation)

English translation of the texts in `Destiny-HUD-v1.3.0-Manual.zip`: its manifest, README, in-game option labels
and weapon icon table (`weapon-ammo-icons.md` here). The original is in Simplified Chinese. Its Lua code is not
included. HD2 HUD+'s Destiny style rebuilds this design from the game's own widgets (see HUD+'s README).

## What it was

An HD2 Arsenal mod with one option, **Core**. Its archive patch holds a Bingus Shared Loader addon,
`mods/codex/destiny_hud`: 17 Lua resources that need Bingus Shared Loader API 1, HD2Runtime API 1 and a font mod, and
register their settings through Mod Options Menu. Its readers are pinned to one game build.

## Manifest

- **Name:** Destiny 2 Style HUD v1.3.0 Release
- **Description:** A Destiny-style yellow and white HUD: native health bar progress, Eagle uses in segments, quick
  switching between three weapons, reserve-ammo icons, squad resources and stratagems on the tactical map. The
  release build trims redundant reads. Keep the font prerequisite enabled.
- **Option "Destiny 2 Style HUD":** Yellow and white, laid out as the user marked. Do not enable BAHUD's custom HUD
  at the same time.

## In-game options (Mod Options Menu, group "Destiny 2 Style HUD")

| Label | Range | Default |
| --- | --- | --- |
| Enable Destiny 2 style HUD | toggle | on |
| Left position (%) | 0 to 90 | 3 |
| Distance from bottom (%) | 0 to 90 | 7 |
| Overall size | 0.5 to 2 | 1 |
| Opacity (%) | 10 to 100 | 100 |
| Hide the game's own HUD | toggle | on |

## README

Keeps the current Destiny HUD layout: native health bar progress, four stratagem tiles with Eagle uses in segments,
quick switching between three weapons, backpack and grenades, and squad names, boosters and resource bars. The GP-20,
P-34, P-33 and S-11 Speargun use the round-nosed K per-round reserve icon. A player's ID is the first English letter of
their nickname plus the game's own 1-4 number, or P when the name has no English letter.

**Install:** quit the game completely, update the same HUD in Echelon, tick it, deploy manually and restart fully.
Keep Bingus Shared Loader API 1, HD2Runtime API 1 and the font prerequisite enabled, and keep the HUD's "hide the
game's own HUD" option on. Do not enable BAHUD's custom HUD at the same time; keep the withdrawn RuntimeFont-Probe
disabled.

This version removes the old fire-mode log sampling, an unused read of the vanilla magazine image and a duplicate
cache check before the current silhouette is overwritten. When the native ammo fields are complete and no ammo
backpack is paired, the spare weapons skip the duplicate spare reader. The 19-span stamina check (18 instruction spans
and one constant) is still verified fresh every time, now merged into 7 reads; only the pre-decoded static bytes are
cached, never the stamina value. The native health bar, Guard safety checks, reload-from-reserve, special backpacks
and underbarrels, the usual fast refresh and the squad features are kept.

The install package holds only the install files, this README, the weapon table and the icon reference. Research
notes, sources and the change log are in the Source package and separate reports. `weapon-ammo-icons.md` is a static
table of 116 entries; when another mod changes feed data in game, the fresh native read wins.

All 17 Lua files were compiled with the installed game's lua51.dll (luaL_loadbuffer) without running them. Exact
diffs, retention checks and a resource-by-resource read-back of the Manual and Source packages passed. The new, old
and reference Lua and the Runtime were not run: no new process reads, and no game, GPU, loading, regression, smoke,
simulation, multiplayer or performance tests or deployment. The change in read counts comes from the source review;
it does not mean a measured frame-rate gain or that multiplayer stutter is gone.

Built by continuously modifying the BAHUD and earlier HUD the user supplied, with their source records and author
credits kept. This delivery is the user's local release package.
