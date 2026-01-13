extends CharacterBody2D

@export var move_speed: float = 200.0
@export var turn_speed: float = 2.0
@export var turret_turn_speed: float = 4.0

@onready var tank_body: Node2D = $TankBodyMesh

@onready var tank_turret: Sprite2D = $TankTurretSprite

func _physics_process(delta: float) -> void:
	var rotation_direction := Input.get_axis("turn_counter_clockwise", "turn_clockwise")
	tank_body.rotation += rotation_direction * turn_speed * delta

	var move_direction := Input.get_axis("move_backward", "move_forward")
	velocity = Vector2.UP.rotated(tank_body.rotation) * move_direction * move_speed
	
	# Turret aiming
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0:
		var nearest_enemy = null
		var min_dist = INF
		
		for enemy in enemies:
			var dist = global_position.distance_squared_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_enemy = enemy
		
		if nearest_enemy:
			var target_phase = global_position.direction_to(nearest_enemy.global_position).angle()
			tank_turret.rotation = lerp_angle(tank_turret.rotation, target_phase + (PI/2), turret_turn_speed * delta)
	
	move_and_slide()
