extends CharacterBody3D

@export var speed: float = 9.0
@export var health: int = 20
@export var xp_scene: PackedScene

func _ready() -> void:
	speed = GameManager.enemy_speed
	health = GameManager.enemy_health

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	var xp = xp_scene.instantiate()
	get_tree().current_scene.add_child(xp)
	xp.global_position = global_position
	queue_free()

func _physics_process(delta: float) -> void:
	var direction = global_position.direction_to(GameManager.player_position)
	velocity = direction * speed
	move_and_slide()
