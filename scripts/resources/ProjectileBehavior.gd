class_name ProjectileBehavior
extends Resource

## Base class for all projectile behaviors (Ricochet, Splitting, etc.)

# Execute logic. This is general purpose, but usually called on specific events.
# 'projectile' is the ProjectileBase node.
# 'context' is an optional dictionary for extra data (e.g. valid targets, impact point, etc.)
func execute(projectile: Node, context: Dictionary = {}) -> void:
	pass

# Called when the projectile is successfully created and ready
func on_ready(projectile: Node) -> void:
	pass

# Called every physics frame
func on_physics_process(projectile: Node, delta: float) -> void:
	pass

# Called when the projectile hits an enemy
# context usually contains { "collider": node, "position": Vector3, "normal": Vector3 }
func on_hit_enemy(projectile: Node, context: Dictionary) -> void:
	pass

# Called when the projectile hits a wall/obstacle
func on_hit_wall(projectile: Node, context: Dictionary) -> void:
	pass

# Called when the projectile expires (lifetime ends)
func on_expired(projectile: Node) -> void:
	pass

# Called when the projectile is destroyed (removed from tree)
func on_destroyed(projectile: Node) -> void:
	pass

# Returns a list of potential upgrades for this behavior
# Each upgrade is a Dictionary: { "title": String, "stat": String, "value": float }
func get_valid_upgrades() -> Array[Dictionary]:
	return []
