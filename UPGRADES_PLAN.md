# Upgrade Implementation Plan

## Overview
Implementation plan for roguelike upgrade selection system with 5 placeholder upgrades. Focus on loose coupling - upgrades should not require modifications to controllers.

## Implementation Strategy
- **Phase 1**: Upgrades that work without controller changes
- **Phase 2**: Design minimal controller changes for life management
- **Phase 3**: Upgrades that need controller changes
- **Phase 4**: Testing and validation

## Upgrade Details

### ✅ 1. Coin Multiplier (COMPLETED)
**Status**: ✅ Implemented and tested
**Approach**: Signal-based interception using enhanced `cash_changed` signal
**Implementation**:
- [x] Create `coin_multiplier_upgrade.gd` extending BaseUpgrade
- [x] Connect to `cash_changed(new_total, amount_added)` signal
- [x] Calculate bonus: `(multiplier - 1.0) * amount_added`
- [x] Add bonus cash with disconnect/reconnect to avoid loops
- [x] Proper cleanup on game over
- [x] Update resource file to use custom script

**Files Changed**:
- `upgrades/coin_multiplier/coin_multiplier_upgrade.gd` (new)
- `upgrades/coin_multiplier/coin_multiplier.tres` (updated script reference)
- `show_sequence/cash_manager.gd` (enhanced signal)
- `show_sequence/level_controller.gd` (updated signal handler)

### ✅ 2. Slow Motion (COMPLETED)
**Status**: ✅ Implemented and tested
**Approach**: Use Godot's `Engine.time_scale` global setting during sequence flashing only
**Implementation**:
- [x] Create `slow_motion_upgrade.gd` extending BaseUpgrade
- [x] Add flash lifecycle hooks to BaseUpgrade (`_on_sequence_flash_start/end()`)
- [x] Update UpgradeManager to broadcast flash events to all upgrades
- [x] Override `_on_sequence_flash_start()` to set `Engine.time_scale = 0.5^stack_count`
- [x] Override `_on_sequence_flash_end()` to restore `Engine.time_scale = 1.0`
- [x] Handle stacking with exponential slow-down (0.5x, 0.25x)
- [x] Prevent time scale corruption with is_active flag
- [x] Update resource file to use custom script

**Files Changed**:
- `upgrades/base_upgrade.gd` (added flash lifecycle hooks)
- `upgrades/upgrade_manager.gd` (broadcast flash events)
- `upgrades/slow_motion/slow_motion_upgrade.gd` (new)
- `upgrades/slow_motion/slow_motion.tres` (updated script reference)

### ✅ 3. Memory Helper (COMPLETED)
**Status**: ✅ Implemented and tested
**Approach**: Use existing `flash()` function on correct button via UpgradeManager tracking
**Implementation**:
- [x] Create `memory_helper_upgrade.gd` extending BaseUpgrade
- [x] Override `_on_step_completed()` to get current correct button
- [x] Use UpgradeManager's `get_current_correct_button()` method
- [x] Call `button.flash()` briefly as a hint using call_deferred
- [x] Add upgrade_manager reference assignment in UpgradeManager
- [x] Update resource file to use custom script

**Files Changed**:
- `upgrades/memory_helper/memory_helper_upgrade.gd` (new)
- `upgrades/memory_helper/memory_helper.tres` (updated script reference)
- `upgrades/upgrade_manager.gd` (added upgrade_manager reference assignment)

### 4. Extra Life
**Status**: ⏳ Pending (requires controller changes)
**Approach**: Add life management signals to LevelController
**Controller Changes Needed**:
- [ ] Add `signal life_changed(new_count: int)` to LevelController
- [ ] Add `add_lives(count: int)` method to LevelController
- [ ] Update life loss logic to use signals

**Implementation Plan**:
- [ ] Design minimal LevelController changes
- [ ] Implement life management signals
- [ ] Create `extra_life_upgrade.gd` extending BaseUpgrade
- [ ] Override `_on_purchase()` to add lives via signal/method
- [ ] Update resource file

**Files to Create/Modify**:
- `show_sequence/level_controller.gd` (add life management)
- `upgrades/extra_life/extra_life_upgrade.gd` (new)
- `upgrades/extra_life/extra_life.tres` (update script reference)

### 5. Lucky Charm
**Status**: ⏳ Pending (requires controller changes)
**Approach**: Add mistake forgiveness pipeline to LevelController
**Controller Changes Needed**:
- [ ] Add `signal life_about_to_be_lost()` (cancellable) to LevelController
- [ ] Modify wrong button press handling to check for forgiveness
- [ ] Allow upgrades to cancel life loss

**Implementation Plan**:
- [ ] Design mistake forgiveness pipeline
- [ ] Implement cancellable life loss signals
- [ ] Create `lucky_charm_upgrade.gd` extending BaseUpgrade
- [ ] Track first mistake per sequence in session data
- [ ] Override life loss signals to forgive first mistake
- [ ] Update resource file

**Files to Create/Modify**:
- `show_sequence/level_controller.gd` (add mistake handling)
- `upgrades/lucky_charm/lucky_charm_upgrade.gd` (new)
- `upgrades/lucky_charm/lucky_charm.tres` (update script reference)

## Testing Strategy
- [ ] Test each upgrade individually during development
- [ ] Test upgrade selection UI with all upgrades
- [ ] Test multiple upgrades active simultaneously
- [ ] Test upgrade effects across level transitions
- [ ] Test edge cases (multiple coin rewards, time scale conflicts, etc.)

## Architecture Principles
1. **Loose Coupling**: Upgrades should not modify controller code directly
2. **Signal-Based**: Use existing signal system for communication
3. **Session-Only**: All upgrade effects are temporary (run-only)
4. **Clean Separation**: Each upgrade has its own folder and script
5. **Extensible**: Easy to add new upgrades following same patterns

## Current Status
- ✅ **Coin Multiplier**: Complete and functional
- ✅ **Slow Motion**: Complete and functional
- 🔄 **Memory Helper**: Ready to implement (no controller changes needed)
- ⏳ **Extra Life**: Waiting for controller life management design
- ⏳ **Lucky Charm**: Waiting for controller mistake handling design

## Next Steps
1. ✅ ~~Implement Slow Motion upgrade using `Engine.time_scale`~~ (COMPLETED)
2. Implement Memory Helper upgrade using button `flash()` method
3. Design minimal LevelController changes for life management
4. Implement Extra Life and Lucky Charm upgrades
5. Comprehensive testing of all upgrades