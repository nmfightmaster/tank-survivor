class_name PlayerController
extends Node

## Handles User Input and commands the controlled Vehicle.
## Replaces the input logic previously inside the Player class.

@export var controlled_vehicle: TankVehicle

func _ready() -> void:
	# If we have a vehicle assigned in inspector, use it.
	pass

func _process(delta: float) -> void:
	if not is_instance_valid(controlled_vehicle):
		return
		
	# Handle Rotation Input (A/D or Left/Right)
	var rotation_input: float = Input.get_axis("turn_clockwise", "turn_counter_clockwise")
	controlled_vehicle.input_rotation = rotation_input
	
	# Handle Movement Input (W/S or Up/Down)
	# NOTE: We map "move_forward" to negative Z (standard Godot forward)
	# but Input.get_axis returns -1 for min, 1 for max.
	# move_backward (S) -> +1, move_forward (W) -> -1
	# In TankVehicle we check input_direction.z.
	# If input is W (-1), we want to move Forward.
	var move_input: float = Input.get_axis("move_backward", "move_forward")
	
	# Pass as Z component for "Forward/Back" axis
	controlled_vehicle.input_direction = Vector3(0, 0, move_input) 

	# DEBUG: Spawn Squad Member
	if Input.is_action_just_pressed("spawn_vehicle"):
		_debug_spawn_squad_member()

func _debug_spawn_squad_member() -> void:
	# Debounce (simple hack, better to use "is_action_just_pressed" but we don't have an action)
	# For now, relying on user tapping quickly or adding a cooldown
	if get_tree().paused: return
	
	var scene = load("res://scenes/entities/TankVehicle.tscn")
	var new_tank = scene.instantiate()
	get_tree().current_scene.add_child(new_tank)
	
	if is_instance_valid(controlled_vehicle):
		var offset = Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		new_tank.global_position = controlled_vehicle.global_position + offset
	else:
		new_tank.global_position = Vector3(0, 1, 0)
		
	# Add some initial random rotation
	new_tank.rotation.y = randf() * TAU
	
	# Wait a bit to prevent spam
	await get_tree().create_timer(0.5).timeout 
