# Team Sync

The one place where we tell each other what we are doing, what changed, and what we want to add.
Read it before you start a session. Update it before you push.

Team: Ahmed, Dario, Narmeen, Sofia.

## How to use this file

1. **Before you start:** pull, then read "Status board", "Changelog" and "Blockers".
2. **Before you push:** update your row in the status board and add a line to the changelog.
3. **Changed something others use** (a contract in Section 5 of the plan, a room size, a shared
   scene, project settings)? Add it under "Contract changes" and tell the group chat.
4. **Have an idea?** Add it to "Ideas". We decide at the next standup; nobody builds an idea
   before it is accepted.
5. Keep entries short (one line each), newest first, and start with the date and your name.
6. To avoid merge conflicts in this file, only edit your own rows and add new lines at the top
   of a list. If you get a conflict here, keep both sides.

---

## Status board

| Role | Owner | Working on now | Next | Blocked by |
|---|---|---|---|---|
| A. XR platform and locomotion | (assign) | | | |
| B. Portals and rendering | (assign) | | | |
| C. Rooms, corridors and hub | (assign) | | | |
| D. Tour, puzzles and data | (assign) | | | |

## Milestones

- [x] Codebase skeleton: core contracts, test rooms, smoke test, debug joystick locomotion
- [ ] **M0, Thu 26 Nov:** everyone deploys a build to the Quest, contracts agreed, area taped
- [ ] **M1, Tue 1 Dec:** walk between two rooms through a portal and a corridor on the Quest
- [ ] **M2, Fri 4 Dec:** full 5-room tour, all three techniques + stride scaling, runtime switch
- [ ] **M3, Tue 8 Dec:** puzzles in, pilot done, feature freeze at 18:00
- [ ] **M4, Wed 9 Dec:** final APK (tag v1.0), demo video, log analysis
- [ ] **Defense, Tue 15 Dec** and **Moodle upload, Fri 18 Dec**

## Changelog

Newest first. Format: `YYYY-MM-DD, name: what changed (files)`.

- 2026-11-25, Ahmed: project skeleton in `impossible-spaces/` from `basic-xr-scene`.
  Autoloads `RoomManager` and `EventLogger`; `Room`, `Connector`, `Portal`, `Corridor`,
  `HubDoor`, `RoomLayout`, `PlayArea`; `StrideScaler`, `BoundaryMonitor` and
  `DebugLocomotion` on the XR rig; test rooms `room_01` and `room_02`; `tests/smoke_test.gd`.
  See README for controls.

## Contract changes

Any change to a shared API, signal, scene structure or project setting. Say who is affected.

- 2026-11-25, Ahmed: names differ from the plan doc: `EventLogger` (not `Logger`, which is
  a built-in Godot class) and `RoomManager.prepare_room()` (not `preload()`, a GDScript keyword).
  Affects: everyone.
- 2026-11-25, Ahmed: use `XRCamera3D/HeadArea` (group `player`) for trigger zones; the old
  `Body` area does not follow the head. Affects: B, C.
- 2026-11-25, Ahmed: pinned **Godot 4.7.2 stable**. Affects: everyone.

## Room plan

The apartment as we agree on it. Owner C keeps this table up to date; everyone checks it
before building anything that sits inside a room (portals, puzzles, points of interest).
All rooms are centred on the 2.5 x 2.5 m play area. Stride gain = room size / 2.5 per axis.

| room_id | Name | Size (m) | Stride gain | Doors to | Contents (furniture, POIs, puzzles) | Status |
|---|---|---|---|---|---|---|
| room_01 | (test room) | 2.5 x 2.5 | 1 x 1 | room_02 | | placeholder |
| room_02 | (test room) | 5 x 2.5 | 2 x 1 | room_01 | | placeholder |
| | Entrance / living | | | | | to design |
| | Kitchen | | | | | to design |
| | Bedroom | | | | | to design |
| | Bathroom | | | | | to design |
| | Office | | | | | to design |
| hub | Central hub (hub layout only) | 2.5 x 2.5 | 1 x 1 | 3+ rooms | | to design |

### Layouts (same rooms, different connections)

| Layout | Connections (from -> to : connector) | Owner | Status |
|---|---|---|---|
| Portals | | B + C | to design |
| Corridors | | C | to design |
| Hub | | C | to design |
| Puzzle mode | portals + corridors mix (P2 needs a portal) | C + D | to design |

## Scene ownership

One owner per `.tscn`. Ask the owner before editing; or work in your own child scene.

| Scene | Owner |
|---|---|
| `main.tscn`, `core/xr_rig/xr_origin_3D.tscn` | A |
| `connectors/portal*.tscn` | B |
| `rooms/*.tscn`, `connectors/corridor*.tscn`, hub | C |
| `extension/**` | D (puzzle scenes: whoever builds that puzzle) |

## Ideas

Proposals for the project. Status: `proposed`, `accepted`, `later`, `rejected`.

| Date | Who | Idea | Effort (S/M/L) | Status |
|---|---|---|---|---|
| | | | | |

## Decisions

What we agreed on, so nobody has to ask again.

- 2026-11-25: extension = real-estate walkthrough as the core, puzzle layer on top.
- 2026-11-25: target = Meta Quest standalone; no AI component.
- 2026-11-25: joystick movement is a debug tool only; the experience uses natural walking.

## Blockers and questions

Anything stopping you, or a question for the group. Remove it when solved.

-

## Integration day checklist (Tue 1 Dec, Fri 4 Dec)

- [ ] Everyone pushed and merged to `main` the evening before
- [ ] `tests/smoke_test.gd` passes on `main`
- [ ] Fresh build deployed to the Quest from `main`
- [ ] Walk the full route in the taped area; note bugs under "Blockers" with an owner
- [ ] Record a 20 to 30 s clip for the final video
- [ ] Update "Status board" and "Milestones"
