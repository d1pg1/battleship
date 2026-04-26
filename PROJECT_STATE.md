# Naval Strike — Project State

**Engine:** Godot 4.6 · **Language:** GDScript · **Renderer:** Mobile (D3D12) · **Window:** 1280 × 720

---

## File Structure

```
res://
├── project.godot
├── DESIGN.md
├── PROJECT_STATE.md
├── autoload/
│   └── game_manager.gd          ← AutoLoad singleton
├── resources/
│   └── ship_data.gd             ← ShipData Resource class
├── scripts/
│   ├── board_state.gd
│   ├── grid_display.gd
│   ├── ai_controller.gd
│   ├── placement_controller.gd
│   ├── hud.gd
│   ├── battle_screen.gd
│   ├── result_screen.gd
│   └── main_menu.gd
└── scenes/
    ├── main_menu.tscn
    ├── placement_screen.tscn
    ├── battle_screen.tscn
    └── result_screen.tscn
```

---

## Screen Flow

```
main_menu.tscn
    │  [VS AI]
    ▼
placement_screen.tscn
    │  [START BATTLE]  (enabled only when all 10 ships placed)
    ▼
battle_screen.tscn
    │  [game over]            [⬅ MENU]
    ▼                              ▼
result_screen.tscn         main_menu.tscn
    │  [PLAY AGAIN]   [MAIN MENU]
    ▼                      ▼
placement_screen.tscn  main_menu.tscn
```

Local PvP uses the same placement and battle scenes:

```
main_menu.tscn
    │  [LOCAL PVP]
    ▼
placement_screen.tscn
    │  Player 1 places fleet → [NEXT PLAYER]
    │  Player 2 places fleet → [START BATTLE]
    ▼
battle_screen.tscn
    │  pass-and-play handoff overlay whenever turn control changes
    ▼
result_screen.tscn
```

AI vs AI skips placement and starts a watchable simulation:

```
main_menu.tscn
    │  [AI VS AI]
    ▼
battle_screen.tscn
    │  both fleets random-placed and visible
    ▼
result_screen.tscn
```

Campaign mode adds a playable Kolobok progression on top of the normal VS AI loop:

```
main_menu.tscn
    │  [CAMPAIGN]
    ▼
placement_screen.tscn
    │  place fleet → [START BATTLE]
    ▼
battle_screen.tscn
    │  fight current Kolobok opponent
    ▼
result_screen.tscn
    │  [NEXT LEVEL] / [RETRY LEVEL]
    ▼
placement_screen.tscn
```

Campaign levels use the standard 10×10 fleet and existing battle rules. Grandparents and Hare use simple random-fire AI profiles with different pacing; Wolf and later campaign opponents use hunt/target AI, with special abilities layered on top for Bear, Kolobok, Fox, and True Kolobok.

Campaign placement now begins with a click-through dialogue overlay using placeholder character portraits, before the player can place ships. Level 1 also includes tutorial copy during placement and opening dialogue that explains placement spacing, firing, hits, misses, and turn changes.

Campaign abilities are active:
- Hare and True Kolobok can force a timed player turn; if the player waits too long, the turn passes.
- Bear and True Kolobok can launch a cross-shaped area strike on cooldown.
- Kolobok and True Kolobok can relocate one unhit hidden ship after the player lands a hit.
- Fox and True Kolobok can spend limited false signals that make a miss feel suspicious in the HUD while the board still records the real miss.

All scene transitions use `get_tree().call_deferred("change_scene_to_file", path)` to avoid mid-signal crashes.

---

## Fleet Composition

10 ships total (Russian Battleship ruleset):

| Class       | Size | Count |
|-------------|------|-------|
| Battleship  | 4    | 1     |
| Cruiser     | 3    | 2     |
| Destroyer   | 2    | 3     |
| Patrol      | 1    | 4     |

Same fleet is used for both the player and the AI.

---

## Placement Rules

- Horizontal or vertical only.
- Ships may not overlap.
- No two ships may occupy adjacent cells, **including diagonals** — there must be at least one empty cell gap in all 8 directions between any two ships.
- These rules are enforced in `BoardState.can_place()` and apply to both manual placement and random auto-fill.

---

## Combat Rules

- A hit keeps the turn with the current shooter; a miss passes turn control.
- In `VS_AI`, the AI keeps firing every 0.8 seconds while it hits, then control returns to the player after an AI miss.
- In `LOCAL_PVP`, the pass-and-play handoff overlay appears only after a miss changes the active player.
- Cannot re-fire at a cell already marked HIT or MISS.
- When a ship is **sunk**, all surrounding empty cells (8-directional) are automatically revealed as MISS — the player cannot waste shots there, and the AI's internal fired list absorbs them so it won't target them either.
- Game ends immediately when all ships on one side are sunk.
- AI shots are paced by a one-shot Timer in GameManager.

---

## Scripts

### `resources/ship_data.gd` — `class_name ShipData extends Resource`

Pure data object describing one ship.

| Member | Type | Description |
|--------|------|-------------|
| `ship_name` | `String` | Display name (e.g. "Cruiser 1") |
| `size` | `int` | Cell count (1–4) |
| `origin` | `Vector2i` | Top-left cell of the ship |
| `horizontal` | `bool` | Orientation flag |
| `hit_count` | `int` | Incremented on each hit |
| `is_placed` | `bool` | True once placed on a board |

Key methods: `cells() → Array[Vector2i]` (derived from origin/size/horizontal), `is_sunk() → bool`, `reset()`.

---

### `scripts/board_state.gd` — `class_name BoardState extends RefCounted`

Pure data layer for one 10×10 grid. Two instances live on `GameManager` (`player_board`, `ai_board`).

**Cell states:** `EMPTY = 0`, `SHIP = 1`, `HIT = 2`, `MISS = 3`

Key methods:

| Method | Description |
|--------|-------------|
| `can_place(data)` | Validates bounds, no overlap, no diagonal adjacency |
| `place_ship(data) → bool` | Writes SHIP cells, appends to `ships` |
| `remove_ship(data)` | Erases SHIP cells, resets ship state |
| `fire(cell) → Dict` | Returns `{result: Cell, sunk_ship: ShipData\|null}` |
| `reveal_surroundings(data) → Array[Vector2i]` | Marks all empty adjacent cells as MISS on ship sunk; returns revealed list |
| `all_sunk() → bool` | True when every ship in `ships` is sunk (guards against empty fleet) |
| `is_already_fired(cell) → bool` | True if state is HIT or MISS |
| `random_place_all(fleet_defs)` | Places ships from a definition array with adjacency rules; max 10,000 attempts per ship |

---

### `autoload/game_manager.gd` — AutoLoad singleton (name: `GameManager`)

Owns the state machine and both board instances. All other scripts talk to game logic exclusively through this node and its signals — no direct cross-scene references.

**Modes:** `VS_AI`, `LOCAL_PVP`, `AI_VS_AI`

**States:** `PLACEMENT → PLAYER_TURN → AI_TURN / RESULT_PAUSE / HANDOFF → GAME_OVER`

In local PvP, `player_board` is Player 1's board and `ai_board` is Player 2's board. In AI vs AI, those same boards are AI 1 and AI 2.

Hits retain the current turn. `RESULT_PAUSE` and `HANDOFF` are used only in `LOCAL_PVP` after a miss changes control.

**Signals:**

| Signal | Payload | Listeners |
|--------|---------|-----------|
| `turn_changed` | `new_state: State` | `GridDisplay`, `HUD` |
| `shot_fired` | `cell: Vector2i, result: Dict` | `GridDisplay`, `HUD` |
| `ship_placed` | `data: ShipData` | *(available, unused by UI directly)* |
| `ship_sunk` | `data: ShipData, owner: String` | `GridDisplay`, `HUD` |
| `game_ended` | `winner: String` | `BattleScreen` |

`owner` is `"player"` when the player's ship is sunk, `"ai"` when the AI's ship is sunk.

**Key behaviour:**
- `player_fire(cell)` — guarded to `PLAYER_TURN` state; calls `reveal_surroundings` before emitting `ship_sunk`; on miss starts the 0.8s Timer and transitions to `AI_TURN`.
- `_on_ai_timer_timeout()` — calls `_ai.choose_cell()`, fires, calls `_ai.on_fire_result()` and `_ai.add_to_fired()` for auto-revealed cells, transitions back to `PLAYER_TURN`.
- `reset()` — recreates both `BoardState` instances, clears `last_winner` and `_ai`. Called on Play Again and Menu navigation.
- `_run_ai_vs_ai_turn()` — uses separate AIController instances for AI 1 and AI 2; hits keep the same active AI, misses swap control.

---

### `scripts/grid_display.gd` — `class_name GridDisplay extends Node2D`

Renders one 10×10 grid entirely via `_draw()`. No game logic. Two instances per battle: one for the enemy grid (interactive, ships hidden), one for the player grid (read-only, ships visible).

**Exported properties:**

| Property | Default | Purpose |
|----------|---------|---------|
| `interactive` | `false` | Enables click detection and hover highlight |
| `hide_ships` | `false` | Renders SHIP cells as ocean blue (enemy grid) |
| `is_enemy_grid` | `false` | Gates sunk reveal and turn-based interactivity |

**Draw constants:** `CELL_SIZE = 56 px`, `LABEL_OFFSET = 20 px` — total grid draw area is 580 × 580 px.

**Draw order** (each layer on top of previous):
1. Column labels A–J
2. Row labels 1–10
3. Cell fills (EMPTY = ocean blue, SHIP = grey, HIT = red, MISS = light grey)
4. Sunk ship reveal — orange fill + white outline (enemy grid only, accumulated in `_revealed_ships`)
5. Ghost ship preview — green (valid) or red (invalid) semi-transparent overlay (placement phase)
6. Grid lines
7. Hover highlight — white 22% alpha (interactive cells not yet fired)

**Click detection:** `_input` converts `mb.global_position` via `to_local()` to a grid cell, emits `cell_tapped` if in bounds and not already fired.

**Signal responses:**
- `turn_changed` → enemy grid toggles `interactive`; all grids call `queue_redraw()`
- `ship_sunk` → enemy grid appends to `_revealed_ships`; all grids redraw
- `shot_fired` → all grids redraw
- `game_ended` → all grids set `interactive = false`

---

### `scripts/ai_controller.gd` — `class_name AIController extends Node`

Hunt/Target AI. Stateful, no scene dependencies. One instance lives in `battle_screen.tscn`.

**Algorithm:**

- **HUNT mode:** Builds a checkerboard candidate list (`(row + col) % 2 == 0`, not already fired). Shuffles and picks the first. Falls back to all unfired cells when the checkerboard is exhausted late-game.
- **TARGET mode:** Entered on first hit. Queues the 4 orthogonal neighbours. On the second consecutive hit, locks the axis (horizontal/vertical) and switches to axial extension only. Reverts to HUNT when the queue is exhausted or a ship is sunk.
- `on_fire_result(cell, result)` — called by GameManager after every AI shot; updates mode and queues.
- `add_to_fired(cells)` — absorbs auto-revealed surroundings cells so the AI never attempts to fire there.

---

### `scripts/placement_controller.gd` — `class_name PlacementController extends Node`

Manages the placement phase UI. Lives in `placement_screen.tscn`.

**Fleet constant `FLEET`** — array of 10 `{name, size}` dicts; used for building sidebar buttons and random auto-fill.

**Interaction model:** tap a sidebar button to select a ship → ghost follows the mouse → tap the grid to place. Selected ship updates its `origin` each frame in `_process` via `get_viewport().get_mouse_position()`. The `R` key and Rotate button both toggle orientation.

**Random fill:** iterates `_fleet_data` in order, tries up to 10,000 random origins/orientations per ship (respects adjacency rules via `can_place`). Uses the existing `ShipData` objects so sidebar button references stay intact.

**Start Battle:** disabled until `GameManager.player_board.ships.size() == FLEET.size()` (all 10 placed).

---

### `scripts/hud.gd` — `class_name HUD extends Control`

Displays turn state and shot feedback. Script is attached to the `HUD` Control node inside `UILayer` (CanvasLayer) in `battle_screen.tscn`.

| Label | Content | Duration |
|-------|---------|---------|
| `TurnLabel` | "YOUR TURN" / "ENEMY FIRING..." | Persistent |
| `FeedbackLabel` | "HIT!" (red) / "MISS" (grey-blue) | 1.5 s auto-clear |
| `SunkLabel` | "[SHIP] SUNK!" | 2.0 s auto-clear |

---

### `scripts/battle_screen.gd` — `extends Node2D`

Thin coordinator for the battle scene. Responsibilities:
- Injects `board_state` references into both `GridDisplay` nodes.
- Calls `GameManager.ai_board.random_place_all(...)` to place AI ships invisibly in `VS_AI` mode.
- In `LOCAL_PVP`, rebinds the two grids from the active player's perspective each turn.
- In `AI_VS_AI`, random-places both boards, shows both fleets, and starts the simulation timer.
- Connects `EnemyGridDisplay.cell_tapped → GameManager.fire_at_target`.
- Shows the pass-and-play handoff overlay before each local PvP turn.
- Connects `GameManager.game_ended → result_screen` scene transition.
- Connects `MenuButton.pressed → GameManager.reset() + main_menu` scene transition.

---

### `scripts/result_screen.gd` — `class_name ResultScreen extends Control`

Reads `GameManager.last_winner` in `_ready()`. Displays "VICTORY" / "DEFEAT" in `VS_AI`, "PLAYER 1 WINS" / "PLAYER 2 WINS" in `LOCAL_PVP`, or "AI 1 WINS" / "AI 2 WINS" in `AI_VS_AI`. Play Again → reset + placement screen, except `AI_VS_AI` which restarts battle directly. Main Menu → reset + main menu.

### `scripts/main_menu.gd` — `class_name MainMenu extends Control`

VS AI → sets `GameManager.mode = VS_AI` and opens placement. Local PvP → sets `GameManager.mode = LOCAL_PVP` and opens placement. AI vs AI → sets `GameManager.mode = AI_VS_AI` and opens battle directly. Quit → `get_tree().quit()`.

---

## Scene Node Hierarchies

### `main_menu.tscn`
```
MainMenu (Control, script: main_menu.gd)
├── Background (ColorRect, dark blue)
└── VBox (VBoxContainer, centred)
    ├── TitleLabel    "NAVAL STRIKE"  48px
    ├── SubtitleLabel "Battleship"    18px
    ├── Spacer
    ├── VsAIButton
    ├── Spacer2
    ├── LocalPvpButton
    ├── Spacer3
    ├── AIVsAIButton
    ├── Spacer4
    └── QuitButton
```

### `placement_screen.tscn`
```
PlacementScreen (Node2D)
├── Background (ColorRect, 1280×720)
├── PlacementController (Node, script: placement_controller.gd)
├── PlayerGridDisplay (Node2D @ 40,70, script: grid_display.gd)
│     interactive=true  hide_ships=false  is_enemy_grid=false
└── Sidebar (Control @ 640,0, size 640×720)
    ├── SidebarBG (ColorRect)
    └── VLayout (VBoxContainer)
        ├── TitleLabel  "PLACE YOUR FLEET"
        ├── InstructLabel
        ├── ShipList (VBoxContainer)  ← 10 buttons added at runtime
        ├── RotateButton  "ROTATE [R]"
        ├── RandomButton  "RANDOM PLACEMENT"
        └── StartButton   "START BATTLE"  (disabled until fleet complete)
```

Grid occupies x=40–620, y=70–650. Sidebar occupies x=640–1280.

### `battle_screen.tscn`
```
BattleScreen (Node2D, script: battle_screen.gd)
├── AIController (Node, script: ai_controller.gd)
├── AIControllerP2 (Node, script: ai_controller.gd)
├── Background (ColorRect, 1280×720)
├── EnemyGridDisplay (Node2D @ 20,70, script: grid_display.gd)
│     interactive=true  hide_ships=true  is_enemy_grid=true
├── PlayerGridDisplay (Node2D @ 660,70, script: grid_display.gd)
│     interactive=false  hide_ships=false  is_enemy_grid=false
└── UILayer (CanvasLayer)              ← viewport-anchored so HUD elements resolve correctly
    └── HUD (Control fullscreen, script: hud.gd)
        ├── TopBar (ColorRect, 1280×62, dark overlay)
        ├── MenuButton   "⬅ MENU"  top-left  (8,10)–(108,52)
        ├── TurnLabel    centred   anchor 0.5, ±140px
        ├── FeedbackLabel centred  anchor 0.5, ±140px
        ├── SunkLabel    right     anchor 1.0, –260 to –10px
        ├── EnemyLabel   "ENEMY WATERS — click to fire"  bottom-left
        └── PlayerLabel  "YOUR FLEET"  bottom-right
    └── HandoffOverlay (Control fullscreen, local PvP only)
        ├── Scrim
        └── Panel
            └── VBox
                ├── HandoffLabel "PASS TO PLAYER N"
                ├── Spacer
                └── ReadyButton  "READY"
```

Enemy grid: x=20–600, y=70–650. Player fleet: x=660–1240, y=70–650.

### `result_screen.tscn`
```
ResultScreen (Control fullscreen, script: result_screen.gd)
├── Background (ColorRect, dark navy)
└── VBox (VBoxContainer, centred)
    ├── ResultLabel    "VICTORY" / "DEFEAT"  56px
    ├── Spacer
    ├── PlayAgainButton
    ├── Spacer2
    └── MenuButton
```

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| `CanvasLayer` wrapping `HUD` in battle screen | Control anchors inside `Node2D` resolve against zero size; `CanvasLayer` always provides viewport dimensions |
| All scene changes via `call_deferred` | Calling `change_scene_to_file` inside a signal handler can crash if the emitting node is freed mid-signal |
| `PlacementController` reuses `_fleet_data` objects for random fill | Keeps sidebar `Button` references valid; avoids a sync pass between new `ShipData` objects and the UI |
| `reveal_surroundings` called before `ship_sunk` signal | Grid display redraws on `ship_sunk`; the MISS cells must already be in `board_state` at that moment |
| `AIController.add_to_fired` absorbs auto-revealed cells | Prevents the AI from wasting a turn firing at a cell that was already auto-opened as MISS |
| `class_name` removed from `game_manager.gd` | Having `class_name GameManager` conflicts with the AutoLoad singleton of the same name; the AutoLoad is accessed directly by its registered name |
