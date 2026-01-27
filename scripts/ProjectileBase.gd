class_name ProjectileBase
extends Area3D

signal hit_enemy(enemy, context)
signal hit_wall(context)
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
			var model = projectile_data.projectile_model.instantiate()
			add_child(model)
			
			# Auto-Configuration: Find and Reparent Collision Shapes
			# Area3D requires CollisionShape3D or CollisionPolygon3D to be immediate children or 
			# properly configured. Godot's physics engine is strict about this.
			# We will search the model for shapes and reparent them to Self (the Area3D).
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

func _reparent_collision_shapes(node: Node):
	# If the node itself is a collision shape, reparent it
	if node is CollisionShape3D or node is CollisionPolygon3D:
		# We need to duplicate or reparent. Reparenting is safer for preventing duplicates.
		# But we must preserve the global transform.
		var global_xform = node.global_transform
		
		# Remove from current parent
		node.get_parent().remove_child(node)
		
		# Add to ProjectileBase
		add_child(node)
		
		# Restore position (relative to ProjectileBase, which is at (0,0,0) of itself)
		# Note: 'node.global_transform' might be tricky if we haven't added 'model' to tree yet usage.
		# Check: we did 'add_child(model)' above. So global_transform is valid.
		node.global_transform = global_xform
		
		print("ProjectileBase: Reparented collision shape ", node.name)
		return # Don't look inside a shape for more shapes (unlikely)

	# Recursively check children
	# We iterate backwards in case we remove children (though we remove 'node' not 'child' here? No wait)
	# If we remove 'child' from 'node', we should iterate safely.
	var children = node.get_children()
	for child in children:
		_reparent_collision_shapes(child)

		# Initialize default behaviors
		for behavior_res in projectile_data.default_behaviors:
			add_behavior(behavior_res.duplicate())
			
	# Setup lifetime
	lifetime_timer = Timer.new()
	lifetime_timer.one_shot = true
	lifetime_timer.wait_time = projectile_data.lifetime if projectile_data else 3.0
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	add_child(lifetime_timer)
	lifetime_timer.start()

	if fire_sound:
		# Override stream if provided in data
		if projectile_data and projectile_data.fire_sound:
			fire_sound.stream = projectile_data.fire_sound
		fire_sound.play()
		
	if explosion_sound and projectile_data and projectile_data.hit_sound:
		explosion_sound.stream = projectile_data.hit_sound
		
	# Notify behaviors of readiness
	for behavior in active_behaviors:
		behavior.on_ready(self)

func _physics_process(delta: float) -> void:
	position -= transform.basis.z * speed * delta
	
	for behavior in active_behaviors:
		behavior.on_physics_process(self, delta)

func _on_body_entered(body: Node3D) -> void:
	var context = {
		"collider": body,
		"position": global_position,
		"normal": transform.basis.z # Approx normal for now
	}
	
	if body.is_in_group("enemy"):
		# Deal damage
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
		hit_enemy.emit(body, context)
		for behavior in active_behaviors:
			behavior.on_hit_enemy(self, context)
			
		# Default destroy on hit behavior (unless a behavior overrides this? 
		# For now, let's assume we destroy unless told otherwise, but Ricochet needs to prevent destroy.
		# Actually, Ricochet usually happens INSTEAD of destroy. 
		# A simple way is to check if any behavior handled the event.
		# But for this task, I'll just destroy if no behaviors are active, 
		# or perhaps I should expose a 'destroy_on_hit' flag that behaviors can toggle?
		# Better: behaviors like Ricochet will act, and if they DON'T recycle the projectile, we destroy.
		# Let's keep it simple: We destroy by default, but Ricochet will implement logic to NOT destroy.
		# Wait, if I call queue_free() here, Ricochet won't have time to work.
		# So I should delegate destruction to a method or a default behavior.
		# Let's create a 'should_destroy' flag.
		pass
		
	else:
		# Hit wall/obstacle
		hit_wall.emit(context)
		for behavior in active_behaviors:
			behavior.on_hit_wall(self, context)

	# Basic destruction logic:
	# If it's a wall, destroy. 
	# If it's an enemy, destroy (unless piercing/ricochet).
	# Since we want modularity, maybe the "Default Destroy" should be a behavior? 
	# Or strict logic: 
	# 1. Trigger events.
	# 2. If active_behaviors is empty or none prevent destruction, destroy?
	#
	# Let's trust the behaviors to manage 'queue_free' OR have a 'destroy()' method that behaviors call.
	# Actually, for Ricochet, we want to STOP it from destroying.
	# Let's make 'destroy()' a function we call, and behaviors can choose to Move/Rotate instead?
	# No, usually Ricochet happens ON contact.
	
	# Revised approach:
	# We always call destroy() at the end of collision, BUT 'destroy()' checks a flag 'pending_destruction'.
	# Or we assume destruction UNLESS a behavior explicitly says "I handled it, don't destroy".
	
	_handle_collision_result(body)

func _handle_collision_result(body):
	# This is a naive implementation. Real systems use event propagation.
	# For this simplified request:
	# If we have Ricochet, it should have already rotated the bullet and reset position/etc in 'on_hit'.
	# If we Ricochet, we DO NOT want to destroy.
	
	# We can check a flag 'cancel_destroy'
	if get_meta("cancel_destroy", false):
		set_meta("cancel_destroy", false) # Reset for next time
		return
		
	# Explosion behavior usually happens ON destroy.
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
	# If we are already running, trigger ready?
	# For now, assume behaviors added at spawn.

func play_sound(stream: AudioStream, pitch_randomness: float = 0.1) -> void:
	if not stream: return
	
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_randomness, pitch_randomness)
	# Copy global position so sound happens at impact point even if bullet moves away/dies
	get_tree().current_scene.add_child(player)
	player.global_position = global_position
	player.play()
	
	# Auto cleanup
	player.finished.connect(player.queue_free)

