# GMTK 2025 - Prototype Design Summary

## 1. Concept:

A rogue-lite game where the player navigates a world
and overcomes challenges by completing cumulative memory patterns on a grid of tiles.

## 2. Core Gameplay Loop (The "Level"):

**Observe**: reveal a sequence of tiles, one step at a time (e.g., A, A→C, A→C→B, … )
**Act**: move character along the sequence
**Success**: correct replication, earn gold, then next step in sequence, until level is complete.
**Failure**: mistakes cost one Life. The player may then try another tile/option.

## 3. Run Structure & Meta-Loop:

Infinite levels, procedurally generated
After clearing a level, get upgrades for rest of the run
Run ends when all lives (3 at start) are lost

## 4. Intended Player Experience ("Why it's fun"):

Feeling Smart: successfully recalling a difficult sequence.
Feeling Powerful: upgrade system (e.g., "Remove 1 incorrect tile," "extra Life").
Tension: The risk of failure and losing a life when attempting a long, complex pattern.

## 5. Biggest Challenges

## 6. Future Additions

- Boss battles
- Special tiles/fields (life restoration, item upgrades).
- Splits in the path, the player must choose.

## 7. Resources

- I Packed my Bag (Game)
- Arktos Superspiel
- [Simon](https://en.wikipedia.org/wiki/Simon_%28game%29)
