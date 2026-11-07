<p align="center"><img src="logo.png" width="160" alt="AutoFart logo"></p>

# AutoFart

Someone walks past you. You fart. Automatically.

AutoFart is a World of Warcraft addon. It watches for players who come close (~10 yards) and fires the `/fart` emote at them the moment they pass by: *"You brush up against Bob and fart loudly."*

## Anti-spam built in
- **Quiet in cities and inns.** It's off in rest areas.
- **Quiet in crowds.** It pauses when 8+ players are visible or 3+ are right next to you.
- **At most 4 farts per minute**, and the same player gets one at most every 30 seconds.
- **No bursts.** When a pause ends, people already standing next to you are skipped. Only new passers-by trigger it.

## Install
Download the zip from [Releases](../../releases) and extract it into:

```
World of Warcraft\_forever_\Interface\AddOns\
```

You should end up with `Interface\AddOns\AutoFart\AutoFart.toc`. Restart the game.

## Commands (`/af` or `/autofart`)
| Command | Effect |
|---|---|
| `/af` | Toggle on/off |
| `/af test` | Fart right now |
| `/af cd <sec>` | Per-player cooldown (default 30) |
| `/af gcd <sec>` | Minimum time between farts (default 2) |
| `/af range 2/3/4` | Trigger range: ~11 / ~10 / ~28 yd (default 3) |
| `/af target` | Aim the emote at the passer-by (default on) |
| `/af city` | Allow in cities/inns (default off) |
| `/af crowd <n>` | Pause when n+ players are visible, 0 = off (default 8) |
| `/af max <n>` | Max farts per minute, 0 = unlimited (default 4) |
| `/af plates` | Toggle friendly nameplates |

## Good to know
- AutoFart **turns on friendly nameplates**, because it can only detect friendly players whose nameplates are shown. Type `/af plates` to turn them off. Without them it still detects enemy players, your target and whoever is under your mouse.
- Settings are saved per account.
- Made for **WoW Forever** (Interface 16001).

## Development
- `AutoFart/`: the addon itself (copy this folder into `Interface\AddOns`).
- `tools/make_logo.py`: draws `logo.png` and `AutoFart/icon.tga` (needs Python + Pillow).

## License
[Apache 2.0](LICENSE)
