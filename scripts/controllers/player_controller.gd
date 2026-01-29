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
