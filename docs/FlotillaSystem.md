# Flotilla System Documentation

## Overview
The **Flotilla System** enables the player to control a swarm of support vehicles (Escorts) or drones. These units are autonomous, following the player and engaging enemies using their own independent weapon systems. The system is data-driven, allowing for easy creation of diverse unit types (e.g., Tanks, Drones, Turrets) without code changes.

## Architecture

### `EscortManager.gd`
- **Location**: `res://scripts/managers/escort_manager.gd`
- **Role**: The "Fleet Brain". Manages the spawning, tracking, and cleanup of all flotilla units.
- **Key Functions**:
    - `spawn_unit(resource: EscortData)`: Instantiates a unit and configures it.
    - `active_escorts`: Array of currently living units.

### `EscortVehicle.gd`
- **Location**: `res://scripts/entities/escort_vehicle.gd`
- **Role**: The "Swarm Entity". Handles movement, state machine (FOLLOW/ATTACK), and component integration.
- **Movement Modes**:
    - `GROUND`: Applies gravity, sticks to floors (e.g., Tanks).
    - `AIR`: Ignores gravity, hovers at a set height (e.g., Drones).

### `EscortData` (Resource)
- **Location**: `res://scripts/resources/escort_data.gd`
- **Role**: Configuration file for a specific unit type.
- **Properties**:
    - `Scene`: The `.tscn` file for the vehicle.
    - `Movement Mode`: GROUND or AIR.
    - `Hover Height`: Flying altitude (for AIR mode).
    - `Weapon Projectile Data`: The `ProjectileData` this unit fires.

---

## How-To Guide

### 1. Create a New Unit Type (e.g., "Attack Drone")

1.  **Create the Scene**:
    -   Root Node: `CharacterBody3D`.
    -   Script: Attach `EscortVehicle.gd`.
    -   Mesh/Collision: Add your visual models.
    -   **Components**: Add `WeaponComponent` node (Node3D) and `HealthComponent` node (Node).
    -   **Important**: Assign the `WeaponComponent` script's `Projectile Scene` export to your generic bullet scene (e.g., `ProjectileBase.tscn`).

2.  **Create the Data**:
    -   Create a new resource inheriting `EscortData`.
    -   **Scene**: Assign your new `.tscn`.
    -   **Movement Mode**: Set to `AIR` for a drone.
    -   **Weapon Configuration**: Assign a `ProjectileData` resource (reuse existing ones or create new).

3.  **Spawn**:
    -   Call `EscortManager.spawn_unit(drone_data)` from anywhere in your game logic.

### 2. Customizing Weapons
Escorts use the same `ProjectileData` system as the player.

-   To change a unit's weapon, simply modify the `Weapon Projectile Data` property in its `EscortData` resource.
-   You can reuse player weapons (e.g., make a "Sniper Drone" by giving it the Player's Sniper projectile data).

### 3. Integration with Upgrades
The system is built on the `Stat` class, making it compatible with the Upgrade System.

#### Future Implementation for Upgrades:
To allow upgrades to target Escorts, you would:

1.  Create an `UpgradeData` resource.
2.  **Targeting Strategies**:
    -   **Global Buff**: Create a "FlotillaStats" global resource that all escorts read from.
    -   **Specific Buff**: Iterate through `EscortManager.active_escorts` and apply a `StatModifier` to their `weapon_component.damage_multiplier_stat` or `speed_stat`.

**Example (Conceptual Script):**
```gdscript
# In GameManager or UpgradeManager
func apply_flotilla_upgrade(modifier_value):
    for unit in EscortManager.active_escorts:
        unit.weapon_component.damage_multiplier_stat.add_modifier(
            StatModifier.new(modifier_value, StatModifier.Type.ADDITIVE)
        )
```

---

## Technical Details

### Steering Behaviors
Unit movement is driven by weighted vectors:
1.  **Seek**: Moves towards the Player (Follow state) or Enemy (Attack state).
2.  **Separation**: Pushes away from other `flotilla_members` to prevent stacking.
3.  **Hover (Air Only)**: Applies vertical force to maintain `hover_height`.

Weights for these behaviors are exposed in `EscortData` and can be tweaked to change the "feel" of the swarm (e.g., "loose" vs "tight" formation).
