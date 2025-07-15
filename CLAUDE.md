# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Geometry Survivor** is a Godot 4.5 top-down survival game with modular equipment systems, buff mechanics, and meta-progression through a safe house system.

## Core Architecture

### Module Structure (5-layer architecture)
```
Layer 1: globals/          - Core services (EventBus, GameManager, Constants)
Layer 2: entities/         - Game entities (Player, Enemies, Buffs)
Layer 3: equipment/        - Weapons, armor, mods, hit effects
Layer 4: ui/              - User interface components
Layer 5: scenes/          - Scene organization and prefabs
```

### Key Systems

**Event System**: Uses FightEventBus for decoupled communication between modules
- `on_projectile_kill`, `on_equipment_used`, `on_player_damage`, etc.

**Equipment System**: Modular weapon/armor system with
- Base classes: `equipment_base.gd`, `equipment_resource.gd`
- Emitters: `emitter_equipment_base.gd` for ranged weapons
- Armor: `armor_equipment_base.gd` for defensive gear
- Mods: Event-driven enhancement system (see equipment/mod/README.md)

**Buff System**: Status effect framework
- `buff_manager.gd` handles buff application/removal
- Effect types: attribute modifiers, DoT, control effects

**Safe House**: Meta-progression hub with 6 rooms
- Battle, Brand, Main, Recruit, Research, Upgrade rooms
- Managed by `safe_house_manager.gd`

## Development Commands

### Godot CLI Commands
```bash
# Run the game
godot --path /Users/xiechuyu/code/godot/geometry-survivor/

# Run specific scene
godot --path /Users/xiechuyu/code/godot/geometry-survivor/ src/fight/fight.tscn

# Export (if configured)
godot --path /Users/xiechuyu/code/godot/geometry-survivor/ --export-release "Windows Desktop" build/
```

### Debug & Testing
```bash
# Enable verbose logging
godot --verbose --path /Users/xiechuyu/code/godot/geometry-survivor/

# Run with debug collision shapes visible
godot --debug-collisions --path /Users/xiechuyu/code/godot/geometry-survivor/

# Profile performance
godot --profile-gpu --path /Users/xiechuyu/code/godot/geometry-survivor/
```

### Common Development Tasks

**Adding New Equipment**:
1. Create equipment class inheriting from appropriate base
2. Define resource in `equipment/{type}/resources/`
3. Add to equipment manager if needed

**Creating New Mods**:
1. Define trigger in `equipment/mod/triggers/`
2. Define effect in `equipment/mod/effects/`
3. Create mod resource combining trigger + effect
4. Test via ModManager API

**Adding Buffs**:
1. Create buff effect in `entities/buff/effects/`
2. Define buff resource in `entities/buff/resources/`
3. Reference from equipment mods or direct application

## File Patterns

- `.gd` - GDScript files (main logic)
- `.tres` - Resource files (config/data)
- `.tscn` - Scene files (Godot scenes)
- `.uid` - Unique identifiers (auto-generated)

## Key Entry Points

- **Game Entry**: `src/fight/fight.tscn` (main scene)
- **Safe House**: `src/safe_house/safe_house.tscn`
- **Player**: `src/entities/player/player.tscn`
- **Equipment Manager**: `src/equipment/equipment_manager.gd`

## Module Communication

All inter-module communication happens through:
1. **EventBus** (`src/fight/global/event_bus.gd`) - Global events
2. **FightEventBus** (`src/fight/global/fight_event_bus.gd`) - Combat events
3. **Direct references** within same layer (entities ↔ equipment)

## Configuration Files

- `project.godot` - Engine configuration
- `src/globals/constants.gd` - Game constants
- Equipment/buff/mod resources in respective `resources/` folders