> English translation of `weapon-ammo-icons.md` from Destiny HUD 1.3.0 (Manual). Kept for reference: HD2 HUD+ draws each weapon's own magazine icon from the game's weapon data instead of these G/K rules.

# Reserve-ammo icon per weapon in the current HUD (116 weapons)

v1.3.0 keeps the rule the user asked for: the GP-20, P-34, P-33 and S-11 Speargun use the round-nosed K per-round reserve icon. They are matched by four stable weapon type ids, the same in the held row and the spare rows. All four are still Magazine components natively, and their numbers still read the native reserve/reserve_max; every other weapon picks its icon from its native feed field. The table below was matched against the bundled SDK 0.40.0 catalogue entry by entry. It is a code and catalogue check, not an in-game test of all 116 weapons. When a mod changes a feed component, the active underbarrel entity or a reserve maximum, or a read fails, the native data at that moment wins.

| Native field / case | Icon | What the reserve number means |
|---|---|---|
| feed=rounds | K: round-nosed single-cartridge icon | Native total reserve, excluding the loaded rounds |
| One of the four stable ids, feed=magazine, maximum spare magazines not 0 | K: round-nosed single-cartridge icon | Native spare count; with single-round capacity one spare is one round |
| Any other feed=magazine with maximum spare magazines not 0 | G: long straight magazine icon | Native spare-magazine count |
| feed=magazine, maximum spare magazines = 0 | G branch, but not drawn by default | A backpack's reserve is not shown as spare magazines |
| heat / backpack / infinite / unrecognised or unreadable reserve | No G/K drawn | Keeps the heat, backpack, ∞ or unknown display |

G/K apply to the weapon in hand and to the two spare weapon rows, with the same branches. The S-11 Speargun is in support slot 3 and uses K whether held or not. In all: K for 22 weapons (18 native rounds + the 4 Magazine weapons by rule), the G branch for 71 (11 of them not drawn by default), and 23 others. By native component it is still 18 rounds and 75 magazine. Apart from these four, the RS-422, for example, still shows G for its native Magazine.

## Primary weapons

| Weapon | Native feed | Icon branch | Default display / condition | Notes |
|---|---|---|---|---|
| AR-11 Arbitrator | magazine | G: long straight magazine | Shown by default | — |
| AR-2 Coyote | magazine | G: long straight magazine | Shown by default | — |
| AR-23 Liberator | magazine | G: long straight magazine | Shown by default | — |
| AR-23A Liberator Carbine | magazine | G: long straight magazine | Shown by default | — |
| AR-23C Liberator Concussive | magazine | G: long straight magazine | Shown by default | — |
| AR-23P Liberator Penetrator | magazine | G: long straight magazine | Shown by default | — |
| AR-32 Pacifier | magazine | G: long straight magazine | Shown by default | — |
| AR-59 Suppressor | magazine | G: long straight magazine | Shown by default | — |
| AR-61 Tenderizer | magazine | G: long straight magazine | Shown by default | — |
| AR/GL-21 One-Two | magazine | G: long straight magazine | Shown by default | This row is the rifle; the underbarrel follows the active entity's native feed component |
| ARC-12 Blitzer | No ammo component | No G/K | Melee / infinite, or no such reserve branch | — |
| BR-14 Adjudicator | magazine | G: long straight magazine | Shown by default | — |
| CB-9 Exploding Crossbow | magazine | G: long straight magazine | Shown by default | — |
| DBS-2 Double Freedom | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| FLAM-66 Torcher | magazine | G: long straight magazine | Shown by default | — |
| GL-15 Evictor | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| JAR-5 Dominator | magazine | G: long straight magazine | Shown by default | — |
| LAS-12 Sai | heat | No G/K | Heat / heat-sink shown separately | — |
| LAS-13 Trident | heat | No G/K | Heat / heat-sink shown separately | — |
| LAS-16 Sickle | heat | No G/K | Heat / heat-sink shown separately | — |
| LAS-17 Double-Edge Sickle | heat | No G/K | Heat / heat-sink shown separately | — |
| LAS-22 Shear | heat | No G/K | Heat / heat-sink shown separately | — |
| LAS-5 Scythe | heat | No G/K | Heat / heat-sink shown separately | — |
| M7S SMG | magazine | G: long straight magazine | Shown by default | — |
| M90A Shotgun | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| MA5C Assault Rifle | magazine | G: long straight magazine | Shown by default | — |
| MP-98 Knight | magazine | G: long straight magazine | Shown by default | — |
| PLAS-1 Scorcher | magazine | G: long straight magazine | Shown by default | — |
| PLAS-101 Purifier | magazine | G: long straight magazine | Shown by default | — |
| PLAS-39 Accelerator Rifle | magazine | G: long straight magazine | Shown by default | — |
| R-2 Amendment | magazine | G: long straight magazine | Shown by default | — |
| R-2124 Constitution | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| R-36 Eruptor | magazine | G: long straight magazine | Shown by default | — |
| R-4 Hyena | magazine | G: long straight magazine | Shown by default | — |
| R-6 Deadeye | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| R-63 Diligence | magazine | G: long straight magazine | Shown by default | — |
| R-63CS Diligence Counter Sniper | magazine | G: long straight magazine | Shown by default | — |
| R-72 Censor | magazine | G: long straight magazine | Shown by default | — |
| R/40-K Hot-Shot Marksman Rifle | magazine | G: long straight magazine | Shown by default | — |
| SG-20 Halt | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| SG-225 Breaker | magazine | G: long straight magazine | Shown by default | — |
| SG-225IE Breaker Incendiary | magazine | G: long straight magazine | Shown by default | — |
| SG-225SP Breaker Spray&Pray | magazine | G: long straight magazine | Shown by default | — |
| SG-451 Cookout | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| SG-8 Punisher | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| SG-8P Punisher Plasma | magazine | G: long straight magazine | Shown by default | — |
| SG-8S Slugger | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| SG-97 Sweeper | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| SMG-203 Gallant | magazine | G: long straight magazine | Shown by default | — |
| SMG-32 Reprimand | magazine | G: long straight magazine | Shown by default | — |
| SMG-37 Defender | magazine | G: long straight magazine | Shown by default | — |
| SMG-72 Pummeler | magazine | G: long straight magazine | Shown by default | — |
| SMG/FLAM-34 Stoker | magazine | G: long straight magazine | Shown by default | — |
| StA-11 SMG | magazine | G: long straight magazine | Shown by default | — |
| StA-52 Assault Rifle | magazine | G: long straight magazine | Shown by default | — |
| VG-70 Variable | magazine | G: long straight magazine | Shown by default | — |

## Secondary weapons

| Weapon | Native feed | Icon branch | Default display / condition | Notes |
|---|---|---|---|---|
| CQC-19 Stun Lance | No ammo component | No G/K | Melee / infinite, or no such reserve branch | — |
| CQC-2 Saber | No ammo component | No G/K | Melee / infinite, or no such reserve branch | — |
| CQC-30 Stun Baton | No ammo component | No G/K | Melee / infinite, or no such reserve branch | — |
| CQC-42 Machete | magazine | G: long straight magazine | Shown by default | The current catalogue gives it a Magazine component, so G; its melee name does not change the branch |
| CQC-5 Combat Hatchet | No ammo component | No G/K | Melee / infinite, or no such reserve branch | — |
| CQC-73 Entrenchment Tool | No ammo component | No G/K | Melee / infinite, or no such reserve branch | — |
| GP-20 Ultimatum | magazine | K: round-nosed cartridge (user rule) | Shown by default | K by stable weapon id; the native Magazine component, reserve/reserve_max and reload-transfer reads are kept |
| GP-31 Grenade Pistol | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| LAS-58 Talon | heat | No G/K | Heat / heat-sink shown separately | — |
| LAS-7 Dagger | heat | No G/K | Heat / heat-sink shown separately | — |
| M6C/SOCOM Pistol | magazine | G: long straight magazine | Shown by default | — |
| P-11 Stim Pistol | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| P-113 Verdict | magazine | G: long straight magazine | Shown by default | — |
| P-19 Redeemer | magazine | G: long straight magazine | Shown by default | — |
| P-2 Peacemaker | magazine | G: long straight magazine | Shown by default | — |
| P-33 Missile Pistol | magazine | K: round-nosed cartridge (user rule) | Shown by default | K by stable weapon id; the native Magazine component, reserve/reserve_max and reload-transfer reads are kept |
| P-34 Breacher | magazine | K: round-nosed cartridge (user rule) | Shown by default | K by stable weapon id; the native Magazine component, reserve/reserve_max and reload-transfer reads are kept |
| P-35 Re-Educator | magazine | G: long straight magazine | Shown by default | — |
| P-4 Senator | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| P-69 Veto | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| P-72 Crisper | magazine | G: long straight magazine | Shown by default | — |
| P-92 Warrant | magazine | G: long straight magazine | Shown by default | — |
| P/40-K Bolt Pistol | magazine | G: long straight magazine | Shown by default | — |
| PLAS-15 Loyalist | magazine | G: long straight magazine | Shown by default | — |
| SG-22 Bushwhacker | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |

## Support weapons

| Weapon | Native feed | Icon branch | Default display / condition | Notes |
|---|---|---|---|---|
| 40-K Meltagun | magazine | G: long straight magazine | Shown by default | — |
| AC-8 Autocannon | rounds | K: round-nosed cartridge | Shown when the reserve is read | Its own native reserve maximum is 0, but the K branch is not hidden for that; backpack pairing and modded amounts use the existing reads; linked to a backpack; the spare-magazine maximum here is not the backpack total |
| APW-1 Anti-Materiel Rifle | magazine | G: long straight magazine | Shown by default | — |
| ARC-3 Arc Thrower | none | No G/K | Neither recognised feed component | — |
| B/FLAM-80 Cremator | magazine | G branch (not drawn by default) | Native spare-magazine maximum is 0 | Has variants with other feed components, so the active entity may take another branch; linked to a backpack; the spare-magazine maximum here is not the backpack total |
| B/MD C4 Pack | none | No G/K | Neither recognised feed component | Linked to a backpack; the spare-magazine maximum here is not the backpack total |
| CQC-1 One True Flag | none | No G/K | Neither recognised feed component | — |
| CQC-20 Breaching Hammer | magazine | G: long straight magazine | Shown by default | Has variants with other feed components, so the active entity may take another branch |
| CQC-72 Entrenchment Tool | none | No G/K | Neither recognised feed component | — |
| CQC-9 Defoliation Tool | none | No G/K | Neither recognised feed component | — |
| EAT-17 Expendable Anti-Tank | magazine | G branch (not drawn by default) | Native spare-magazine maximum is 0 | — |
| EAT-411 Leveller | magazine | G branch (not drawn by default) | Native spare-magazine maximum is 0 | — |
| EAT-700 Expendable Napalm | magazine | G branch (not drawn by default) | Native spare-magazine maximum is 0 | — |
| FAF-14 Spear | magazine | G branch (not drawn by default) | Native spare-magazine maximum is 0 | Linked to a backpack; the spare-magazine maximum here is not the backpack total |
| FLAM-40 Flamethrower | magazine | G: long straight magazine | Shown by default | — |
| GL-21 Grenade Launcher | magazine | G: long straight magazine | Shown by default | — |
| GL-28 Belt-Fed Grenade Launcher | backpack | No G/K | Fed directly from a backpack | Linked to a backpack; the spare-magazine maximum here is not the backpack total |
| GL-52 De-Escalator | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| GR-8 Recoilless Rifle | magazine | G branch (not drawn by default) | Native spare-magazine maximum is 0 | Linked to a backpack; the spare-magazine maximum here is not the backpack total |
| LAS-98 Laser Cannon | heat | No G/K | Heat / cooldown shown separately | — |
| LAS-99 Quasar Cannon | heat | No G/K | Heat / cooldown shown separately | — |
| M-1000 Maxigun | backpack | No G/K | Fed directly from a backpack | Linked to a backpack; the spare-magazine maximum here is not the backpack total |
| M-105 Stalwart | magazine | G: long straight magazine | Shown by default | — |
| MG-206 Heavy Machine Gun | magazine | G: long straight magazine | Shown by default | — |
| MG-43 Machine Gun | magazine | G: long straight magazine | Shown by default | — |
| MGX-42 Bullet Storm | magazine | G branch (not drawn by default) | Native spare-magazine maximum is 0 | — |
| MLS-4X Commando | magazine | G branch (not drawn by default) | Native spare-magazine maximum is 0 | — |
| MS-11 Solo Silo | magazine | G branch (not drawn by default) | Single-shot special case, maximum 0 | — |
| PLAS-45 Epoch | magazine | G: long straight magazine | Shown by default | — |
| RL-77 Airburst Rocket Launcher | magazine | G branch (not drawn by default) | Native spare-magazine maximum is 0 | Linked to a backpack; the spare-magazine maximum here is not the backpack total |
| RS-422 Railgun | magazine | G: long straight magazine | Shown by default | — |
| S-11 Speargun | magazine | K: round-nosed cartridge (user rule) | Shown by default | K by stable weapon id; the native Magazine component, reserve/reserve_max and reload-transfer reads are kept |
| SG-88 Break-Action Shotgun | rounds | K: round-nosed cartridge | Shown when the reserve is read | — |
| StA-X3 W.A.S.P. Launcher | magazine | G branch (not drawn by default) | Native spare-magazine maximum is 0 | Linked to a backpack; the spare-magazine maximum here is not the backpack total |
| TX-41 Sterilizer | magazine | G: long straight magazine | Shown by default | — |

## Names from installed weapon packs

A pack that only replaces display names, fire rate, damage, capacity and so on, and keeps the original feed component, follows its base weapon above: Khvostov 7G-0X is the AR-2 Coyote (G), "Fated Chaos" is the MG-206 Heavy Machine Gun (G), "VS Velocity Baton" is the GL-15 Evictor (K), Gjallarhorn is the GR-8 Recoilless Rifle (G branch, hidden when its native spare-magazine maximum is 0) and Heir Apparent is the M-1000 Maxigun (backpack-fed, no G/K). No special icon rule was added for these weapons; if their mod really changes the native feed data, the display follows it.

Sources: reserve_icon and the current_spare/other row conditions in work/destiny-hud-130/src/renderer.lua, ctx.weapon/BAWeaponAmmo.read in reference.lua, proxy:ammo in equipment_view.lua, and the SHAs of the three SDK catalogues listed in this folder's weapon-ammo-icons.json.
