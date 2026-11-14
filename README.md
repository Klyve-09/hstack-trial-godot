# Star Basket

A tiny 2D game about catching falling stars. Move the basket, collect ten points
per star, and try to beat your best score in a thirty-second round.

The three screens are the title menu (Start / Quit), the playing field, and the
round summary (score, best score, Play again / Title). There are no external
assets or runtime dependencies beyond Godot, and the game works offline.

## Requirements and setup

Use Godot 4.7.2 with GDScript. The project starts from the editor's standard empty
project format (`config_version=5`, Godot 4.7 feature tag) and uses the
Compatibility renderer for software OpenGL support. No asset downloads or
addons are needed. Audio is disabled because the game has no sound.

Import and run from the project directory:

```sh
godot --headless --path . --import
godot --path .
```

To edit the game, open `project.godot` in Godot or run:

```sh
godot --editor --path .
```

## Controls

- Move: A / D, left / right arrow keys, gamepad D-pad, or left stick.
- Menus: up / down arrows or D-pad to move focus; Enter, Space, or gamepad A
  (the south face button) to select. Tab / Shift+Tab also cycle through buttons.

Every menu focuses its first button and wraps between the two choices.
Movement bindings and menu confirmation are defined in the project's InputMap.

## Saved score

The only stored game data is the highest completed round score, saved with
`ConfigFile` to `user://save.cfg`, section `scores`, key `best`. On a standard
Linux installation this is
`~/.local/share/godot/app_userdata/Star Basket/save.cfg`.
Godot uses the corresponding app data directory on other operating systems.
Missing or invalid scores start at zero. Lower scores never overwrite a higher
one. A save failure is shown on the round summary; the in-memory best remains
available for the current session. Delete the file to reset the record.

## Tests and style

Run the dependency-free headless tests:

```sh
godot --headless --path . --script res://tests/run_tests.gd
```

The runner exits nonzero on failure. It covers scoring, time limits, save
round trips and damaged data, movement and catches, screen transitions, menu
focus, and simulated keyboard and gamepad events. It uses a separate temporary
save file and removes it afterward.

For formatting and linting, install Python 3.12 or newer and uv. Tool versions
and dependency hashes are pinned in `uv.lock`; these tools are not used by the
game itself.

```sh
uv --cache-dir .cache sync --locked
.venv/bin/gdformat --check scripts tests
.venv/bin/gdlint scripts tests
```

Apply formatting with `.venv/bin/gdformat scripts tests`.

## Build and smoke run

Build the game as a compiled resource pack using the included Linux preset.
This does not require installing native export templates:

```sh
mkdir -p build
godot --headless --path . --export-pack Linux build/star-basket.pck
godot --main-pack build/star-basket.pck
```

The pack is run with Godot 4.7.2. For a standalone Linux executable, install the
matching Godot export templates, then run:

```sh
godot --headless --path . --export-release Linux build/star-basket.x86_64
```

On Linux without a display, Xvfb can run a short windowed smoke check:

```sh
xvfb-run -a godot --path . --quit-after 300
```

## License

MIT. See LICENSE.
