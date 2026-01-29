class_name SquadMemberController
extends Node

## Controls a vehicle using BOID swarm logic.
## Handles formation with other squad members and following the leader.

@export var controlled_vehicle: VehicleBase

# BOID Weights - Tunable
@export_group("BOID Weights")
@export var separation_weight: float = 2.0
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var seek_weight: float = 1.5
@export var avoid_weight: float = 3.0

@export_group("BOID Radii")
@export var neighbor_radius: float = 10.0
@export var separation_radius: float = 3.0
@export var avoid_radius: float = 8.0

# References
var leader: Node3D

func _ready() -> void:
	leader = GameManager.main_vehicle
	
func _physics_process(delta: float) -> void:
	if not is_instance_valid(controlled_vehicle):
		if get_parent() is VehicleBase:
			controlled_vehicle = get_parent()
		else:
			return
		
	# Update leader if needed
	if not is_instance_valid(leader):
		leader = GameManager.main_vehicle
		
	var steering: Vector3 = _calculate_flocking()
	
	_apply_movement(steering, delta)

func _calculate_flocking() -> Vector3:
	var separation: Vector3 = Vector3.ZERO
	var alignment: Vector3 = Vector3.ZERO
	var cohesion: Vector3 = Vector3.ZERO
	var seek: Vector3 = Vector3.ZERO
	var avoid: Vector3 = Vector3.ZERO
	
	var neighbors: Array = _get_neighbors()
	var enemies: Array = _get_nearby_enemies()
	
	# 1. Separation / Alignment / Cohesion
	var neighbor_count: int = 0
	var avg_pos: Vector3 = Vector3.ZERO
	var avg_vel: Vector3 = Vector3.ZERO
	
	for neighbor in neighbors:
		if neighbor == controlled_vehicle: continue
		if not is_instance_valid(neighbor): continue
		
		var dist = controlled_vehicle.global_position.distance_to(neighbor.global_position)
		if dist > neighbor_radius: continue
		
		# Separation
		if dist < separation_radius:
			var diff = controlled_vehicle.global_position - neighbor.global_position
			separation += diff.normalized() / max(dist, 0.1)
			
		# Alignment / Cohesion prep
		avg_pos += neighbor.global_position
		avg_vel += neighbor.velocity
		neighbor_count += 1
		
	if neighbor_count > 0:
		avg_pos /= neighbor_count
		avg_vel /= neighbor_count
		
		# Cohesion: Steer towards average position
		var direction_to_center = controlled_vehicle.global_position.direction_to(avg_pos)
		cohesion = direction_to_center
		
		# Alignment: Steer towards average velocity
		alignment = avg_vel.normalized()
		
	# 2. Seek Leader
	if is_instance_valid(leader):
		var dist_to_leader = controlled_vehicle.global_position.distance_to(leader.global_position)
		if dist_to_leader > 5.0: # Stop crowded seeking if close
			seek = controlled_vehicle.global_position.direction_to(leader.global_position)
	
	# 3. Avoid Enemies
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		var dist = controlled_vehicle.global_position.distance_to(enemy.global_position)
		if dist < avoid_radius:
			var diff = controlled_vehicle.global_position - enemy.global_position
			avoid += diff.normalized() * (1.0 - (dist / avoid_radius)) # Stronger when closer

	# Combine
	var total_force = (separation * separation_weight + 
					  alignment * alignment_weight + 
					  cohesion * cohesion_weight + 
					  seek * seek_weight + 
					  avoid * avoid_weight)
					
	return total_force.normalized()

func _get_neighbors() -> Array:
	return GameManager.squadron_vehicles

func _get_nearby_enemies() -> Array:
	# Optimization: Only check every few frames or use spatial query?
	# For now, simplistic approach
	return get_tree().get_nodes_in_group("enemy")

func _apply_movement(direction_vector: Vector3, _delta: float) -> void:
	# GENERIC INPUT INTERFACE
	
	# Case 1: TankVehicle (Needs Rotation + Forward)
	if "input_rotation" in controlled_vehicle and "tank_body_mesh" in controlled_vehicle:
		if direction_vector.length_squared() < 0.01:
			controlled_vehicle.input_direction = Vector3.ZERO
			controlled_vehicle.input_rotation = 0.0
			return

		var current_forward = -controlled_vehicle.tank_body_mesh.global_transform.basis.z
		var angle_to = current_forward.signed_angle_to(direction_vector, Vector3.UP)
		
		# Turn
		var turn_intent = clamp(angle_to * 2.0, -1.0, 1.0)
		controlled_vehicle.input_rotation = turn_intent
		
		# Move if facing roughly correct
		if abs(angle_to) < PI / 2:
			controlled_vehicle.input_direction = Vector3(0, 0, -1) # Forward
		else:
			controlled_vehicle.input_direction = Vector3.ZERO # Stop to turn
			
	# Case 2: Generic Directional Vehicle (Drone, etc)
	elif "input_direction" in controlled_vehicle:
		controlled_vehicle.input_direction = direction_vector

