# Walking in Impossible Spaces

Godot 4 + OpenXR re-implementation of *Room Connection Techniques in VR for Walking in
Impossible Spaces* (Rebelo, Ferreira, Nóbrega, IEEE VR 2025), extended into a real-estate
walkthrough with a puzzle layer. Target: Meta Quest (standalone), 2.5 x 2.5 m play area.

Team: Ahmed, Dario, Narmeen, Sofia. Plan and schedule: see the shared project plan doc.

**Read and update [`TEAM_SYNC.md`](TEAM_SYNC.md) every session:** status, changes, room plan, ideas.

## Requirements

- **Godot 4.7.2 stable** (everyone on the same version)
- Android SDK + JDK 17, configured in Editor Settings > Export > Android
- Quest in developer mode, connected over USB (`adb devices` should list it)
- Git LFS: `brew install git-lfs && git lfs install` (once per machine)

## Getting started

1. Open `impossible-spaces/project.godot` in Godot.
2. `Project > Install Android Build Template...` (the `android/` folder is not in git).
3. Run on desktop (F5): no headset is found, so the XR simulator starts
   (see `addons/xr-simulator` for the controls).
4. Run on the Quest: plug it in and use the one-click deploy button with the `MetaHeadset` preset.
5. **Calibrate** each time you put the headset on: stand in the centre of the taped square,
   face the front edge, hold the **left menu button** for 1 s (or hold the Meta button).
6. Controls:

   | Action | Quest | Desktop simulator |
   |---|---|---|
   | Recenter on the taped square | hold left menu button 1 s (or Meta button) | R |
   | Cycle stride gain cap 1.25 / 1.5 / 2.0 (pilot) | left Y | G |
   | Move, debug only (relative to where you look) | left stick | W A S D |
   | Snap turn 30 degrees, debug only | right stick left/right | left/right arrows |
   | Cycle rooms, debug only | A button | Tab |

   Joystick movement is for testing without walking and is off in release builds. It moves
   the whole play area, so it is logged once per session as `debug_locomotion_used`.
   Recentering undoes it. Settings are on the `DebugLocomotion` node in
   `core/xr_rig/xr_origin_3D.tscn`.

## Building for the Quest

```bash
export GODOT=/Applications/Godot.app/Contents/MacOS/Godot
scripts/build_quest.sh debug --install   # build, install and launch
scripts/build_quest.sh release           # final build (needs the release keystore, see the script)
```

APKs go to `exports/` (not in git). Quest settings in the project: 72 Hz (physics matched to
the refresh rate), Stage reference space, high dynamic foveation, 2x MSAA.

## Structure

| Path | What | Owner |
|---|---|---|
| `core/room_manager.gd` | Autoload `RoomManager`: one active room at a time | A |
| `core/event_logger.gd` | Autoload `EventLogger`: CSV log per session | D |
| `core/play_area.gd` | `PlayArea`: 2.5 x 2.5 m size, boundary test, stride gain | A |
| `core/xr_rig/` | XR origin (recenter, refresh rate), hands, `StrideScaler`, `BoundaryMonitor`, `ScreenFade`, `PerfMonitor`, `DebugLocomotion` | A |
| `rooms/room.gd` + `room_XX.tscn` | `Room` contract and room scenes | C |
| `connectors/connector.gd` | `Connector` base class + `Technique` enum | A |
| `connectors/portal.gd` | `Portal` (crossing works, preview is TODO) | B |
| `connectors/corridor.gd`, `hub_door.gd` | `Corridor`, `HubDoor` (swap when old door is out of view) | C |
| `layouts/room_layout.gd` | `RoomLayout`: the floor plan built with one technique | C |
| `extension/` | tour, puzzles, ui | D (+ B, C for puzzles) |
| `tests/smoke_test.gd` | headless checks of the contracts | all |
| `main.tscn` | rig + all rooms on the same floor | A |

`room_01` (2.5 x 2.5 m) and `room_02` (5 x 2.5 m, stride gain 2 on x) are test rooms. Replace them.

## Contracts (plan Section 5)

- **Room**: root script `Room`, with `room_id`, `floor_size`, a `Spawn` marker and one
  `Door_<target_room_id>` marker per exit. Rooms are centred on the play area and register
  themselves with RoomManager.
- **RoomManager**: `activate(room_id, technique)`, `prepare_room(room_id)`, `set_technique(t)`,
  `current_room`, signals `room_entered`, `room_exited`, `technique_changed`.
- **Connector**: `from_room`, `to_room`, `technique`; subclasses call `notify_crossed()`.
- **EventLogger**: `EventLogger.log_event("name", {...})`. Columns:
  `t_ms,participant,technique,room,event,head_x,head_z,data`.
- The head-tracked `XRCamera3D/HeadArea` is in the `player` group (use it for trigger zones).

## Logs

Saved to `user://logs/session_<date>.csv`. From the Quest:

```bash
adb pull /sdcard/Android/data/fr.ubx.impossiblespaces/files/logs/ logs/
```

## Tests

```bash
cd impossible-spaces
godot --headless --xr-mode off -s tests/smoke_test.gd   # 23 checks, exit code = failed checks
```

## Git workflow

- Update `TEAM_SYNC.md` (status row + changelog line) with every push.
- `main` always builds and runs on the Quest.
- One branch per feature, one teammate reviews before merge.
- One owner per `.tscn` file; pull before every session.
- Definition of done: runs on the Quest at 72 Hz, logs its events, merged, tried by a teammate.

## Notes

- The autoload is `EventLogger`, not `Logger`: Godot already has a built-in `Logger` class.
- `prepare_room()` instead of `preload()`: `preload` is a GDScript keyword.
- Stride scaling maps position absolutely from the calibrated origin, so leaving a scaled
  room does not shift the next one. When the gain changes at a room swap and the view would
  jump more than 5 cm, the screen fades to black for about 0.3 s to hide it.
- Use `ScreenFade.flash()` (child of `XRCamera3D`) for any other teleport-like change.
- `PerfMonitor` logs a `perf` event every 5 s (average fps, worst frame, missed frames).
- Recommended: add the Godot OpenXR Vendors plugin (Meta) from the Asset Library for
  Quest-specific features (passthrough, hand tracking, boundary).
