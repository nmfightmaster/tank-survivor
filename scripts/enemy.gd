extends CharacterBody2D

@export var move_speed: float = 180.0
@export var turn_speed: float = 2.0

@onready var tank_body: Node2D = $TankBodyMesh

@onready var tank_turret: Node2D = $TankTurretSprite

func _ready() -> void:
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Fallback try to find sibling named Player
		player = get_node_or_null("../Player")
		
	if player:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * move_speed
		
		# Optional: Rotate towards player
		tank_body.rotation = lerp_angle(tank_body.rotation, direction.angle() - (PI/2), turn_speed * delta)
		
		# Rotate turret towards player
		tank_turret.look_at(player.global_position)
		tank_turret.rotation += PI/2
		
		move_and_slide()