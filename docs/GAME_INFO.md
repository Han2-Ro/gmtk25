# Game Design Document

## Game Overview

This is a **Simon-style memory game** built in Godot where players must repeat increasingly complex sequences of button presses. The game combines classic memory gameplay with a progression system featuring purchasable upgrades.

## Core Gameplay Loop

1. **Sequence Display**: The game shows a sequence of button flashes on a grid
2. **Player Input**: Players must repeat the sequence by clicking buttons in the correct order
3. **Progressive Difficulty**: Each round adds one more button to the sequence (starting with 1 button, up to 5+ buttons)
4. **Subsequence Building**: Players practice each new sequence by first completing shorter versions (1 button, then 1-2 buttons, then 1-2-3 buttons, etc.)

## Economy System

Players earn coins through gameplay:

- **1 coin per step** completed correctly
- **1 coin bonus** for completing each subsequence
- **Sequence length bonus** for completing full sequences

## Shop & Upgrade System

Persistent upgrades that carry between game sessions:
_(NONE YET)_

## Technical Architecture

### Key Components:

- **SequenceController**: Manages game flow, sequence generation, and input validation
- **ShopManager**: Handles upgrade purchases, persistent state, and upgrade effects
- **CashManager**: Tracks player coins and reward distribution
- **SequenceButton**: Individual button components with flash animations
- **UI Components**: Shop interface, life counter, cash display

### Integration Points:

- Shop upgrades integrate seamlessly with gameplay (coin multiplier affects CashManager, slow motion affects SequenceController timing)
- Persistent save system for shop purchases
- Signal-based communication between components

## Game Design:

- **Clear progression**: Coins → Upgrades → Better performance → More coins
- **Balanced difficulty curve**: Gradual sequence length increase with practice rounds
- **Meaningful choices**: Different upgrade types serve different player needs
- **Immediate feedback**: Visual and audio cues for success/failure
- **Replayability**: Persistent upgrades encourage multiple sessions
