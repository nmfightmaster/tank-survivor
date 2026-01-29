# Upgrade System Documentation

This document outlines the architecture and usage of the modular Upgrade and Stat Modifier system.

## 1. Architecture Overview

The system processes upgrades in two distinct categories: **Stat Upgrades** and **Behavior Upgrades**. This allows for flexible progression where stat boosts (Health, Speed) can be granted on level-up, while game-changing behaviors (Ricochet, Multishot) can be tied to specific achievements or milestones (e.g., Vehicle Kills).

### Core Components

#### `UpgradePool` (Resource)
-   **Location**: `res://scripts/resources/upgrade_pool.gd`
-   **Purpose**: Manages the collections of available upgrades.
-   **Structure**:
    -   `stat_upgrades`: Array of `UpgradeData` for numeric stat boosts. **These are available in the Level-Up pool.**
    -   `behavior_upgrades`: Array of `UpgradeData` for granting new behaviors. **These are excluded from the Level-Up pool** and are granted when a specific vehicle reaches a kill threshold.
    -   **Functionality**:
        -   `pick_behavior_upgrades(count, active_behaviors)`: Selects behavior upgrades intelligently.
        -   **Smart Upgrades**: If a vehicle already owns a behavior (e.g., Ricochet), this method converts the "Unlock Ricochet" card into an "Upgrade Ricochet" card (e.g., +1 Bounce).
        -   **Cap Limit**: Vehicles can hold a maximum of **3 unique behaviors**. Once capped, new behaviors will not be offered.

#### `UpgradeData` (Resource)
-   **Location**: `res://scripts/resources/upgrade_data.gd`
-   **Purpose**: The data-driven definition of an upgrade displayed to the player.
-   **Key Properties**:
    -   `target_stat`: String name of the variable in `VehicleBase` to modify (e.g., `"speed"`).
    -   `modifier_value` & `modifier_type`: Defines the underlying `StatModifier`.
    -   `granted_behavior`: A `ProjectileBehavior` resource or script to properly add a new mechanic to the vehicle.
    -   `target_behavior_script` & `target_behavior_stat`: For substat upgrades (e.g., boosting `bounce_count` on an existing Ricochet behavior).

#### `Stat` (Resource)
-   **Location**: `res://scripts/resources/stat.gd`
-   **Purpose**: Represents a single numeric attribute (Speed, Damage, etc.).
-   **Functionality**:
    -   Holds a `base_value` (initial stats).
    -   Maintains a list of `StatModifier`s.
    -   Calculates the final effective value on demand via `get_value()`.

#### `GameManager` (Singleton)
-   **Location**: `res://scripts/managers/game_manager.gd`
-   **Purpose**: Central hub for applying upgrades.
-   **Key Changes**:
    -   `apply_upgrade(upgrade)`:
        -   **Stat Upgrades**: Applied globally to **all** vehicles in the squadron.
        -   **Behavior Upgrades**: Applied to the **Specific Vehicle** that triggered the upgrade request.
    -   `_on_vehicle_request_upgrade(vehicle)`: Handles individual vehicle upgrade triggers.

---

## 2. Developer Guide

### How to Add a New Stat Upgrade
(e.g., "+10% Fire Rate")

1.  **Create Resource**:
    -   Right-click -> **Create New** -> **Resource** -> `UpgradeData`.
    -   Save in `res://resources/data/upgrades/`.

2.  **Configure Upgrade**:
    -   **Title/Description/Icon**: Set for UI.
    -   **Target Stat**: Must match the variable name in `VehicleBase` (e.g., `"fire_rate"`).
    -   **Modifier Value**: `0.1` (for 10%).
    -   **Modifier Type**: `Multiplicative` (Percentage) or `Additive` (Flat).

3.  **Add to Pool**:
    -   Open `res://resources/data/default_pool.tres`.
    -   Add your new resource to the **`Stat Upgrades`** array.
    -   **Result:** This upgrade will now appear in the Level-Up choices.

### How to Add a New Behavior Upgrade
(e.g., "Ricochet")

1.  **Create Resource**:
    -   Create `UpgradeData` as above.
    -   **Granted Behavior**: Assign a `ProjectileBehavior` script or resource (e.g., `RicochetBehavior`).
    -   **Target Stat**: Leave empty (unless it also boosts stats).

2.  **Add to Pool**:
    -   Open `res://resources/data/default_pool.tres`.
    -   Add your new resource to the **`Behavior Upgrades`** array.
    -   **Result:** This upgrade is **NOT** available via Level-Up. It will be offered when a vehicle reaches its kill threshold.

### How to Add a New Stat Attribute
If you want to track a new attribute (e.g., "Armor"):

1.  **Update `VehicleBase.gd`**:
    ```gdscript
    @export var armor: Stat
    
    func _init_stats():
        # ... existing stats ...
        armor = Stat.new(0.0)
    ```

2.  **Update `reset_stats()` in `VehicleBase.gd`** to include correct initialization for the new stat.

3.  **Use in Gameplay**:
    ```gdscript
    var damage_taken = calculate_damage(incoming) - armor.get_value()
    ```

### Kill Threshold System
- **Scaling**: Each vehicle tracks its own kills.
- **Milestones**: Upgrades are granted at 10, 20, 40, 80... kills (doubles each time).
- **Trigger**: `VehicleBase` emits `request_upgrade` when threshold is met.
