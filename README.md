# Walking in Impossible Spaces

Godot 4 + OpenXR re-implementation of *Room Connection Techniques in VR for Walking in
Impossible Spaces* (Rebelo, Ferreira, Nóbrega, IEEE VR 2025), extended into a real-estate
walkthrough with a puzzle layer. Target: Meta Quest (standalone), 2.5 x 2.5 m play area.

Team: Ahmed, Dario, Narmeen, Sofia. Plan and schedule: see the shared project plan doc.

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
5. Debug: the **A button** (or **Tab** on desktop) cycles through the rooms.

## Structure

| Path | What | Owner |
|---|---|---|
| `core/room_manager.gd` | Autoload `RoomManager`: one active room at a time | A |
| `core/event_logger.gd` | Autoload `EventLogger`: CSV log per session | D |
| `core/play_area.gd` | `PlayArea`: 2.5 x 2.5 m size, boundary test, stride gain | A |
| `core/xr_rig/` | XR origin, hands, `StrideScaler`, `BoundaryMonitor` | A |
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
godot --headless --xr-mode off -s tests/smoke_test.gd   # exit code = failed checks
```

## Git workflow

- `main` always builds and runs on the Quest.
- One branch per feature, one teammate reviews before merge.
- One owner per `.tscn` file; pull before every session.
- Definition of done: runs on the Quest at 72 Hz, logs its events, merged, tried by a teammate.

## Notes

- The autoload is `EventLogger`, not `Logger`: Godot already has a built-in `Logger` class.
- `prepare_room()` instead of `preload()`: `preload` is a GDScript keyword.
- Stride scaling maps position absolutely from the calibrated origin, so leaving a scaled
  room does not shift the next one. Call `StrideScaler.recalibrate()` after recentering.
- Recommended: add the Godot OpenXR Vendors plugin (Meta) from the Asset Library for
  Quest-specific features (passthrough, hand tracking, boundary).
