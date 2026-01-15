extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 2.0

@export var tankBodyMesh: MeshInstance3D
@export var tankTurretMesh: MeshInstance3D
@export var tankCollision: CollisionShape3D


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle rotation
	var rotation_direction := Input.get_axis("turn_clockwise", "turn_counter_clockwise")
	if rotation_direction:
		tankBodyMesh.rotate_y(rotation_direction * ROTATION_SPEED * delta)
		if tankCollision:
			tankCollision.rotation.y = tankBodyMesh.rotation.y

	# Handle movement
	var input_dir := Input.get_axis("move_backward", "move_forward")
	if input_dir:
		# Move in the direction the tank body is facing
		var direction = -tankBodyMesh.global_transform.basis.z * input_dir
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
