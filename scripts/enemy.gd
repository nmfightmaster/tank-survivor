extends CharacterBody3D

@export var speed: float = 4.0

@onready var last_pos = global_position

func _ready() -> void:
	print("Enemy READY at: ", global_position, " PATH: ", get_path(), " ID: ", get_instance_id())

func _physics_process(delta: float) -> void:
	if global_position.distance_to(last_pos) > 1.0:
		print("Enemy JUMPED from ", last_pos, " to ", global_position, " ID: ", get_instance_id())
	last_pos = global_position

	var direction = global_position.direction_to(GameManager.player_position)
	velocity = direction * speed
	move_and_slide()
