# Projectile System Documentation

## Overview
The **Component-Based Projectile System** allows for modular bullet behaviors (like Ricochet, Splitting, AoE) to be mixed and matched dynamically. Instead of hardcoding logic into `bullet.gd`, projectiles now hold a list of `ProjectileBehavior` resources.

## Architecture

### `ProjectileBase.gd`
- **Location**: `res://scripts/ProjectileBase.gd`
- **Role**: Replaces the old `bullet.gd`. Manages movement, lifetime, and collision detection.
- **Key Feature**: `active_behaviors` array. Iterates through behaviors to delegate logic.

### `ProjectileBehavior` (Resource)
- **Location**: `res://scripts/resources/ProjectileBehavior.gd`
- **Role**: Abstract base class. Defines hooks like `on_ready`, `on_hit_enemy`, `on_destroyed`.
- **How to Create**: Inherit from this class and override the desired functions.

### `ProjectileData` (Resource)
- **Location**: `res://scripts/resources/ProjectileData.gd`
- **Role**: Defines a "Type" of projectile (model scene, speed, damage mult, default behaviors).
- **Note on Models**: The `Projectile Model` scene can have any structure. `ProjectileBase` will automatically find any `CollisionShape3D` nodes inside it and apply them to the projectile logic.

---

## How-To Guide

### 1. Add a New Projectile Type
1.  Create a new Resource in Godot.
2.  Search for **ProjectileData**.
3.  Set properties:
    -   `Speed`, `Lifetime`.
    -   `Projectile Model`: Assign a `.tscn` file containing the Mesh and CollisionShape.
    -   `Fire Sound` / `Hit Sound`: (Optional) Assign custom audio streams.
    -   `Default Behaviors`: (Add things inherently on this bullet, e.g., "Explosive Shell").

### 2. Add a New Behavior (Scripting)
Write a new script inheriting from `ProjectileBehavior`.

**Example: Poison Trail**
```gdscript
class_name PoisonTrailBehavior
extends ProjectileBehavior

@export var poison_scene: PackedScene

func on_physics_process(projectile: Node, delta: float) -> void:
    if poison_scene:
         # Spawn a trail particle every frame or distance
         pass
```

**Hookable Events:**
- `on_ready(projectile)`
- `on_physics_process(projectile, delta)`
- `on_hit_enemy(projectile, context)` (Context has `collider`, `position`, `normal`)
- `on_hit_wall(projectile, context)`
- `on_expired(projectile)` (Time ran out)
- `on_destroyed(projectile)` (Queue free called)

### 3. Behavior Stacking
Behaviors run in the order they are added.
- **Example**: `[Ricochet, Explode]`
    - **Ricochet** intercepts the hit on enemy, rotates the bullet, and cancels destruction.
    - **Explode** might trigger on destruction. If Ricochet prevents destruction, Explode won't run until the final hit (when Ricochet runs out of bounces).

To make behaviors compatible, use tags or check flags on the projectile.
- `projectile.set_meta("cancel_destroy", true)` allows a behavior to keep the bullet alive after a hit.

### 4. Integration with Upgrade System
You can create an Upgrade that grants a new behavior.

1.  Create an **UpgradeData** resource.
2.  Set `Title`, `Icon`, etc.
3.  Leave `Target Stat` empty (unless you also want to buff a stat).
4.  **Granted Behavior**:
    -   **Option A (Simple)**: Drag and drop the `.gd` script (e.g., `RicochetBehavior.gd`). This uses default values (e.g., Bounce Count = 2).
    -   **Option B (Configured)**: Create a new Resource (`RicochetBehavior`), set custom values (e.g., Bounce Count = 10), save it as a `.tres`, and assign that.
5.  When picked, `GameManager` adds this behavior to the global pool, and `Player` injects it into every new shot.

---

## Smart Behavior Upgrades
The system automatically detects if a player already owns a behavior.

-   **Unlock**: If the player **does not** own the behavior, the upgrade card unlocks it.
-   **Upgrade**: If the player **already owns** it, the card transforms into a stat boost for that behavior (e.g., "+1 Bounce").

### Defining Upgrades
Override `get_valid_upgrades()` in your `ProjectileBehavior` script:
```gdscript
func get_valid_upgrades() -> Array[Dictionary]:
    return [
        { "title": "+1 Bounce", "stat": "bounce_count", "value": 1.0 },
        { "title": "+50 Range", "stat": "range", "value": 50.0 }
    ]
```

---

## Behavior Sounds
Behaviors can trigger their own sound effects.

### 1. In Scripts
Call `projectile.play_sound(stream)` to play a sound at the bullet's location. This handles temporary audio players automatically.

```gdscript
@export var my_sound: AudioStream

func on_hit_enemy(projectile, context):
    if projectile.has_method("play_sound"):
        projectile.play_sound(my_sound)
```

### 2. Supported Behaviors
-   **Ricochet**: Assign a stream to `Ricochet Sound` property.
-   **Explode**: Assign a stream to `Explosion Sound` property.
