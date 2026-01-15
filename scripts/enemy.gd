extends CharacterBody3D

@export var speed: float = 9.0

func _physics_process(delta: float) -> void:
	var direction = global_position.direction_to(GameManager.player_position)
	velocity = direction * speed
	move_and_slide()
