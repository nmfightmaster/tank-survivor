class_name TankVehicle
extends VehicleBase

## Tank-specific implementation.
## Handles specific movement physics (sliding) and Turret rotation.

@export_group("Tank Visuals")
@export var tank_body_mesh: MeshInstance3D
@export var tank_turret_mesh: MeshInstance3D
@export var tank_turret_speed_stat_name: String = "turret_speed" # Allow unique stat name if needed

# We need a separate stat for turret speed, which VehicleBase doesn't have in its default set
# But we can add it or just use 'rotation_speed'. 
# Let's add it as a specific stat for Tanks.
var turret_speed: Stat

@export var base_turret_speed: float = 4.0

# Input Control Variables (Set by PlayerController)
var input_direction: Vector3 = Vector3.ZERO
var input_rotation: float = 0.0

func _init_stats() -> void:
	super._init_stats()
	# Initialize Tank-specific stats
	turret_speed = Stat.new(base_turret_speed)

func get_gravity_vector() -> Vector3:
	return Vector3(0, -float(ProjectSettings.get_setting("physics/3d/default_gravity")), 0)

func _physics_process(delta: float) -> void:
	super._physics_process(delta) # Runs auto-aim targeting
	
	_handle_turret(delta)
	_handle_movement(delta)

func _handle_turret(delta: float) -> void:
	if not tank_turret_mesh:
		return
		
	var target_pos: Vector3 = Vector3.ZERO
	
	if is_instance_valid(auto_aim_target):
		target_pos = auto_aim_target.global_position
	else:
		# If no target, maybe look forward?
		# For now, stay as is or look forward
		target_pos = global_position - global_transform.basis.z * 10.0
	
	# Adjust Y to turret level
	target_pos.y = tank_turret_mesh.global_position.y
	
	# Turret Rotation logic
	var target_xform: Transform3D = tank_turret_mesh.global_transform.looking_at(target_pos)
	var target_angle: float = target_xform.basis.get_euler().y
	var current_angle: float = tank_turret_mesh.global_rotation.y
	
	var angle_diff: float = wrapf(target_angle - current_angle, -PI, PI)
	var t_speed: float = turret_speed.get_value()
	var rotation_change: float = clamp(angle_diff, -t_speed * delta, t_speed * delta)
	
	tank_turret_mesh.global_rotation.y += rotation_change
	
	# Sync Muzzle rotation to turret if needed
	# (Muzzle is usually child of turret, so it rotates with it automatically)

func _handle_movement(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity_vector() * delta
		
	# Rotation Body
	if input_rotation != 0.0:
		if tank_body_mesh:
			tank_body_mesh.rotate_y(input_rotation * rotation_speed.get_value() * delta)
			# Sync collision/hitbox if they are separate children and not children of mesh
			# Assuming CollisionShape is sibling, we might need to rotate it too or just rotate the whole CharacterBody?
			# In player.gd, the user was rotating the MESHES, not the CharacterBody itself.
			# Let's align with player.gd:
			# tank_body_mesh.rotate_y(...)
			# tank_collision.rotation.y = tank_body_mesh.rotation.y
			# But rotating the mesh only means Velocity is not aligned with body.
			# Re-reading player.gd:
			# "var direction: Vector3 = - tank_body_mesh.global_transform.basis.z * input_dir"
			# So the Tank acts like a car.
			pass

	# Movement
	if input_direction.length() > 0:
		# We use the TANK BODY's forward direction
		var move_speed: float = speed.get_value()
		# Determine forward vector from Body Mesh
		var forward = -tank_body_mesh.global_transform.basis.z
		
		# For tank controls (W=Forward, S=Back), input_direction.z will be non-zero
		# input_direction is passed from Controller.
		# If we assume "Directional" control (Joystick/WASD absolute), we move in that direction.
		# But the User said "Direct Control" for main vehicle. 
		# "Standard keys" for Tank are Rotate Left/Right, Move Fwd/Back.
		# Let's assume input_rotation handles the turning, diff from input_direction.
		
		# If using "Tank Controls" (Rotate + Fwd/Back):
		if abs(input_direction.z) > 0:
			var direction = forward * input_direction.z
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
	else:
		var move_speed: float = speed.get_value()
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()
