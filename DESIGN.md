# NAVAL STRIKE — Game Design Document

**Version:** 1.0 | **Team:** Solo Dev | **Time Budget:** 5 Hours | **Platform:** PC / Windows  
**Engine:** Godot 4 / GDScript | **Renderer:** Mobile 2D

---

## Table of Contents

1. [Vision & Concept](#1-vision--concept)
2. [Core Loop](#2-core-loop)
3. [Mechanics & Systems Detail](#3-mechanics--systems-detail)
4. [Internal Systems](#4-internal-systems)
5. [Player Flow & UX Design](#5-player-flow--ux-design)
6. [Scope & Time Budget](#6-scope--time-budget)
7. [MoSCoW Prioritization](#7-moscow-prioritization)
8. [Testable Requirements](#8-testable-requirements)

---

## 1. Vision & Concept

> **One-sentence pitch:** Naval Strike is a classic Battleship duel against a tactical AI opponent — pure grid strategy, zero-filler, delivering the satisfying "hit or miss" tension of the original game in a clean, fast digital format.

**Genre:** Turn-based strategy / Classic board game adaptation  
**Theme:** Battleship (jam theme compliance: direct)  
**Tone:** Military-tactical — clean grids, minimal UI, punchy audio feedback

### Player Fantasy

The player is a naval commander calling strikes on unknown enemy waters. Every shot is a deduction — reading the board, tracking hit patterns, hunting down ships to their last cell. Victory feels earned through methodical thinking, not luck.

### Core Experience Statement

The game must create **tension on every shot**. The single moment between firing and the hit/miss reveal is the heartbeat of the game. All design decisions serve this moment.

---

## 2. Core Loop

```
[PLACEMENT PHASE]
  Player places 5 ships on own grid
		↓
  GAME STARTS
		↓
[PLAYER TURN]
  Tap cell on enemy grid → fire
		↓
[REVEAL]
  HIT  → cell marks red, sunk feedback if applicable
  MISS → cell marks grey
		↓
[CHECK WIN] — All enemy ships sunk? → END SCREEN (Victory)
		↓
[AI TURN]
  AI fires on player grid → reveal
		↓
[CHECK LOSS] — All player ships sunk? → END SCREEN (Defeat)
		↓
  ← loop back to PLAYER TURN ←
		↓
[END SCREEN]
  Win / Lose result + Play Again
```

> **Loop integrity:** Every mechanic in this document maps back to one of three loop states: **Placement**, **Combat Turn**, or **End Resolution**. Any feature that doesn't serve these states is out of scope.

---

## 3. Mechanics & Systems Detail

### The Grid

Two 10×10 grids (columns A–J, rows 1–10).

- **Player Grid** (bottom half of screen): shows own ships and incoming enemy hits
- **Enemy Grid** (top half): shows only hit/miss markers — enemy ships hidden until sunk

### Ships

| Ship       | Size (cells) | Quantity | Sunk Feedback         |
|------------|:------------:|:--------:|-----------------------|
| Carrier    | 5            | 1        | "Carrier sunk!"       |
| Battleship | 4            | 1        | "Battleship sunk!"    |
| Cruiser    | 3            | 1        | "Cruiser sunk!"       |
| Submarine  | 3            | 1        | "Submarine sunk!"     |
| Destroyer  | 2            | 1        | "Destroyer sunk!"     |

### Placement Phase Rules

- Ships placed horizontally or vertically only — no diagonal
- Ships may not overlap each other
- Ships may not extend outside grid bounds
- Player taps a ship from the sidebar, then taps a cell to place it
- A "Rotate" button toggles orientation before placement
- Placed ships can be tapped again to re-pick and reposition
- "Random" button fills all remaining ships via random valid placement
- "Start Battle" button activates only when all 5 ships are placed

### Combat Rules

- Player and AI alternate single shots per turn
- A cell already fired at cannot be selected again (visually blocked)
- A HIT is any shot landing on an occupied cell of an opposing ship
- A ship is SUNK when all of its cells have been hit
- On sunk: all cells of that ship reveal their full outline on the enemy grid
- Game ends immediately when all ships of one side are sunk

### AI Behavior — Hunt/Target Mode

The AI uses a two-state machine to feel tactical without requiring look-ahead:

**HUNT mode:**
- Fires at cells using a checkerboard pattern to maximize coverage
- Skips cells that can't contain the smallest remaining enemy ship
- Selected from remaining valid cells at random within the pattern

**TARGET mode:**
- Entered immediately on a hit
- Fires at orthogonal neighbors of the hit cell
- On second hit, locks to that axis and continues in that direction
- Reverts to HUNT if the ship is sunk or all axis options are exhausted
- The AI never fires at a cell it already fired at

> **Difficulty note:** Hunt/Target is the single difficulty setting for the jam. It provides a fair, satisfying challenge without requiring difficulty sliders or time to balance multiple tiers.

---

## 4. Internal Systems

### BoardState (Data Layer)

`board_state.gd` — RefCounted. Two instances: one for the player, one for the AI. Tracks all cell states independently of visuals.

- Cell states: `EMPTY`, `SHIP`, `HIT`, `MISS`
- Ship registry: array of `ShipData` resources, each storing position, orientation, size, hit-count
- `fire(cell)` → returns `{ result: HIT/MISS, sunk_ship: ShipData|null }`
- `all_sunk()` → returns `true` when every ShipData hit-count equals its size

### GridDisplay (Visual Layer)

`grid_display.gd` — Node2D. Renders a single grid. Receives state updates via signals and redraws only changed cells. Contains no game logic.

### GameManager (AutoLoad)

`game_manager.gd` — Singleton. Owns the turn state machine.

- States: `PLACEMENT → PLAYER_TURN → AI_TURN → GAME_OVER`
- Emits: `turn_changed`, `shot_fired(result)`, `game_ended(winner)`
- Other scripts subscribe to signals — never query GameManager state directly from outside

### AIController

`ai_controller.gd` — Node. Exposes one method: `choose_cell() → Vector2i`. Internally manages hunt/target state. Called by GameManager on AI turn. Has no scene dependencies.

### Signal Map

| Signal                      | Emitter              | Listener(s)              |
|-----------------------------|----------------------|--------------------------|
| `ship_placed(ship_data)`    | PlacementController  | GameManager, GridDisplay |
| `cell_tapped(cell)`         | GridDisplay          | GameManager              |
| `shot_fired(cell, result)`  | GameManager          | GridDisplay, HUD         |
| `ship_sunk(ship_data, owner)` | GameManager        | GridDisplay, HUD         |
| `game_ended(winner)`        | GameManager          | HUD, Main scene          |
| `turn_changed(new_turn)`    | GameManager          | HUD, GridDisplay         |

---

## 5. Player Flow & UX Design

### Screen Map

```
MAIN MENU
	↓ "Play"
PLACEMENT SCREEN
	↓ "Start Battle"
BATTLE SCREEN
	↓ Win / Lose
RESULT SCREEN
	↓ "Play Again" → PLACEMENT SCREEN
	↓ "Menu"       → MAIN MENU
```

### Learning Curve

Naval Strike targets **zero onboarding text**. The player learns entirely through affordance and immediate feedback:

- Ships in the sidebar are visually tappable — no tutorial needed
- Invalid placements ghost red; valid placements confirm green
- "Start Battle" is greyed out until placement is complete — no explanation needed
- First shot fires immediately — no modal interruption

### Feedback Hierarchy

| Event       | Visual                         | Audio           | HUD Text          |
|-------------|--------------------------------|-----------------|-------------------|
| Miss        | Grey X marker                  | Splash SFX      | —                 |
| Hit         | Red marker + cell flash        | Explosion SFX   | "HIT!"            |
| Ship Sunk   | Full ship outline revealed     | Explosion + siren | "[Ship] SUNK!"  |
| Player Win  | Screen flash white             | Victory fanfare | "VICTORY"         |
| Player Lose | Screen flash red               | Defeat sting    | "DEFEAT"          |
| AI Turn     | Enemy grid dims briefly        | —               | "ENEMY FIRING…"   |

### AI Turn Pacing

After the player fires, a **0.8-second delay** is inserted before the AI shot resolves. This prevents the game feeling reactive and gives the player time to process their own shot result.

### Emotional Arc

| Phase        | Experience                                                                 |
|--------------|----------------------------------------------------------------------------|
| Placement    | Calm, strategic — full control, building a hidden fortress                 |
| Early combat | Curious tension — each shot probes unknown waters                          |
| Mid-game     | Mounting pressure — both sides have information, tight deduction           |
| Endgame      | Anxiety or triumph — one ship left each side, every cell matters           |
| Resolution   | Sharp emotional release — clear win/lose with strong audio, instant rematch|

---

## 6. Scope & Time Budget

| Metric       | Value        |
|--------------|--------------|
| Total time   | 5 hours      |
| Developer    | 1 (solo)     |
| Screens      | 3            |
| Scripts      | 8            |

### Time Allocation Plan

| Block         | Time          | Focus                                                                           |
|---------------|---------------|---------------------------------------------------------------------------------|
| Setup         | 0:00 – 0:30   | Project, folder structure, stub scenes/scripts, AutoLoad registration           |
| Data + Grid   | 0:30 – 1:30   | BoardState logic, GridDisplay rendering, cell click detection                   |
| Placement     | 1:30 – 2:30   | Ship sidebar, tap-to-place, rotation, validation, random placement, Start button |
| Combat        | 2:30 – 3:30   | GameManager turn machine, player fire flow, AI hunt/target, win/loss detection  |
| UI + Screens  | 3:30 – 4:15   | HUD labels, hit/miss markers, result screen, main menu, Play Again              |
| Polish        | 4:15 – 4:45   | SFX, AI delay, sunk reveal, screen flash                                        |
| Export        | 4:45 – 5:00   | Windows build, smoke test full loop x2, critical bug fixes only                 |

### Risk Register

| Risk                              | Mitigation                                                                  |
|-----------------------------------|-----------------------------------------------------------------------------|
| AI hunt/target bugs eat time      | Implement pure random AI first; upgrade only after core loop is confirmed   |
| Placement drag-and-drop overruns  | Use tap-to-select + tap-to-place (not drag) — simpler on a grid             |
| Audio assets not ready            | AudioStreamPlayer nodes present but empty; game fully playable without sound |

---

## 7. MoSCoW Prioritization

### Must Have
- 10×10 grid rendering (both grids)
- 5-ship placement with rotation
- Placement validation (bounds + overlap)
- Player fire on enemy grid (tap)
- Hit / Miss / Sunk state tracking
- AI opponent (minimum: random)
- Win / Loss detection and result screen
- Play Again button
- Visual hit/miss markers on grids
- Previously-fired cells blocked from re-fire

### Should Have
- Hunt/Target AI (tactical feel)
- Sunk ship outline reveal on enemy grid
- HUD: turn indicator + shot feedback text
- SFX: hit, miss, sunk, win, lose
- AI turn delay (0.8s pacing)
- Random placement button
- Main menu screen

### Could Have
- Cell coordinate labels (A–J, 1–10)
- Shot count tracker in HUD
- Screen flash on win/lose
- Remaining ship silhouettes in HUD
- BGM loop

### Won't Have (this jam)
- Multiplayer (local or online)
- Multiple difficulty levels
- Animated ship sprites
- Campaign / progression
- Save / load game state
- Settings screen

---

## 8. Testable Requirements

All requirements below are pass/fail verifiable with no design interpretation needed.

### REQ-PLACE — Placement Phase

| ID    | Requirement                                                                                                         |
|-------|---------------------------------------------------------------------------------------------------------------------|
| PL-01 | When the game starts, the placement screen is shown before the battle screen.                                       |
| PL-02 | All five ships (Carrier 5, Battleship 4, Cruiser 3, Submarine 3, Destroyer 2) appear in the placement sidebar.     |
| PL-03 | Tapping a ship then tapping a valid cell places that ship at that cell in the current orientation.                  |
| PL-04 | Tapping Rotate before placing changes orientation from horizontal to vertical and back.                             |
| PL-05 | Placing a ship that would extend outside grid boundaries does not place the ship.                                   |
| PL-06 | Placing a ship overlapping an already-placed ship does not place the ship.                                          |
| PL-07 | Tapping an already-placed ship picks it back up and allows repositioning.                                           |
| PL-08 | Tapping Random fills all unplaced ships in valid, non-overlapping positions within the grid.                        |
| PL-09 | Start Battle is non-interactive (greyed out) when fewer than 5 ships are placed.                                   |
| PL-10 | Tapping Start Battle with all 5 ships placed transitions to the battle screen.                                      |

### REQ-COMBAT — Combat Phase

| ID    | Requirement                                                                                                         |
|-------|---------------------------------------------------------------------------------------------------------------------|
| CB-01 | On the player's turn, tapping an unfired cell on the enemy grid fires a shot at that cell.                         |
| CB-02 | A shot at an empty enemy cell places a grey miss marker on that cell.                                               |
| CB-03 | A shot at a cell occupied by an enemy ship places a red hit marker on that cell.                                    |
| CB-04 | A cell with a hit or miss marker cannot be targeted again in the same game.                                         |
| CB-05 | When all cells of an enemy ship have been hit, the game displays a sunk notification naming that ship.              |
| CB-06 | When a ship is sunk, its full shape becomes visible on the enemy grid.                                              |
| CB-07 | After the player fires, at least 0.5 seconds pass before the AI fires.                                             |
| CB-08 | The AI never fires at a cell it has previously fired at.                                                            |
| CB-09 | After an AI hit, the AI fires at an orthogonal neighbor of the hit cell on its next eligible turn.                  |
| CB-10 | AI and Player shots strictly alternate — no double turns.                                                           |

### REQ-END — Win / Loss / Restart

| ID    | Requirement                                                                                                         |
|-------|---------------------------------------------------------------------------------------------------------------------|
| EN-01 | When all 5 enemy ships are sunk, the game ends and shows a win result screen.                                       |
| EN-02 | When all 5 player ships are sunk, the game ends and shows a loss result screen.                                     |
| EN-03 | No further shots can be fired after the game ends.                                                                  |
| EN-04 | Tapping Play Again returns to the placement screen with fully reset game state (no ships placed, no shots recorded).|
| EN-05 | The result screen clearly displays either "VICTORY" or "DEFEAT" in text.                                           |

### REQ-AI — AI Correctness

| ID    | Requirement                                                                                                         |
|-------|---------------------------------------------------------------------------------------------------------------------|
| AI-01 | In 100 simulated AI-only games, the AI sinks all player ships in every game (no stuck states).                      |
| AI-02 | The AI never fires at a cell outside the 10×10 grid.                                                                |
| AI-03 | In HUNT mode, the AI uses a checkerboard skip pattern (never fires two adjacent misses with no active hit).         |
| AI-04 | After sinking a ship, the AI returns to HUNT mode and does not continue along the sunk ship's axis.                 |

### REQ-UX — Interface & Feedback

| ID    | Requirement                                                                                                         |
|-------|---------------------------------------------------------------------------------------------------------------------|
| UX-01 | A HUD element clearly shows whose turn it is (PLAYER TURN / ENEMY FIRING) at all times during combat.              |
| UX-02 | The player's own grid is not tappable as a target during combat.                                                    |
| UX-03 | The enemy grid is not tappable during the AI turn.                                                                  |
| UX-04 | A hit shot produces a visually distinct response from a miss shot within 0.3 seconds of the tap.                   |
| UX-05 | The game runs without crashes through a complete game on the target Windows PC.                                     |

---

> **Testing protocol:** All REQ-PLACE and REQ-COMBAT requirements can be verified by a single tester playing two complete games (one win, one loss). REQ-AI correctness tests require a headless simulation loop or extended manual play session.
