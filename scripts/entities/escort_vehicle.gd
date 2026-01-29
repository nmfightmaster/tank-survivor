class_name EscortVehicle
extends CharacterBody3D

signal destroyed

enum State { FOLLOW, ATTACK, DISABLED }

@export var data: EscortData # Assigned on spawn

# References
var manager: Node3D
# We assume components are children, or assigned
@export var weapon_component: WeaponComponent
@export var health_component: HealthComponent

# Movement Params (Can be overridden by data)
var speed_stat: Stat
var acceleration: float = 20.0
var rotation_speed: float = 5.0
var movement_mode: int = 0 # Default GROUND
var hover_height: float = 2.0
var seek_weight: float = 1.0
var separate_weight: float = 2.0
var personal_space: float = 3.0

var current_state: State = State.FOLLOW
var target_entity: Node3D = null

func _ready() -> void:
	speed_stat = Stat.new(10.0)
	
	if not health_component:
		health_component = get_node_or_null("HealthComponent")
	if not weapon_component:
		weapon_component = get_node_or_null("WeaponComponent")
		
	if health_component:
		health_component.died.connect(_on_death)
		
	# Apply Data if available
	if data:
		apply_data(data)

func apply_data(escort_data: EscortData) -> void:
	speed_stat.base_value = escort_data.speed
	acceleration = escort_data.acceleration
	rotation_speed = escort_data.rotation_speed
	movement_mode = escort_data.movement_mode
	hover_height = escort_data.hover_height
	seek_weight = escort_data.seek_weight
	separate_weight = escort_data.separate_weight
	personal_space = escort_data.personal_space
	
	if health_component:
		health_component.max_health_stat.base_value = escort_data.max_health
		health_component.current_health = escort_data.max_health # Heal to full
		
	if weapon_component:
		weapon_component.projectile_data = escort_data.weapon_projectile_data
		weapon_component.projectile_scene = escort_data.weapon_projectile_scene
		weapon_component.range_val = escort_data.weapon_range
		weapon_component.fire_rate_stat.base_value = escort_data.weapon_fire_rate

func _physics_process(delta: float) -> void:
	if current_state == State.DISABLED:
		return
		
	var steering_force: Vector3 = Vector3.ZERO
	
	# Priority 1: Separation (Avoid crowding)
	var separation: Vector3 = _calculate_separation()
	steering_force += separation * separate_weight
	
	# Priority 2: Seek (Target or Leader)
	var seek: Vector3 = _calculate_seek()
	steering_force += seek * seek_weight
	
	# Apply steering to velocity
	# We want to move towards target velocity
	var desired_velocity = steering_force.normalized() * speed_stat.get_value()
	
	# If no steering force (balanced or idle), slow down
	if steering_force.length_squared() < 0.01:
		desired_velocity = Vector3.ZERO
		
	# Smoothly interpolate velocity
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	
	# Apply Gravity (Only if Ground Unit)
	if movement_mode == EscortData.MovementMode.GROUND:
		if not is_on_floor():
			velocity += Vector3(0, -9.8, 0) * delta
	elif movement_mode == EscortData.MovementMode.AIR:
		# Hover logic: Spring-like force to maintain height relative to floor (or just absolute if no floor)
		var desired_y = hover_height
		# If Raycast or ground check available, use that. For now, assume y=0 is ground.
		if is_instance_valid(GameManager.player):
			# Match player's Y plus offset? Or just use global height.
			# Let's assume ground is at y=0 or we trace down.
			# Simple approach: Lerp Y to hover_height
			var current_y = global_position.y
			var y_diff = desired_y - current_y
			velocity.y = y_diff * 5.0 # Simple P-controller for height
		
	move_and_slide()
	
	# Rotation: Look at movement direction
	if velocity.length() > 0.1:
		var look_target = global_position + Vector3(velocity.x, 0, velocity.z)
		
		# Smooth rotation
		var target_xform = global_transform.looking_at(look_target, Vector3.UP)
		var current_quat = global_transform.basis.get_rotation_quaternion()
		var target_quat = target_xform.basis.get_rotation_quaternion()
		
		global_transform.basis = Basis(current_quat.slerp(target_quat, rotation_speed * delta))

	_handle_state_logic()

func _calculate_seek() -> Vector3:
	var target_pos: Vector3 = Vector3.ZERO
	
	if current_state == State.FOLLOW:
		if GameManager.player:
			target_pos = GameManager.player.global_position
			
			# Orbit / Offset logic? For now, just seek player position but stop at a distance
			var dist = global_position.distance_to(target_pos)
			if dist < 5.0: # Stop close to player
				return Vector3.ZERO
	
	elif current_state == State.ATTACK:
		if is_instance_valid(target_entity):
			target_pos = target_entity.global_position
			var dist = global_position.distance_to(target_pos)
			
			# If existing weapon, keep within range but don't hug
			if weapon_component and dist < weapon_component.range_val * 0.8:
				return Vector3.ZERO # existing range is good
			
	if target_pos != Vector3.ZERO:
		return (target_pos - global_position).normalized()
		
	return Vector3.ZERO

func _calculate_separation() -> Vector3:
	var force: Vector3 = Vector3.ZERO
	var neighbors = get_tree().get_nodes_in_group("flotilla_members")
	var count: int = 0
	
	for neighbor in neighbors:
		if neighbor == self or not (neighbor is Node3D):
			continue
			
		var dist_sq = global_position.distance_squared_to(neighbor.global_position)
		var space_sq = personal_space * personal_space
		
		if dist_sq < space_sq and dist_sq > 0.001:
			# Vector pointing AWAY from neighbor
			var push: Vector3 = global_position - neighbor.global_position
			# Weight by inverse distance (closer = stronger push)
			push = push.normalized() * (personal_space / sqrt(dist_sq))
			force += push
			count += 1
			
	if count > 0:
		force /= count
		
	return force

func _handle_state_logic() -> void:
	# Transition Logic
	if current_state == State.FOLLOW:
		# Check for enemies to engage
		if weapon_component:
			var potential_target = weapon_component.get_nearest_target()
			if potential_target:
				target_entity = potential_target
				current_state = State.ATTACK
				
	elif current_state == State.ATTACK:
		if not is_instance_valid(target_entity):
			current_state = State.FOLLOW
		else:
			# Check if too far from player?
			if GameManager.player:
				var dist_to_player = global_position.distance_to(GameManager.player.global_position)
				if dist_to_player > 30.0: # Leash distance
					target_entity = null
					current_state = State.FOLLOW

func _on_death() -> void:
	destroyed.emit()
	queue_free()
