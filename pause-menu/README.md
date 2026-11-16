# Screen check evidence for #3 (pause menu)

Captured at commit 7b000ab on the Factory VM (Xvfb virtual display, Godot 4.7.2,
Compatibility renderer on llvmpipe, `--fixed-fps 60`).

- `frame-0149.png`: round in play just before pause
- `frame-0180.png`: pause menu open over the frozen round, Resume focused
- `frame-0220.png`: after Down, Restart focused
- `frame-0260.png`: after Up, Resume focused again
- `frame-0320.png`: after cancel, round running again
- `pause-menu.mp4`: 6 s fixed-frame recording of the whole replay (Godot movie maker)

Replay from the game repository root at the PR head:

    godot --path . --fixed-fps 60 --script /path/to/pause-menu/replay.gd -- /path/to/pause-menu/pause-menu.replay.json /tmp/pause-captures
