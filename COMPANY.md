# Battleship Campaign — *Kolobok*

## Overview

This document describes a narrative-driven campaign mode for a classic Battleship game inspired by the Kolobok folktale. Each level introduces a new opponent with distinct AI behavior, dialogue, and mechanics. The campaign blends simple gameplay evolution with light storytelling.

---

## Core Concept

You are a naval commander tracking a rogue experimental vessel called **Kolobok**.
Each opponent you face represents a different attempt to capture or destroy it — and each teaches you a new tactical layer.

---

## Campaign Structure

### Level 1 — Grandparents (Tutorial)

**Role:** Creators of Kolobok
**Theme:** Learning basics

**AI Logic:**

* Random shooting
* No memory of previous hits
* Low accuracy bias

**Mechanics:**

* Small grid (e.g., 6x6)
* Fewer ships
* Highlight valid moves

**Dialogue:**

* “We built him… but he slipped away.”
* “Careful now, commander. Learn the waters first.”

---

### Level 2 — Hare

**Theme:** Speed vs precision

**AI Logic:**

* Random shots with high frequency
* Slight bias toward unexplored cells
* No targeting logic

**Special Mechanic:**

* Time-limited turns

**Dialogue:**

* “Too slow! Too slow!”
* “I’ll find him first!”

---

### Level 3 — Wolf

**Theme:** Hunting behavior

**AI Logic:**

* Hunt/target system:

  * Random search phase
  * On hit → prioritize adjacent cells
* Remembers hit clusters

**Pseudo-logic:**

```
if hit:
    push neighbors to priority queue
else:
    random unexplored cell
```

**Dialogue:**

* “Once I see blood… I don’t stop.”
* “You’ve been found.”

---

### Level 4 — Bear

**Theme:** Power vs efficiency

**AI Logic:**

* Slow turn rate
* Uses area attacks (3x3 or cross pattern)
* Prefers center of grid

**Special Mechanic:**

* AoE strike with cooldown

**Dialogue:**

* “No need to aim… I crush everything.”
* “The sea trembles.”

---

### Level 5 — Kolobok (First Encounter)

**Theme:** Evasion and trickery

**AI Logic:**

* Standard hunt/target + one special ability:

  * **Reposition** one ship after being hit

**Special Mechanic:**

* One-time ship relocation

**Dialogue:**

* “I sailed from them, I’ll sail from you!”
* “Catch me if you can~”

**Outcome:**

* Escapes after defeat

---

### Level 6 — Fox (Boss)

**Theme:** Deception

**AI Logic:**

* Probabilistic targeting
* Introduces **fake signals**
* Occasionally ignores obvious optimal moves

**Special Mechanics:**

* Decoy hits (false positives)
* Hidden ship masking (temporary)

**Pseudo-logic:**

```
if random() < deception_rate:
    fire misleading shot
else:
    best probability cell
```

**Dialogue:**

* “You’re clever… but not clever enough.”
* “Come closer, commander… just a little closer.”

---

## Final Level — True Kolobok

**Theme:** Adaptation

**AI Logic:**
Combines all previous strategies:

* Random exploration (Hare)
* Target locking (Wolf)
* Area pressure (Bear)
* Deception (Fox)

**Advanced Behavior:**

* Tracks player patterns
* Avoids previously targeted zones
* Adjusts ship placement dynamically

**Pseudo-logic:**

```
strategy = weighted_mix(hare, wolf, bear, fox)

update_weights(player_behavior)

choose_action(strategy)
```

**Dialogue:**

* “You’ve learned from them… now learn from me.”
* “I am not running. I am choosing.”

---

## Endings

### Capture Ending

* Kolobok is defeated
* Dialogue: “You’ve grown… enough to stop me.”

### Escape Ending

* Kolobok disappears again
* Unlocks endless mode

---

## Optional Enhancements

### Dynamic Dialogue System

* Trigger lines on:

  * hit
  * miss
  * ship destroyed
  * near victory

### Progression

* Unlock abilities:

  * sonar (reveal area)
  * double shot
  * shield

### Visual Identity

* Each enemy has:

  * unique color palette
  * sound cues
  * UI theme

---

## Summary

This campaign transforms Battleship into a progression-based experience:

* Each level teaches a mechanic
* Each enemy introduces a new AI behavior
* Final boss tests full player understanding

The structure is simple to implement incrementally while still feeling like a cohesive story.
