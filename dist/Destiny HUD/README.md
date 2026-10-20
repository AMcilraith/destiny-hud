# Destiny HUD

A Destiny-style panel at the bottom left of the mission HUD. It replaces the game's own panel there and leaves the rest of the HUD alone. Set it in the game's Options menu, on the Destiny tab.

From left to right:

- **Booster**: your booster's icon at the left end. It keeps the last icon read this life, so a ping or a missed read does not blank it.
- **Health bar**: on its own dark plate with a medical cross in front, split in quarters. Its colour shows how much health is left: white at 90% or more, blue at 80%, green at 70%, yellow at 50%, orange at 25%, red below that. Under 15% it pulses between dark burgundy and red, one cycle every 0.75 seconds. **Stamina bar**: yellow, under it.
- **Stratagem tiles**: the four stratagems you chose, as the game's own cards. Mission stratagems such as Reinforce, SOS and Resupply are left out. A yellow rail means ready, grey means on its way in or cooling down.
- **Backpack row**: a glyph for the kind of pack and its bar. A Guard Dog (Rover, Dog Breath and the rest) shows its gun's recharge, yellow while recharging. A shield pack shows its charge, and its recharge in red once broken. A pack with its own countdown shows that countdown; any other pack shows the game's own gauge. An ammo backpack also shows the rounds left for the weapon it feeds.
- **Weapon in hand**: its picture, rounds left (red at 0; heat weapons show no count), a shade that drains with the magazine, spare magazines with the weapon's own magazine icon, and its fire mode.
- **Other weapons**: your other two weapons, with their pictures and magazine icons from the start, and the rounds and spare magazines they had when you last held them. The strip at the right edge shows the slot: white for primary, green for secondary, violet for support.
- **Stims and grenades**: count and one cell per item you can carry: grenades up to the game's own maximum, stims up to at least 4 (the game's standard) or the most you have carried since you last spawned. Stims are cyan and grenades yellow; either turns red at 0. Without a backpack they take the backpack row as well, as two full-width rows beside the spare weapons.
- **Teammates**: each squadmate's row in the game's squad list shrinks with the panel, in place, and gets a Destiny frame: a dark plate, a yellow rail (red while they are dead) and a thin base line. The game still draws their name, health and gear.

The panel draws the game's own icons: the weapon's HUD picture, its magazine icon, the throwable and stim icons, fire-mode icons and the game's stratagem cards. Icon packs therefore show up here as they do in the game.

Options are under **Destiny HUD**:

| Option | Range | Default |
| --- | --- | --- |
| Position X | 0 to 90% of the screen width from the left | 1 |
| Distance From Bottom | 0 to 90% of the screen height | 1 |
| Size (squad rows scale with it) | Default (about the game's own HUD size) / 25% Larger / 50% Larger | Default |
| Opacity | 0.1 to 1 | 1 |
| Hide Game Panel | off / on | on |

**Hide Game Panel** hides only the game's own panel at the bottom left. The squad list and the stratagem list stay. The squad list moves up while this panel shows, so it sits just above the panel, and goes back when it closes.

## Building

```
powershell -ExecutionPolicy Bypass -File build.ps1
```

`build.ps1` writes `dist/Destiny HUD/`, ready to add to a mod manager. It rebuilds three resources from `src/` and keeps the archive's textures, materials and GPU/stream files as they are:

- `src/boot.lua`: the game's startup script with this mod's loader (`boot`);
- `src/modules/*.lua`, in the order of `src/modules.json`: the HUD (`mods/hd2_hud/hd2_hud_plus`);
- `src/strings/strings.json`: the options menu text, in 15 languages, English first. A row with fewer languages uses its English text for the rest.

This mod includes the game's startup script. It cannot run alongside another mod that also provides that script; only one will load. It still needs the game's Lua loader. It is not an asset swap: the panel is built and updated in Lua from the game's own widgets.

## Credits

- **HD2 HUD+** by DDRK1NG: https://www.nexusmods.com/helldivers2/mods/15298. This mod keeps that mod's loader, menu and the readers the panel uses, and drops the rest. Reuse and modification are permitted with credit to the author and a link back to that page. Do not re-upload it as your own work.
- **Destiny HUD 1.3.0** (`mods/codex/destiny_hud`, the "Destiny 2 style HUD"): the layout, palette and panel design. Its package names no author. It says it was built from BAHUD 2.2 and an earlier HUD, with their credits kept, and it has no licence file. Its Chinese texts are rewritten in English here. None of its code, fonts or baked icon art is included: this panel is drawn from the game's own widgets and textures.
