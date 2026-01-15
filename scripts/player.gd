extends CharacterBody3D

@export var speed: float = 10.0
@export var rotation_speed: float = 2.0
@export var tank_body_mesh: MeshInstance3D
@export var tank_turret_mesh: MeshInstance3D
@export var tank_collision: CollisionShape3D
@export var tank_hitbox: Area3D

@onready var damage_timer: Timer = $Hitbox/DamageTimer

var enemies_touching: int = 0

func _ready() -> void:
	GameManager.player_position = global_position

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		enemies_touching += 1
		if damage_timer.is_stopped():
			take_damage()
			damage_timer.start()

func _on_hitbox_body_exited(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		enemies_touching -= 1
		if enemies_touching <= 0:
			enemies_touching = 0
			damage_timer.stop()

func _on_damage_timer_timeout() -> void:
	take_damage()

func take_damage() -> void:
	GameManager.player_health -= 10
	print("Player health: ", GameManager.player_health)

	if GameManager.player_health <= 0:
		GameManager.player_health = 0
		die()

func die() -> void:
	print("Player died!")
	get_tree().reload_current_scene()
	GameManager.player_health = 100
	enemies_touching = 0

func _physics_process(delta: float) -> void:
	GameManager.player_position = global_position
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle rotation
	var rotation_direction := Input.get_axis("turn_clockwise", "turn_counter_clockwise")
	if rotation_direction:
		tank_body_mesh.rotate_y(rotation_direction * rotation_speed * delta)
		if tank_collision:
			tank_collision.rotation.y = tank_body_mesh.rotation.y
		if tank_hitbox:
			tank_hitbox.rotation.y = tank_body_mesh.rotation.y

	# Handle movement
	var input_dir := Input.get_axis("move_backward", "move_forward")
	if input_dir:
		# Move in the direction the tank body is facing
		var direction = -tank_body_mesh.global_transform.basis.z * input_dir
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

