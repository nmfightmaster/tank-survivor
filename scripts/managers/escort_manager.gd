class_name EscortManager
extends Node3D

@export var active_escorts: Array[EscortVehicle] = []

func spawn_unit(resource: EscortData, spawn_pos: Vector3 = Vector3.ZERO) -> void:
	if not resource or not resource.scene:
		push_warning("EscortManager: Cannot spawn unit, missing resource or scene.")
		return
		
	var instance = resource.scene.instantiate()
	if not instance is EscortVehicle:
		push_error("EscortManager: Resource scene is not an EscortVehicle!")
		instance.queue_free()
		return
		
	# Setup Instance
	instance.max_slides = 4 
	instance.data = resource # Pass resource so it can configure itself in _ready
	
	# Add to Scene
	get_tree().current_scene.add_child(instance)
	
	# Position (default to around player if not specified)
	if spawn_pos == Vector3.ZERO and GameManager.player:
		# Random offset behind player
		var offset = Vector3(randf_range(-5, 5), 0, randf_range(2, 6))
		instance.global_position = GameManager.player.global_position - offset
	else:
		instance.global_position = spawn_pos
		
	instance.add_to_group("flotilla_members")
	instance.manager = self
	
	# Track
	active_escorts.append(instance)
	instance.destroyed.connect(_on_unit_destroyed.bind(instance))
	
	print("Spawned Escort Unit. Active count: ", active_escorts.size())

func _on_unit_destroyed(unit: EscortVehicle) -> void:
	if unit in active_escorts:
		active_escorts.erase(unit)
	print("Escort Unit Destroyed. Active count: ", active_escorts.size())
