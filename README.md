# Battleship

A Godot 4 naval strategy game inspired by classic Battleship. Place your fleet, read the grid, and sink the enemy one shot at a time.

The project includes several playable modes: standard player-versus-AI battles, local pass-and-play PvP, AI-versus-AI simulation, and a narrative Kolobok campaign with opponent-specific abilities.

## Features

- Classic 10x10 Battleship-style combat.
- Russian Battleship fleet rules: 1 battleship, 2 cruisers, 3 destroyers, and 4 patrol boats.
- Ships cannot overlap or touch, including diagonally.
- Hits keep the current turn; misses pass control to the opponent.
- Sunk ships automatically reveal surrounding empty water as misses.
- VS AI mode with selectable difficulty.
- Local PvP pass-and-play mode.
- AI vs AI watch mode.
- Kolobok campaign with dialogue, commander naming, themed opponents, and special abilities.
- Audio feedback for hits, misses, victory, and defeat.

## Play Modes

### VS AI

Choose a difficulty, place your fleet, then battle the computer. The AI uses increasingly tactical behavior depending on the selected difficulty.

### Local PvP

Two players share one device. Player 1 places a fleet, Player 2 places a fleet, then the game uses handoff overlays when turn control changes.

### AI vs AI

Both fleets are placed automatically and the battle plays out as a simulation.

### Campaign

Fight through a Kolobok-inspired campaign:

1. Grandparents - tutorial waters.
2. Hare - timed player turns.
3. Wolf - hunt/target behavior.
4. Bear - cross-shaped area strikes.
5. Kolobok - ship relocation.
6. Fox - false signals.
7. True Kolobok - combined abilities.

Campaign progress is kept in memory for the current app session only.

## Requirements

- Godot 4.6 or newer.
- Windows, Linux, or macOS with Godot 4 support.

If you only want to playtest the game, download the prebuilt Windows `.exe` from the GitHub release instead of opening the project in Godot.

The project is configured for:

- Main scene: `res://scenes/main_menu.tscn`
- Viewport: `1280x720`
- Renderer: Mobile
- Language: GDScript

## Download a Build

Prebuilt Windows releases include a `.exe` so testers can run the game without installing Godot.

1. Open the repository's **Releases** page on GitHub.
2. Download the latest Windows build.
3. Extract the archive if needed.
4. Run the included `.exe`.

## Running the Game

1. Open Godot.
2. Click **Import**.
3. Select this folder's `project.godot`.
4. Open the project.
5. Press **F5** or click **Run Project**.

From the command line, if the Godot executable is available on your `PATH`:

```sh
godot --path .
```

## Project Structure

```text
res://
├── autoload/
│   └── game_manager.gd
├── resources/
│   └── ship_data.gd
├── scenes/
│   ├── main_menu.tscn
│   ├── difficulty_menu.tscn
│   ├── placement_screen.tscn
│   ├── battle_screen.tscn
│   ├── result_screen.tscn
│   └── audio_manager.tscn
├── scripts/
│   ├── ai_controller.gd
│   ├── battle_screen.gd
│   ├── board_state.gd
│   ├── grid_display.gd
│   ├── hud.gd
│   ├── main_menu.gd
│   ├── placement_controller.gd
│   └── result_screen.gd
├── assets/
├── audio/
├── GDD.md
├── DESIGN.md
├── PROJECT_STATE.md
└── project.godot
```

## Core Scripts

- `autoload/game_manager.gd` owns game state, turns, scene-level flow, campaign data, and emitted gameplay signals.
- `scripts/board_state.gd` stores one board's cells, ships, placement validation, firing results, and sunk-ship reveal behavior.
- `scripts/ai_controller.gd` chooses AI shots and handles hunt/target logic.
- `scripts/placement_controller.gd` manages manual and random fleet placement.
- `scripts/grid_display.gd` renders board state and forwards grid input.
- `resources/ship_data.gd` defines ship size, position, orientation, hit count, and sunk state.

## Rules Summary

- Ships are placed horizontally or vertically.
- Ships cannot overlap.
- Ships cannot touch each other, even diagonally.
- Firing at a ship cell is a hit.
- Firing at empty water is a miss.
- A hit grants another shot.
- A miss passes the turn.
- A ship sinks when every cell in that ship has been hit.
- The first side to sink the entire enemy fleet wins.