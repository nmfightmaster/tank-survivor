# Enemy System Documentation

## Overview
The new Enemy System is modular and data-driven, separating logic (`EnemyBase.gd`) from data (`EnemyData.gd`) and visuals (`enemy.tscn`). Scaling and spawning are handled by the `WaveManager`.

## Migration Guide
To migrate an old enemy or create a new one:

1. **Visuals**: Create a scene (e.g. `MyEnemyModel.tscn`) with a root `Node3D`. Add your MeshInstance and any animations. Do *not* add scripts or physics bodies here.
2. **Data**: Create a new resource in `res://scripts/resources/enemies/` (or similar).
   - Right-click in FileSystem -> Create New -> Resource -> `EnemyData`.
   - Set `Base Health`, `Base Speed`, `Damage`.
   - Set `Xp Reward` (amount of XP dropped on death).
   - Assign your `MyEnemyModel.tscn` to the `Enemy Model` field.
   - Add behaviors to the `Behaviors` array (e.g., `ChasePlayerBehavior`).

## Creating Bosses
1. Create a generic `BossData.tres` of type `EnemyData`.
2. Increase stats (High Health, Size).
3. Assign a distinct model.
4. Add unique `EnemyBehavior` scripts (e.g., `BossChargeBehavior`).

## Wave Manager & Budget System
The `WaveManager` replaces the old spawner.
- **WaveData**: Define waves as resources.
  - `Total Budget`: Maximum cost of enemies to spawn in this wave.
  - `Available Enemies`: List of `EnemyData` types.
  - `Spawn Weights`: Chance for each enemy type to spawn.
- **Scaling**: The manager scales spawn rates based on `GameManager.level`.
- **Infinite Mode**: When all defined waves are completed, the `WaveManager` automatically loops the last wave.
  - It applies a difficulty multiplier that increases with each cycle.
  - Spawn rates increase and the budget expands, allowing for higher density.
