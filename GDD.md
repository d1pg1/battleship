# Battleship - Game Design Document

## 1. Project Overview

**Project name:** Battleship  
**Genre:** Turn-based strategy / board game adaptation  
**Engine:** Godot 4.6  
**Language:** GDScript  
**Target platform:** PC / Windows, with Godot-compatible desktop support  
**Primary input:** Mouse  
**Main scene:** `res://scenes/main_menu.tscn`  
**Viewport:** 1280x720  

Battleship is a digital naval strategy game based on the classic Battleship ruleset. The player places a hidden fleet on a 10x10 grid, fires at an opponent's hidden grid, and wins by sinking every enemy ship. The project expands the base game with AI difficulty levels, local pass-and-play PvP, AI simulation, and a narrative Kolobok campaign with unique opponent abilities.

The intended player experience is fast, readable, and tactical. Every shot should clearly communicate hit, miss, sunk ship, turn change, and match outcome.

## 2. Core Gameplay Loop

1. Player selects a mode from the main menu.
2. Player places ships on their own board.
3. Opponent fleet is placed manually, by another player, or automatically.
4. Active player fires at the opponent grid.
5. Shot resolves as hit or miss.
6. Hit keeps the turn.
7. Miss passes the turn.
8. Sunk ships reveal surrounding water as misses.
9. Game ends when one side's full fleet is sunk.
10. Result screen offers replay, next campaign level, retry, or menu navigation.

## 3. Game Modes

### 3.1 VS AI

The player fights a computer-controlled opponent.

Functionality:

- Difficulty menu before placement.
- Difficulties: Easy, Medium, Hard, Impossible.
- Player manually places fleet or uses random placement.
- AI fleet is randomly placed and hidden.
- Player fires by clicking the enemy grid.
- AI fires after a short delay when it receives a turn.
- Result screen shows Victory or Defeat.

AI behavior by difficulty:

- **Easy:** Random unfired cells.
- **Medium:** Random/hunt behavior with basic targeting after hits.
- **Hard:** Checkerboard hunt mode, target mode after hits, axis locking after multiple hits.
- **Impossible:** Reads remaining ship cells and selects a valid hidden ship cell when possible.

### 3.2 Local PvP

Two players play on one machine using pass-and-play.

Functionality:

- Player 1 places a fleet.
- Player 2 places a fleet.
- Handoff overlay hides both boards between turns.
- Active player clicks the opponent grid to fire.
- Hits keep the current player's turn.
- Misses trigger a result pause, then handoff to the other player.
- Result screen announces Player 1 Wins or Player 2 Wins.

### 3.3 AI vs AI

The game runs a watchable AI simulation.

Functionality:

- Both fleets are randomly placed.
- Both boards are visible.
- Two AI controllers take turns firing.
- Hits keep the active AI's turn.
- Misses swap active AI control.
- Result screen announces AI 1 Wins or AI 2 Wins.

### 3.4 Campaign

The campaign is a Kolobok-inspired sequence of battles. The player names their commander, views dialogue, places a fleet, and fights themed opponents.

General campaign functionality:

- Commander name prompt at campaign start.
- In-session campaign continuation from the main menu.
- Campaign progress is not saved to disk.
- Dialogue overlay before placement.
- Opponent portraits from `assets/Naval Battle Assets/Characters/`.
- Tutorial copy during Level 1 placement.
- Result screen supports Next Level, Retry Level, or Replay Campaign.

Campaign levels:

| Level | Opponent | Theme | AI / Ability |
| --- | --- | --- | --- |
| 1 | Grandparents | Tutorial waters | Random AI, slower pacing |
| 2 | Hare | Speed vs precision | Random AI plus timed player turns |
| 3 | Wolf | Hunting behavior | Hunt/target AI |
| 4 | Bear | Power vs efficiency | Hunt/target AI plus cross-shaped area strike |
| 5 | Kolobok | First encounter | Hunt/target AI plus hidden ship relocation |
| 6 | Fox | Deception | Hunt/target AI plus false signal messages |
| 7 | True Kolobok | Adaptation | Timed turns, area strikes, relocation, and false signals |

Campaign abilities:

- **Timed turns:** Player has 10 seconds to fire. If time expires, the turn passes to the opponent.
- **Area strike:** Opponent fires at a cross pattern: center, left, right, up, and down. Used on cooldown.
- **Relocation:** After the player hits but does not sink a ship, the opponent may relocate one unhit hidden ship once.
- **False signal:** Some player misses may display suspicious feedback while still recording the real miss.

## 4. Board and Fleet Rules

### 4.1 Board

- Board size is 10x10.
- Cell states are Empty, Ship, Hit, and Miss.
- Each side owns one board.
- Enemy ships are hidden during normal player combat.
- Own ships are visible on the player's board.
- In AI vs AI, both fleets are visible.

### 4.2 Fleet

The game uses a 10-ship fleet based on Russian Battleship rules:

| Ship class | Size | Count |
| --- | ---: | ---: |
| Battleship | 4 | 1 |
| Cruiser | 3 | 2 |
| Destroyer | 2 | 3 |
| Patrol | 1 | 4 |

### 4.3 Placement Rules

- Ships can be horizontal or vertical.
- Ships cannot be diagonal.
- Ships cannot overlap.
- Ships cannot extend outside the board.
- Ships cannot touch any other ship, including diagonally.
- The Start Battle button is disabled until every ship is placed.
- Random placement must obey all placement rules.
- Pressing `R` or the Rotate button changes orientation.
- Clicking an already placed ship button removes and reselects that ship for repositioning.

## 5. Combat Rules

- A shot at a ship cell becomes a Hit.
- A shot at an empty cell becomes a Miss.
- A player cannot meaningfully reuse already fired cells because Hit and Miss cells are already recorded on the board.
- A ship sinks when all of its cells have been hit.
- When a ship sinks, all surrounding empty cells are automatically marked as Miss.
- A hit keeps the current shooter's turn.
- A miss passes the turn to the opponent.
- The game ends immediately when all ships on one board are sunk.

## 6. Screens and Flow

### 6.1 Main Menu

Functionality:

- VS AI button opens difficulty selection.
- Campaign button starts or continues campaign flow.
- Local PvP button starts pass-and-play placement.
- AI vs AI button starts simulation.
- Quit button exits the game.

### 6.2 Difficulty Menu

Functionality:

- Easy, Medium, Hard, and Impossible buttons start VS AI with selected difficulty.
- Back button returns to main menu.

### 6.3 Placement Screen

Functionality:

- Shows player grid and ship list.
- Allows selecting ships from sidebar.
- Allows rotation.
- Allows random fleet placement.
- Shows campaign dialogue overlay when in campaign mode.
- Supports Player 1 and Player 2 placement in local PvP.
- Enables Start Battle only when all ships are placed.

### 6.4 Battle Screen

Functionality:

- Shows enemy grid and player grid.
- Enemy grid receives firing input in player-controlled modes.
- HUD displays current turn, shot feedback, sunk messages, campaign events, and elapsed time.
- Menu button returns to main menu.
- Local PvP uses handoff overlay to hide boards between players.
- Game over automatically transitions to result screen.

### 6.5 Result Screen

Functionality:

- Shows Victory or Defeat in VS AI and Campaign.
- Shows Player 1/Player 2 winner in Local PvP.
- Shows AI 1/AI 2 winner in AI vs AI.
- Campaign victory advances to the next level unless the final level is complete.
- Campaign defeat retries the current level.
- Menu button returns to main menu.

## 7. Feedback and Presentation

### 7.1 Visual Feedback

- Ship placement buttons fade when their ship is placed.
- Invalid placement is rejected.
- Hit and miss states are drawn on the grid.
- Sunk ships trigger HUD text.
- Campaign events appear in HUD text.
- PvP handoff overlay prevents the next player from seeing the previous player's board.

### 7.2 Audio Feedback

Audio files are included for:

- Hit
- Miss
- Ship destruction
- Victory
- Defeat

### 7.3 Theme and Assets

The game uses naval board, ship, radar, token, background, and character assets. The naval asset pack is credited to Molly "Cougarmint" Willits and is licensed under CC-BY 3.0 according to the included asset readme:

`assets/Naval Battle Assets/NavalBattle - ReadMe.txt`

## 8. Technical Architecture

### 8.1 GameManager

File: `autoload/game_manager.gd`

Responsibilities:

- Global state machine.
- Current game mode.
- AI difficulty.
- Campaign level data.
- Player and opponent board ownership.
- Turn transitions.
- Timers for AI delay, PvP handoff, and timed campaign turns.
- Game over detection.
- Signals for shot fired, ship sunk, turn changed, campaign event, and game ended.

### 8.2 BoardState

File: `scripts/board_state.gd`

Responsibilities:

- Stores 10x10 cell grid.
- Validates placement.
- Places and removes ships.
- Resolves firing.
- Tracks sunk ships.
- Reveals surrounding cells after a ship sinks.
- Randomly places fleets.
- Relocates hidden ships for campaign ability.

### 8.3 ShipData

File: `resources/ship_data.gd`

Responsibilities:

- Stores ship name, size, origin, orientation, hit count, and placed state.
- Provides occupied cells.
- Reports whether ship is sunk.
- Resets ship state.

### 8.4 AIController

File: `scripts/ai_controller.gd`

Responsibilities:

- Chooses target cells.
- Supports random, hare, and wolf profiles.
- Supports Easy, Medium, Hard, and Impossible difficulties.
- Tracks fired cells.
- Maintains hunt/target state.
- Queues orthogonal target cells after hits.
- Locks targeting axis on harder behavior.

### 8.5 UI Scripts

Key files:

- `scripts/main_menu.gd`
- `scripts/difficulty_menu.gd`
- `scripts/placement_controller.gd`
- `scripts/battle_screen.gd`
- `scripts/grid_display.gd`
- `scripts/hud.gd`
- `scripts/result_screen.gd`

Responsibilities:

- Scene navigation.
- Placement UI.
- Grid input and rendering.
- HUD messaging.
- Result display.
- Campaign dialogue presentation.

## 9. QA Checklist

QA can use this section as a functional grading checklist.

### Main Menu

- Main menu loads on project start.
- VS AI opens difficulty menu.
- Campaign opens name prompt or continue prompt.
- Local PvP starts placement.
- AI vs AI starts simulation.
- Quit exits the application.

### VS AI

- Each difficulty starts a playable match.
- Player can manually place every ship.
- Random placement fills the full fleet legally.
- Start Battle is disabled until all 10 ships are placed.
- Enemy ships are hidden.
- Player can fire at enemy grid.
- AI fires after player misses.
- Hit lets shooter continue.
- Miss passes turn.
- Victory appears when enemy fleet is fully sunk.
- Defeat appears when player fleet is fully sunk.

### Local PvP

- Player 1 places fleet.
- Next Player starts Player 2 placement.
- Both players can place full fleets.
- Handoff overlay hides boards.
- Ready button reveals the active player's perspective.
- Player 1 and Player 2 turns swap after misses.
- Hits keep turn.
- Result screen announces correct player winner.

### AI vs AI

- Both fleets are randomly placed.
- Both boards are visible.
- AI 1 and AI 2 alternate turns after misses.
- Hits keep active AI firing.
- Simulation ends with correct AI winner.

### Campaign

- Campaign accepts commander name.
- Empty commander name falls back to Commander.
- Campaign dialogue appears before placement.
- Level 1 tutorial text appears.
- Grandparents use random/slower behavior.
- Hare timed turns pass control after timeout.
- Wolf uses hunt/target behavior.
- Bear area strike affects up to five cross-pattern cells.
- Kolobok can relocate one unhit hidden ship after a hit.
- Fox false signal can appear on a miss without changing board truth.
- True Kolobok combines previous special abilities.
- Victory advances campaign level.
- Defeat retries current campaign level.
- Final campaign victory completes campaign and offers replay.
- Campaign continuation works during the same app session.

### Board Rules

- Ships cannot overlap.
- Ships cannot touch horizontally, vertically, or diagonally.
- Ships cannot leave board bounds.
- Rotation changes placement orientation.
- Sunk ships reveal surrounding empty cells as misses.
- The game ends only after every ship on one side is sunk.

### Presentation

- HUD shows turn state.
- HUD shows Hit and Miss feedback.
- HUD shows sunk ship messages.
- HUD shows campaign events.
- Result screen text matches the mode and winner.
- Audio feedback plays for key events where configured.

## 10. Known Scope Notes

- Campaign progress is intentionally session-only and is not saved to disk.
- The Windows `.exe` release build is intended for easier testing without requiring Godot.
- The project is optimized for a 1280x720 desktop viewport.
