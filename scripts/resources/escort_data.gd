class_name EscortData
extends Resource

## Data resource for Escort Vehicle configuration.

@export var scene: PackedScene # The actual vehicle scene to instantiate
@export var max_health: float = 100.0
@export var speed: float = 10.0
@export var acceleration: float = 20.0
@export var rotation_speed: float = 5.0

@export_group("Weapon Configuration")
@export var weapon_projectile_data: ProjectileData
@export var weapon_projectile_scene: PackedScene # Base projectile scene (container)
@export var weapon_range: float = 300.0
@export var weapon_fire_rate: float = 1.0

enum MovementMode { GROUND, AIR }
@export_group("Behavior")
@export var movement_mode: MovementMode = MovementMode.GROUND
@export var hover_height: float = 2.0
@export var seek_weight: float = 1.0
@export var separate_weight: float = 2.0
@export var personal_space: float = 3.0
