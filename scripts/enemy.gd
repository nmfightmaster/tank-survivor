extends CharacterBody3D

@export var speed: float = 9.0
@export var health: int = 20

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	queue_free()

func _physics_process(delta: float) -> void:
	var direction = global_position.direction_to(GameManager.player_position)
	velocity = direction * speed
	move_and_slide()
