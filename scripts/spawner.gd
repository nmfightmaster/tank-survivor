extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.0
@export var spawn_radius: float = 600.0

var _timer: float = 0.0

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		spawn_enemy()

func spawn_enemy() -> void:
	if not enemy_scene:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Fallback if group not set, though risky if multiple nodes named Player
		player = get_node_or_null("../Player") 
	
	if not player:
		return
		
	var random_angle = randf() * TAU
	var spawn_pos = player.global_position + Vector2(cos(random_angle), sin(random_angle)) * spawn_radius
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	
	# Add to the same parent as the spawner (likely the world root)
	get_parent().add_child(enemy)
