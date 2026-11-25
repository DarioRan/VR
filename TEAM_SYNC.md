# Team Sync

The one place where we tell each other what we are doing, what changed, and what we want to add.
Read it before you start a session. Update it before you push.

Team: Ahmed, Dario, Narmeen, Sofia.

## How to use this file

1. **Before you start:** pull, then read "Status board", "Changelog" and "Blockers".
2. **Before you push:** update your row in the status board, your tickets' status, and add a
   line to the changelog.
3. **Changed something others use** (a contract in Section 5 of the plan, a room size, a shared
   scene, project settings)? Add it under "Contract changes" and tell the group chat.
4. **Have an idea?** Add it to "Ideas". We decide at the next standup; nobody builds an idea
   before it is accepted.
5. Keep entries short (one line each), newest first, and start with the date and your name.
6. To avoid merge conflicts in this file, only edit your own rows and add new lines at the top
   of a list. If you get a conflict here, keep both sides.

---

## Status board

| Role | Owner | Working on now (ticket) | Next | Blocked by |
|---|---|---|---|---|
| A. XR platform and locomotion | Ahmed | A-01 to A-09 on branch `feature/a-xr-platform` | Test on the Quest, merge | needs headset time |
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

## Project plan

Full plan (architecture, technical notes, risks): the shared "2-Week Implementation Plan" doc.

**Goal by Wed 9 Dec:** a standalone Quest build that (1) re-implements portals, corridors,
the central hub and stride scaling in one 2.5 x 2.5 m play area, (2) wraps them in a 5-room
real-estate walkthrough with a runtime technique switch, (3) adds overlap puzzles on top, and
(4) logs time, boundary hits and room transitions for a small pilot.

**Key dates:** integration days Tue 1 and Fri 4 Dec · feature freeze Tue 8 Dec 18:00 ·
final build Wed 9 Dec · paper and rehearsal 10 to 14 Dec · defense Tue 15 Dec · Moodle Fri 18 Dec.
Weekends are buffer only.

**If we run late, cut from the bottom:** Must > Should > Could (column P below).

### How to use the tickets

- **Status:** `todo` · `doing (Name)` · `v0` (first version merged, needs more work) · `done` · `cut`
- Take a ticket by setting its status to `doing (YourName)`. Set `done` only when it meets the
  definition of done: runs on the Quest at 72 Hz, logs its events, merged to `main`, tried by a teammate.
- New work gets a new ID at the end of its area (for example `C-14`) and a changelog line.
- Owner = role from the status board (A, B, C, D) or `All`.

### Setup (M0, Thu 26 Nov)

| ID | Ticket | Owner | Due | P | Status |
|---|---|---|---|---|---|
| SET-01 | Repo and Godot project skeleton: contracts, autoloads, test rooms, smoke test | Ahmed | 25 Nov | Must | done |
| SET-02 | Debug joystick locomotion (left stick move, right stick snap turn) | Ahmed | 25 Nov | Should | done |
| SET-03 | TEAM_SYNC.md for status, changes, room plan, ideas and tickets | Ahmed | 25 Nov | Must | done |
| SET-04 | Kickoff: assign roles A to D, agree on the contracts (plan Section 5) | All | 26 Nov | Must | todo |
| SET-05 | Each machine: Godot 4.7.2, Android SDK + JDK 17, Android build template | All | 26 Nov | Must | todo |
| SET-06 | Each person deploys a build to the Quest (**M0**) | All | 26 Nov | Must | todo |
| SET-07 | Install Git LFS on each machine (`brew install git-lfs && git lfs install`) | All | 26 Nov | Must | todo |
| SET-08 | Tape the 2.5 x 2.5 m area; reserve a room for integration days and the pilot | All | 26 Nov | Must | todo |
| SET-09 | Add the Godot OpenXR Vendors (Meta) plugin and check it on the Quest | A | 27 Nov | Should | todo |

### A. XR platform and locomotion

| ID | Ticket | Owner | Due | P | Status |
|---|---|---|---|---|---|
| A-01 | XR rig on the Quest: controllers, sphere hands, hold-to-recenter on the taped square, refresh rate | A | 27 Nov | Must | v0 |
| A-02 | RoomManager v1: one active room, `prepare_room`, enter/exit signals | A | 30 Nov | Must | v0 |
| A-03 | Stride scaling per room, tested on the headset | A | 2 Dec | Must | v0 |
| A-04 | Hide the view jump when the stride gain changes at a room swap (fade to black) | A | 3 Dec | Should | v0 |
| A-05 | Boundary-hit detection and logging | A | 3 Dec | Must | v0 |
| A-06 | Boundary warning: darken the view near the edge | A | 3 Dec | Should | v0 |
| A-07 | Stride gain cap for the pilot (1.25 / 1.5 / 2.0, left Y button), logged | A | 7 Dec | Should | v0 |
| A-08 | Performance: 72 Hz, physics at display rate, foveation, MSAA 2x, `PerfMonitor` log; verify on the Quest | A | 7 Dec | Must | v0 |
| A-09 | Build script `scripts/build_quest.sh`, final APK, tag `v1.0` (**M4**) | A | 9 Dec | Must | v0 |

### B. Portals and rendering

| ID | Ticket | Owner | Due | P | Status |
|---|---|---|---|---|---|
| B-01 | Desktop portal prototype: SubViewport + camera following the player relative to the paired portal | B | 27 Nov | Must | todo |
| B-02 | Portal crossing triggers RoomManager | B | 30 Nov | Must | v0 |
| B-03 | Portal running on the Quest (mono preview), measure fps | B | 30 Nov | Must | todo |
| B-04 | Portal polish: clipping, half-res viewport, render only when on screen | B | 2 Dec | Must | todo |
| B-05 | Placement check: portals must sit inside the play area | B | 2 Dec | Should | todo |
| B-06 | Align the player to the destination portal after crossing | B | 2 Dec | Must | todo |
| B-07 | Smooth transition, no flicker on crossing | B | 3 Dec | Should | todo |
| B-08 | Preview on hub doors | B | 3 Dec | Could | todo |
| B-09 | Stereo-correct portals | B | n/a | Could | todo |
| B-10 | Puzzle P2: keypad code visible only through a portal | B | 7 Dec | Should | todo |
| B-11 | Record the demo video (with C) | B | 9 Dec | Must | todo |

### C. Rooms, corridors and hub

| ID | Ticket | Owner | Due | P | Status |
|---|---|---|---|---|---|
| C-01 | Draw the 5-room floor plan with real sizes; fill in the Room plan table below | C | 27 Nov | Must | todo |
| C-02 | Greybox rooms 1 and 2 (replace the test rooms) | C | 27 Nov | Must | todo |
| C-03 | Corridor v1: L-shaped corridor scene, swap when the old door is out of view | C | 30 Nov | Must | v0 |
| C-04 | Corridor way back (to_room -> from_room) | C | 2 Dec | Must | todo |
| C-05 | Central hub room with 3+ HubDoors and the way back to the hub | C | 2 Dec | Must | todo |
| C-06 | Greybox rooms 3 to 5 | C | 2 Dec | Must | todo |
| C-07 | The same floor plan built 3 ways (one `RoomLayout` per technique) | C | 3 Dec | Must | todo |
| C-08 | Puzzle designs on paper (with D) | C | 4 Dec | Must | todo |
| C-09 | Puzzle P1: key from the bedroom opens a door that leads back to room 1 | C | 7 Dec | Must | todo |
| C-10 | Auto-fit the layout to any play-area size | C | n/a | Could | todo |
| C-11 | Record the demo video (with B) | C | 9 Dec | Must | todo |

### D. Tour, puzzles and data

| ID | Ticket | Owner | Due | P | Status |
|---|---|---|---|---|---|
| D-01 | EventLogger: one CSV per session, pull with adb | D | 27 Nov | Must | v0 |
| D-02 | Debug HUD: room, technique, fps, distance to boundary | D | 27 Nov | Should | todo |
| D-03 | Tour task v1: points of interest per room, collect, return to room 1 | D | 30 Nov | Must | todo |
| D-04 | Hook log events to RoomManager signals | D | 1 Dec | Must | v0 |
| D-05 | Runtime technique switch (wrist menu) -> `RoomManager.set_technique` + layout swap | D | 2 Dec | Must | todo |
| D-06 | Real-estate content: room names, area panels, CC0 furniture | D | 3 Dec | Should | todo |
| D-07 | Puzzle designs on paper (with C) | D | 4 Dec | Must | todo |
| D-08 | Puzzle state manager (flags + events) and tutorial room | D | 7 Dec | Must | todo |
| D-09 | Pilot protocol: counterbalanced order, 1 to 5 ratings (presence, sickness, floor-plan sketch) | D | 7 Dec | Should | todo |
| D-10 | Participant ID setting before each session | D | 7 Dec | Should | todo |
| D-11 | Minimap | D | n/a | Could | todo |
| D-12 | Log analysis and charts for the paper | D | 9 Dec | Must | todo |

### Shared: integration, pilot, paper

| ID | Ticket | Owner | Due | P | Status |
|---|---|---|---|---|---|
| ALL-01 | Integration day 1: two rooms via a portal and a corridor on the Quest (**M1**) | All | 1 Dec | Must | todo |
| ALL-02 | Integration day 2: full 5-room tour, 3 techniques + stride, bug list (**M2**) | All | 4 Dec | Must | todo |
| ALL-03 | Puzzle P3: impossible geometry (object seen from two overlapping rooms) | C + D | 8 Dec | Should | todo |
| ALL-04 | Bug fixing before the freeze | All | 8 Dec | Must | todo |
| ALL-05 | Pilot: team + 2 to 4 classmates, all three techniques | All | 8 Dec | Should | todo |
| ALL-06 | Feature freeze at 18:00 (**M3**) | All | 8 Dec | Must | todo |
| ALL-07 | 20 to 30 s clip at each milestone (raw material for the video) | All | each M | Should | todo |
| ALL-08 | One paper paragraph per role on your feature | All | 9 Dec | Must | todo |
| ALL-09 | 2-page paper: edit and finalize | All | 14 Dec | Must | todo |
| ALL-10 | Slides and 2 rehearsals | All | 14 Dec | Must | todo |
| ALL-11 | Defense with live demo | All | 15 Dec | Must | todo |
| ALL-12 | Moodle upload: project, code, video | All | 18 Dec | Must | todo |

## Changelog

Newest first. Format: `YYYY-MM-DD, name: what changed (files)`. Mention ticket IDs.

- 2026-11-25, Ahmed: A-01 to A-09 on branch `feature/a-xr-platform`: hold-to-recenter,
  72 Hz + physics rate, foveation, MSAA 2x, `ScreenFade` (boundary warning + fade on gain
  jumps), gain-cap presets, play-area footprint, `PerfMonitor`, `scripts/build_quest.sh`,
  hands fixed (spheres were stretched to 1 m tall). Smoke test: 23 checks. Needs a Quest test.
- 2026-11-25, Ahmed: added the project plan and all tickets (SET, A, B, C, D, ALL) to this file.
- 2026-11-25, Ahmed: project skeleton in `impossible-spaces/` from `basic-xr-scene`.
  Autoloads `RoomManager` and `EventLogger`; `Room`, `Connector`, `Portal`, `Corridor`,
  `HubDoor`, `RoomLayout`, `PlayArea`; `StrideScaler`, `BoundaryMonitor` and
  `DebugLocomotion` on the XR rig; test rooms `room_01` and `room_02`; `tests/smoke_test.gd`.
  See README for controls.

## Contract changes

Any change to a shared API, signal, scene structure or project setting. Say who is affected.

- 2026-11-25, Ahmed: `StrideScaler.recalibrate()` is gone; recentering is
  `XROrigin3D.recenter()` (signal `recentered`), which also calls `StrideScaler.reset_base()`.
  New `ScreenFade` under `XRCamera3D`: use `flash()` to hide any jump (B: portal alignment).
  Affects: B, D.
- 2026-11-25, Ahmed: project settings: foveation high + dynamic, MSAA 3D 2x. The physics rate
  follows the headset refresh rate (72 Hz). Affects: everyone.

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
