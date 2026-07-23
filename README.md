# es_soundtester — Cortex Sound Tester

![FiveM](https://img.shields.io/badge/FiveM-Cfx%20Re-%23FF6C00?logo=fivem&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-%23000080?logo=lua&logoColor=white)
![React](https://img.shields.io/badge/React-%2361DAFB?logo=react&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg)

A client-side FiveM developer utility for browsing, filtering, and previewing GTA V sound sets and vehicle engine audio through an in-game NUI interface.

## Features

- **2,204+ sound entries** loaded from `config/sounds_database.json`
- **Fuzzy search** and filtering by sound set or category
- **Live sound preview** with position and volume handling
- **Vehicle audio preview** using `ForceVehicleEngineAudio` with RPM and volume controls
- **Replay keybind** for quickly re-testing the last played sound
- **Build-aware UI** that shows which GTA V build a sound belongs to
- **Copy-to-clipboard** helper for sound names and sets
- **Developer exports** for other resources to trigger playback or open the UI

## Installation

1. Copy the `es_soundtester` folder into your FiveM server under `resources/`.
2. Add `ensure es_soundtester` to your `server.cfg`.
3. Restart the server or run `refresh` followed by `ensure es_soundtester` from the server console.

### Building the UI

The in-game UI is a React + Vite application. The built files already live in `html/`:

- `html/index.html`
- `html/app.js`
- `html/style.css`

If you modify the source in `web/src/`, rebuild with:

```bash
cd web
bun install
bun run build
```

This outputs the new bundle to `html/`.

## Configuration

Edit `config/config.lua` to change behavior:

| Setting | Default | Description |
| --- | --- | --- |
| `Config.OpenKey` | `MINUS` | Key to open/close the tester UI |
| `Config.ReplayKey` | `F10` | Key to replay the last selected sound |
| `Config.DefaultVolume` | `1.0` | Default preview volume (0.0 to 1.0) |
| `Config.PlayAtPlayerPosition` | `true` | Play sounds at the player position |
| `Config.FixedPosition` | `vector3(0.0, 0.0, 0.0)` | Fallback world position if `PlayAtPlayerPosition` is `false` |
| `Config.SoundsPerPage` | `50` | Number of sounds shown per page in the UI |
| `Config.Debug` | `false` | Enable console debug logging |
| `Config.VehiclePreviewDuration` | `4000` | How long vehicle audio preview runs before auto-stopping (ms) |
| `Config.VehicleDamageMultiplier` | `0.1` | Damage multiplier applied while the UI is open |
| `Config.NotificationDuration` | `3000` | Duration of on-screen notifications (ms) |

## Usage

- Press `MINUS` (default) to open the in-game UI.
- Press `F10` (default) to replay the last sound.
- Use `/soundtester` to toggle the UI from chat.
- Use `/soundtester_replay` to replay the last sound from chat.
- Use `/playsound <soundName> <soundSet>` to play a sound directly.

The UI has two tabs:

- **Sounds** — search and preview any sound from the database.
- **Vehicles** — preview engine audio for listed vehicles by forcing the audio name onto a hidden spawned vehicle.

## Architecture

```
es_soundtester/
├── fxmanifest.lua            # FiveM resource manifest (fx_version cerulean, game gta5)
├── client/
│   └── client.lua            # Client runtime: NUI callbacks, commands, exports, playback, vehicle preview
├── config/
│   ├── config.lua            # User-configurable settings
│   ├── sounds.lua            # Loads and categorizes sounds_database.json
│   ├── sounds_database.json  # 2,204+ GTA V sound entries
│   └── vehicles.lua          # Vehicle audio names for ForceVehicleEngineAudio
├── html/                     # Built NUI files served to FiveM
│   ├── index.html
│   ├── app.js
│   └── style.css
└── web/                      # React + Vite source for the NUI
    ├── src/
    │   ├── App.jsx
    │   └── index.css
    ├── package.json
    └── bun.lock
```

### Client Exports

Other resources can use:

```lua
exports['es_soundtester']:PlaySound(soundName, soundSet)
exports['es_soundtester']:GetLastPlayedSound()
exports['es_soundtester']:OpenUI()
exports['es_soundtester']:CloseUI()
exports['es_soundtester']:ToggleUI()
```

## Limitations

- GTA V frontend sounds do not support volume control; the `DefaultVolume` setting is applied to positioned playback.
- Some sounds and audio banks are tied to specific GTA V builds and may not be available on older builds.
- Vehicle audio preview creates a hidden, invincible vehicle under the player and stops automatically after the configured duration.
- The `DamageMultiplier` and engine health protection only apply while the UI is open and are reset on close.
- This resource is client-side only; it does not require or include a server component.

## Disclaimer

This is an independent community resource. FiveM, Cfx.re, Rockstar Games, and Grand Theft Auto V are trademarks or registered trademarks of their respective owners. This project is not affiliated with, endorsed by, or sponsored by any of them.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

Copyright (c) 2026 Ever3st
