# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Simon-style memory game built in Godot 4.4. Players must repeat increasingly complex sequences of button presses on a 3D grid, earning coins to purchase upgrades between runs.

More details in:

- [DESIGN_DRAFT](docs/DESIGN_DRAFT.md)
- [GAME_INFO](docs/GAME_INFO.md)

## Development Commands

Since this is a Godot project, development is primarily done through the Godot editor:

- Check your code with `godot {scene} --check-only --quit`
- Format all `.gd` files with `uvx --from gdtoolkit gdformat {file}`
- Lint all `.gd` files with `uvx --from gdtoolkit gdlint {file}`

## Architecture Overview

### Core Game Flow

The game follows a sequence pattern where players observe and repeat button sequences:

1. **SequenceController** generates and displays sequences on a grid of SequenceButtons
2. **LevelController** manages game state, lives, and win/lose conditions
3. **Player** (3D pawn) moves between tiles when correct buttons are pressed

### Key Components

**SequenceController** (`show_sequence/sequence_controller.gd`):

- Generates random sequences from grid buttons
- Manages the observe→repeat gameplay loop
- Progressive difficulty: shows subsequences (1, then 1-2, then 1-2-3, etc.)
- Emits signals for game events (correct/wrong presses, sequence completion)

**SequenceButton** (`tile/tile.gd`):

- Individual 3D tile that can be clicked
- Handles flash animations for sequence display
- Manages pressed states and visual feedback (correct/wrong animations)
- Uses Area3D for mouse detection in 3D space

**LevelController** (`show_sequence/level_controller.gd`):

- Coordinates between UI and game logic
- Tracks lives and handles game over/win states
- Manages scene reloading for restart functionality

**Grid** (`show_sequence/grid.gd`):

- Data structure for managing button layout
- Supports different grid configurations

### Signal Architecture

The game uses Godot's signal system extensively for component communication:

- `sequence_flash_start/end` - UI disable during sequence display
- `pressed_correct/wrong` - Input validation feedback
- `step_completed` - Progress tracking within sequences
- `subsequence_completed` - Round completion events
- `sequence_completed` - Full sequence success

## Code Conventions

- GDScript files use `.gd` extension
- Scene files use `.tscn` extension
- Classes use `class_name` for global accessibility
- Signals declared at top of class
- Export variables for inspector configuration
- Node paths use `@onready` for scene references
- Consistent use of typed arrays (e.g., `Array[SequenceButton]`)

## Important Notes

- 3D assets are Blender files (`.blend`) with import settings
- UI is overlay-based for game state screens
