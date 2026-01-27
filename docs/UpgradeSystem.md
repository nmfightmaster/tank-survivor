# Upgrade System Documentation

This document outlines the architecture and usage of the modular Upgrade and Stat Modifier system.

## 1. Architecture Overview

The system moves away from raw variables (e.g., `speed = 10`) to an object-oriented `Stat` system. This allows for clean, non-destructive modification of values through upgrades without "spaghetti code" logic (like `speed = speed * 1.1`).

### Core Components

#### `Stat` (Resource)
-   **Location**: `res://scripts/resources/Stat.gd`
-   **Purpose**: Represents a single numeric attribute (Speed, Damage, etc.).
-   **Functionality**:
    -   Holds a `base_value` (initial stats).
    -   Maintains a list of `StatModifier`s.
    -   Calculates the final effective value on demand via `get_value()`.
    -   Caches the result for performance until a modifier is added/removed (`dirty` flag pattern).
-   **Signals**: `value_changed(new_value)` - emitted whenever a modifier changes the final value.

#### `StatModifier` (Resource)
-   **Location**: `res://scripts/resources/StatModifier.gd`
-   **Purpose**: A data packet representing a change to a Stat.
-   **Properties**:
    -   `value`: The numeric amount (e.g., `10.0` or `0.2`).
    -   `type`:
        -   `ADDITIVE`: Adds directly to base (Base 10 + 5 = 15).
        -   `MULTIPLICATIVE`: Adds percentage to a multiplier accumulator (Base 10 * (1.0 + 0.2) = 12).

#### `UpgradeData` (Resource)
-   **Location**: `res://scripts/resources/UpgradeData.gd`
-   **Purpose**: The data-driven definition of an upgrade displayed to the player.
-   **Key Properties**:
    -   `target_stat`: String name of the variable in `GameManager` to modify (e.g., `"player_speed"`).
    -   `modifier_value` & `modifier_type`: Defines the underlying `StatModifier` to create.

#### `GameManager` (Singleton)
-   **Location**: `res://scripts/GameManager.gd`
-   **Purpose**: Acts as the central registry for Stats.
-   **Setup**:
    -   Because `GameManager` is a Singleton, you must convert it to a Scene Autoload to assign the `UpgradePool` in the Inspector.
    -   **Steps**:
        1.  I have created `res://scenes/managers/game_manager.tscn` for you.
        2.  Go to **Project -> Project Settings -> Globals (Autoload)**.
        3.  Find `GameManager`.
        4.  Click the folder icon next to the path.
        5.  Select `res://scenes/managers/game_manager.tscn`.
        6.  Now you can open `scenes/GameManager.tscn`, click the root node, and assign your `UpgradePool` in the Inspector.

-   **Key Changes**:
    -   Stats are now initialized as `Stat` objects in `_init_stats()`.
    -   `apply_upgrade(upgrade)`: Generic function that takes an `UpgradeData`, finds the matching Stat by name, and injects a new Modifier.

---

## 2. Developer Guide

### How to Add a New Upgrade
You do not need to write code to add new standard upgrades.

1.  **Create Resource**:
    -   In the FileSystem, right-click -> **Create New** -> **Resource**.
    -   Search for `UpgradeData`.
    -   Save it in `res://resources/upgrades/` (or similar folder).

2.  **Configure Upgrade**:
    -   **Title**: Display name (e.g., "Heavy Barrels").
    -   **Description**: Effect text (e.g., "+5 Damage").
    -   **Icon**: Drag a texture here.
    -   **Target Stat**: **Crucial**. This must match the variable name in `GameManager` exactly.
        -   Available: `player_speed`, `player_rotation_speed`, `player_turret_speed`, `player_damage`, `player_fire_rate`, `player_projectile_speed`.
    -   **Modifier Value**: The number to apply (e.g., `5.0`).
    -   **Modifier Type**:
        -   `Additive`: Flat increase.
        -   `Multiplicative`: Percentage increase.
            -   **Important**: The value is added to 1.0.
            -   Example: `0.2` becomes `1.2x` (+20%).
            -   Stacking: Multiple multiplicative upgrades add together first (Additive Multipliers).
                -   Two `0.2` upgrades = `1.0 + 0.2 + 0.2 = 1.4x` (Not `1.44x`).

3.  **Add to Pool**:
    -   Open your `UpgradePool` resource (e.g., `DefaultPool.tres`).
    -   Add the new `UpgradeData` file to the `Upgrades` array.

### How to Add a New Stat
If you want to track a new attribute (e.g., "Armor"):

1.  **Update `GameManager.gd`**:
    ```gdscript
    var player_armor: Stat # Declare variable

    func _init_stats():
        # ... existing stats ...
        player_armor = Stat.new(0.0) # Initialize with base value
    ```

2.  **Use in Gameplay**:
    -   In your Tank/Enemy script, access it via:
    ```gdscript
    var damage_taken = incoming_damage - GameManager.player_armor.get_value()
    ```

3.  **Create Upgrades**:
    -   Create an `UpgradeData` with `target_stat = "player_armor"`.
