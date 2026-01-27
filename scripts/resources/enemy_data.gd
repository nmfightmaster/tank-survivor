class_name EnemyData
extends Resource

## Data resource for Enemy configuration.

@export var base_health: int = 20
@export var base_speed: float = 9.0
@export var damage: int = 10
@export var xp_reward: int = 10
@export var enemy_model: PackedScene
@export var behaviors: Array[EnemyBehavior] = []

func _init() -> void:
	# Ensure arrays are unique per instance if modified at runtime, though resources are usually shared.
	pass
