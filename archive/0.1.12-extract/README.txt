HD2 HUD+ 0.1.12
by DDRK1NG

See your weapon's status beside the crosshair without looking away
from your target.

  - Remaining rounds and reserves beside the crosshair, with your weapon's own ammo icon
  - A reload indicator that fills while you reload
  - A reload stage icon: tactical reload, empty magazine or chambering a round for magazine weapons, a single round for weapons loaded round by round, and the weapon's ammo icon while a heat sink is replaced
  - A charge indicator for weapons that charge before firing
  - Your weapon's fire mode, its function icons and the scope zoom it is set to
  - A dot and ring for weapons the game leaves without a third-person crosshair
  - Backpack ammo and status indicators for supported backpacks
  - Health and stamina indicators
  - Your stim and throwable counts under the stamina bar, with the icon of the throwable you brought
  - Your squad's boosters beside the squad list, yours at the bottom - a skull when a player is dead, or what they pinged
  - The stratagems a player has called, squad-wide ones such as Resupply included, stacked to the right of their squad row in the order they called them: each one fills up while it is on its way in and leaves the row when the game ends that call, so the rest shift along
  - The stratagems you chose, on their own row in the order you chose them: each one drains while it is on the way in, then fills back up while it cools down, with the seconds left shown on it as it comes back in Integrated, and one with no uses left marked as unavailable

Keep Core enabled, then choose what to display.
Choose one HUD layout, then adjust idle visibility and squad icons. Integrated is the default layout:

  HUD layout
    Integrated             Under the crosshair: a charge, reload, heat or rounds arc, ammo, reserve ammo, health/stamina bars, stims, throwables, backpack. Best with game HUD on Map only.
    Rings                  A ring by the crosshair shows charge, reload, heat or rounds; another shows a backpack's own resource. Plus ammo, reserve ammo and weapon setting icons.
    Simple                 Weapon setting icons only - fire mode, function, scope zoom - beside the game's weapon panel. Fixed brightness, and they hide when that panel hides.
  Show when idle
    Faint                  Dims the crosshair HUD to 30% brightness when idle. Does not affect Simple or squad icons.
    Full brightness        Keeps the crosshair HUD at full brightness when idle. Does not affect Simple or squad icons.
  Squad                    Each squad row shows that player's booster, yours last - a skull when dead or what they pinged. Stratagems they call stack along the row. All hide with it.
  Game crosshair           Draws the game's dot and ring for weapons with no third-person crosshair. Hidden in first person. Ignores the game HUD setting for now; that link comes later.
  Stratagems               The stratagems you chose, on a row at the bottom center: each drains on the way in, fills back as it cools, flat when you have no uses left.

  - Scales with your resolution and HUD Scale setting.
  - Supports four-player squads.
  - Writes no log and no settings of its own.

Drop this folder (or a zip of it) into your mod manager, enable it,
and deploy. Removing it is disabling the mod and deploying again - the
patch is additive and replaces no original file.

This mod includes the game's startup script. It cannot run alongside
another mod that also provides that script; only one will load.

Delete the old version from your mod manager first, then add this one,
enable it and pick your options again. Previous selections are not
retained.

If the HUD does not show up or does not behave as described, disable
the mod, delete it from your mod manager, then add this version,
enable it, and deploy.

After a Helldivers 2 update, download a rebuilt version before
deploying the mod. An older build may contain an outdated game startup
script.

Reuse and modification are permitted with credit to the author and a
link back to the Nexus page. Do not re-upload it as your own work.

https://www.nexusmods.com/helldivers2/mods/15298
COMMON           sha256 1d646fa03ea44c2c75d8fca14523daab0d953a59b23afb5a836c6de8f17a4c5c
HUD_INTEGRATED   sha256 37ecae7c2f7f350e2def2145e532ad7ce26ba5e26f490ee8ab04064379083bff
HUD_RING         sha256 9180dcb65e8bdf33d571acd7015ac7f809e7f9bd3c4716aeae7f8e4971cfb9fa
HUD_SIMPLE       sha256 b720833fe64167b203d9f39529643dd8047d5406e4ad45fa32038b49f89e574c
IDLE_FADE        sha256 06b18aee7fa410e35c7078e12024b82b0fb824645e26c8b5912ead30ee966dd2
IDLE_FIX         sha256 7cfabf877e0eec74618467602af9d1f47ce24712a9f8079ddb97db061e2e2822
SQUAD_ALL        sha256 d344b67e17b0e5b81f009a67468b32b28ef83e86eeeac40607f6041738f34ae5
RETICLE_ON       sha256 ed07ee08c9886f10bcad34442c3a0e113098016e40e685602f05c136a3532152
STRATAGEM_ON     sha256 6544424c92f5506fb637449b41cbf70694eb750db9b434aada75f7583f6ca158
