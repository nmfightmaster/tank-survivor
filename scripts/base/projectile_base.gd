class_name ProjectileBase
extends Area3D

## Base class for all projectiles.
## 
## Handles movement, collision detection, lifetime management, and behavior execution.
## Uses ProjectileData resource for configuration and ProjectileBehavior resources for logic.

signal hit_enemy(enemy: Node3D, context: Dictionary)
signal hit_wall(context: Dictionary)
signal expired()
signal destroyed()

@export var projectile_data: ProjectileData

var speed: float = 50.0
var damage: float = 10.0
var active_behaviors: Array[ProjectileBehavior] = []
var lifetime_timer: Timer

@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")

var fire_sound: AudioStreamPlayer3D
var explosion_sound: AudioStreamPlayer3D

func _ready() -> void:
	# Setup Audio
	_setup_audio()

	if projectile_data:
		speed = projectile_data.speed
		damage = damage * projectile_data.damage_multiplier
		if projectile_data.projectile_model:
			# Remove defaults if they exist
			if mesh_instance: 
				mesh_instance.queue_free()
				mesh_instance = null # Clear reference
			if has_node("CollisionShape3D"): 
				get_node("CollisionShape3D").queue_free()
			
			# Instantiate new model
			var model: Node = projectile_data.projectile_model.instantiate()
			add_child(model)
			
			# Auto-Configuration: Find and Reparent Collision Shapes
			_reparent_collision_shapes(model)

	# Setup lifetime
	lifetime_timer = Timer.new()
	lifetime_timer.one_shot = true
	lifetime_timer.wait_time = projectile_data.lifetime if projectile_data else 3.0
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	add_child(lifetime_timer)
	lifetime_timer.start()

	# Initialize default behaviors
	if projectile_data:
		for behavior_res in projectile_data.default_behaviors:
			add_behavior(behavior_res.duplicate())
			
	# Play Fire Sound
	if fire_sound and fire_sound.stream:
		fire_sound.play()
		
	# Notify behaviors
	for behavior in active_behaviors:
		behavior.on_ready(self)

func _setup_audio() -> void:
	# Fire Sound
	if has_node("FireSound"):
		fire_sound = $FireSound
	else:
		fire_sound = AudioStreamPlayer3D.new()
		fire_sound.name = "FireSound"
		add_child(fire_sound)
	
	# Explosion Sound
	if has_node("ExplosionSound"):
		explosion_sound = $ExplosionSound
	else:
		explosion_sound = AudioStreamPlayer3D.new()
		explosion_sound.name = "ExplosionSound"
		add_child(explosion_sound)

	# Apply streams from data if available
	if projectile_data:
		if projectile_data.fire_sound:
			fire_sound.stream = projectile_data.fire_sound
		if projectile_data.hit_sound:
			explosion_sound.stream = projectile_data.hit_sound

func _reparent_collision_shapes(node: Node) -> void:
	# If the node itself is a collision shape, reparent it
	if node is CollisionShape3D or node is CollisionPolygon3D:
		var global_xform: Transform3D = node.global_transform
		
		# Remove from current parent
		node.get_parent().remove_child(node)
		
		# Add to ProjectileBase
		add_child(node)
		
		# Restore position
		node.global_transform = global_xform
		return 

	# Recursively check children
	# Iterate backwards to safely handle potential removals (though we reparent, so children list changes)
	# Using duplicate of children list is safer if modifying hierarchy
	var children: Array[Node] = node.get_children()
	for child in children:
		_reparent_collision_shapes(child)

func _physics_process(delta: float) -> void:
	position -= transform.basis.z * speed * delta
	
	for behavior in active_behaviors:
		behavior.on_physics_process(self, delta)

func _on_body_entered(body: Node3D) -> void:
	var context: Dictionary = {
		"collider": body,
		"position": global_position,
		"normal": transform.basis.z 
	}
	
	if body.is_in_group("enemy"):
		# Deal damage
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
		hit_enemy.emit(body, context)
		for behavior in active_behaviors:
			behavior.on_hit_enemy(self, context)
	else:
		# Hit wall/obstacle
		hit_wall.emit(context)
		for behavior in active_behaviors:
			behavior.on_hit_wall(self, context)

	_handle_collision_result(body)

func _handle_collision_result(_body: Node3D) -> void:
	# Check if any behavior has cancelled destruction (e.g., Ricochet)
	if get_meta("cancel_destroy", false):
		set_meta("cancel_destroy", false) # Reset for next time
		return
		
	destroy()

func destroy() -> void:
	destroyed.emit()
	for behavior in active_behaviors:
		behavior.on_destroyed(self)
	
	if explosion_sound and explosion_sound.stream:
		explosion_sound.play()
		if mesh_instance:
			mesh_instance.visible = false
		set_deferred("monitoring", false)
		await explosion_sound.finished
	
	queue_free()

func _on_lifetime_timeout() -> void:
	expired.emit()
	for behavior in active_behaviors:
		behavior.on_expired(self)
	destroy()

func add_behavior(behavior: ProjectileBehavior) -> void:
	active_behaviors.append(behavior)

func play_sound(stream: AudioStream, pitch_randomness: float = 0.1) -> void:
	if not stream: return
	
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_randomness, pitch_randomness)
	get_tree().current_scene.add_child(player)
	player.global_position = global_position
	player.play()
	
	# Auto cleanup
	player.finished.connect(player.queue_free)
