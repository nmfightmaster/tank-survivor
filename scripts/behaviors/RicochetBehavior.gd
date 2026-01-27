class_name RicochetBehavior
extends ProjectileBehavior

@export var bounce_count: int = 2
@export var range: float = 150.0
@export var ricochet_sound: AudioStream

var _current_bounces: int

func on_ready(projectile: Node) -> void:
	_current_bounces = bounce_count

func on_hit_enemy(projectile: Node, context: Dictionary) -> void:
	if _current_bounces > 0:
		var current_enemy = context.get("collider")
		var pos = context.get("position", projectile.global_position)
		
		var nearest = _find_nearest_enemy(projectile, pos, current_enemy)
		
		if nearest:
			# Prevent destruction
			projectile.set_meta("cancel_destroy", true)
			
			# Point towards new target
			projectile.look_at(nearest.global_position, Vector3.UP)
			
			# Play Sound
			if projectile.has_method("play_sound"):
				projectile.play_sound(ricochet_sound)
		
		_current_bounces -= 1

func _find_nearest_enemy(projectile, origin: Vector3, exclude_node: Node) -> Node3D:
    var enemies = projectile.get_tree().get_nodes_in_group("enemy")
    
    var nearest: Node3D = null
    var min_dist = range
    
    for enemy in enemies:
        if enemy == exclude_node:
            continue
            
        var dist = origin.distance_to(enemy.global_position)
        
        if dist < min_dist:
            min_dist = dist
            nearest = enemy
            
    return nearest

func get_valid_upgrades() -> Array[Dictionary]:
    return [
        { "title": "+1 Bounce", "stat": "bounce_count", "value": 1.0 },
        { "title": "+50 Range", "stat": "range", "value": 50.0 }
    ]
