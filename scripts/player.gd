extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 2.0

@export var tank_body_mesh: MeshInstance3D
@export var tank_turret_mesh: MeshInstance3D
@export var tank_collision: CollisionShape3D

func _ready() -> void:
	GameManager.player_position = global_position

func _physics_process(delta: float) -> void:
	GameManager.player_position = global_position
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle rotation
	var rotation_direction := Input.get_axis("turn_clockwise", "turn_counter_clockwise")
	if rotation_direction:
		tank_body_mesh.rotate_y(rotation_direction * ROTATION_SPEED * delta)
		if tank_collision:
			tank_collision.rotation.y = tank_body_mesh.rotation.y

	# Handle movement
	var input_dir := Input.get_axis("move_backward", "move_forward")
	if input_dir:
		# Move in the direction the tank body is facing
		var direction = -tank_body_mesh.global_transform.basis.z * input_dir
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

