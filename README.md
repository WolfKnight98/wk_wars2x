# Wraith ARS 2X

The **Wraith ARS 2X** (Wraith Advanced Radar System) is a realistic police radar inspired by the real Stalker DSR 2X radar system. It features enhanced realism and experience, including a plate reader that scans vehicles in front and behind the patrol vehicle. The Wraith ARS 2X tracks both large, slower vehicles and smaller, faster targets, displaying speeds of up to four targets simultaneously when both antennas are active. Developers can also hook into the scanner to link it to other resources.

## Installation

1. Download the latest version from [GitHub](https://github.com/flyinggoatman/wk_wars2x/releases).
2. Place the `wk_wars2x` folder into your server's resource folder.
3. Add `ensure wk_wars2x` to your server configuration file.

Your server should now be set up to use the Wraith ARS 2X.

## Default Key Binds

The default key binds can be viewed in-game through the operator manual or in the table below.

| Action                        | Key                      | Description                                                                           |
| ----------------------------- | ------------------------ | ------------------------------------------------------------------------------------- |
| Open remote                   | F5                       | Opens the remote control if the driver is in a police vehicle.                        |
| Close remote                  | ESC / Right Mouse Button | Closes the remote/all displayed UI elements and returns focus to the game.            |
| Lock/unlock front antenna     | Numpad 8                 | Locks the current front antenna speed with audio confirmation.                        |
| Lock/unlock rear antenna      | Numpad 5                 | Locks the current rear antenna speed with audio confirmation.                         |
| Lock/unlock front plate       | Numpad 9                 | Locks the plate currently caught by the front plate reader, with a beep notification. |
| Lock/unlock rear plate        | Numpad 6                 | Locks the plate currently caught by the rear plate reader, with a beep notification.  |
| Copy front plate to clipboard | Numpad 1                 | Copies the front plate text to clipboard and shows a notification.                    |
| Copy rear plate to clipboard  | Numpad 3                 | Copies the rear plate text to clipboard and shows a notification.                     |
| Toggle keylock                | L                        | Toggles the keylock state, disabling keybinds until keylock is toggled again.         |

## Script Configuration

All configurations are done inside the `config.lua` file. Key options include setting default key binds, configuring operator menu defaults, and adjusting UI scale and safe zone.

### Key Configuration

```lua
-- Default key binds
CONFIG.keyDefaults = {
    remote_control = "f5",
    key_lock = "l",
    front_lock = "numpad8",
    rear_lock = "numpad5",
    plate_front_lock = "numpad9",
    plate_rear_lock = "numpad6",
    copy_front_plate = "numpad1",
    copy_rear_plate = "numpad3"
}
```

### Operator Menu Defaults

```lua
-- Default values for the operator menu
CONFIG.menuDefaults = {
    fastDisplay = true,     -- Display faster targets
    same = 0.6,             -- Same lane sensitivity
    opp = 0.6,              -- Opposite lane sensitivity
    beep = 0.6,             -- Audible beep volume
    voice = 0.6,            -- Verbal lock confirmation volume
    plateAudio = 0.6,       -- Plate reader audio volume
    speedType = "mph",      -- Speed unit (mph or kmh)
    fastLock = false,       -- Automatic speed locking
    fastLimit = 60          -- Speed limit for automatic locking
}
```

### UI Scale and Safe Zone

```lua
-- UI scale and safe zone configuration
CONFIG.uiDefaults = {
    scale = {
        radar = 0.75,
        remote = 0.75,
        plateReader = 0.75
    },
    safezone = 20  -- Safe zone size
}
```

## Suggestions

To suggest improvements, open a pull request with your code changes, or create an issue with a detailed description. Code should be well-formatted and commented.

## Reporting Issues

Open an issue if you encounter problems, providing detailed information on the issue and steps to reproduce it when applicable.
