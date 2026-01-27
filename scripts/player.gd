extends CharacterBody3D

# @export var speed: float = 10.0
# @export var rotation_speed: float = 2.0
# @export var turret_traversal_speed: float = 4.0
@export var tank_body_mesh: MeshInstance3D
@export var tank_turret_mesh: MeshInstance3D
@export var tank_collision: CollisionShape3D
@export var tank_hitbox: Area3D
@export var bullet_scene: PackedScene

@onready var muzzle: Marker3D = $Turret/Barrel/Muzzle
@onready var shoot_timer: Timer = $ShootTimer
@onready var damage_timer: Timer = $Hitbox/DamageTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var engine_sound: AudioStreamPlayer3D = $EngineSound
@onready var reload_sound: AudioStreamPlayer3D = $ReloadSound

var enemies_touching: int = 0
var is_auto_aiming: bool = false
var auto_aim_target: Node3D = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_aim"):
		is_auto_aiming = !is_auto_aiming
		print("Auto aim: ", is_auto_aiming)

func _ready() -> void:
	GameManager.player = self
	GameManager.player_position = global_position
	# Initialize shoot timer based on fire rate
	shoot_timer.wait_time = 1.0 / GameManager.player_fire_rate.get_value()

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		enemies_touching += 1
		if damage_timer.is_stopped():
			take_damage()
			damage_timer.start()

func _on_hitbox_body_exited(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		enemies_touching -= 1
		if enemies_touching <= 0:
			enemies_touching = 0
			damage_timer.stop()

func _on_damage_timer_timeout() -> void:
	take_damage()

func take_damage() -> void:
	animation_player.play("take_damage")
	GameManager.player_health -= 10
	print("Player health: ", GameManager.player_health)

	if GameManager.player_health <= 0:
		GameManager.player_health = 0
		die()

func die() -> void:
	print("Player died!")
	GameManager.reset()
	get_tree().reload_current_scene()
	enemies_touching = 0

func get_mouse_world_position():
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	
	# 1. Define the start and end of our 'laser beam'
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 2000 # 2000 is the 'range'
	
	# 2. Ask the physics world what the laser hits
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 1 # Only hit Layer 1 (the floor)
	query.exclude = [self]
	
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	# 3. If the laser hit the floor, return that 3D coordinate
	if result:
		return result.position
	return Vector3.ZERO

func get_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return null
	var nearest_enemy = null
	var nearest_distance = INF
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	return nearest_enemy

func _on_shoot_timer_timeout() -> void:
	shoot()

func shoot() -> void:
    # Refresh target on fire
	if is_auto_aiming:
		auto_aim_target = get_nearest_enemy()

	var bullet = bullet_scene.instantiate()
	bullet.position = muzzle.global_position
	bullet.rotation = muzzle.global_rotation
	bullet.damage = GameManager.player_damage.get_value()
	bullet.speed = GameManager.player_projectile_speed.get_value()
	
	# Inject behaviors
	if bullet is ProjectileBase:
		for behavior in GameManager.active_projectile_behaviors:
			bullet.add_behavior(behavior.duplicate())
			
	get_tree().current_scene.add_child(bullet)
	
	# Update timer in case fire rate changed
	shoot_timer.wait_time = 1.0 / GameManager.player_fire_rate.get_value()
	shoot_timer.start()
	
	await get_tree().create_timer(0.5).timeout
	reload_sound.play()

func _physics_process(delta: float) -> void:
	GameManager.player_position = global_position

	var target_pos = Vector3.ZERO

	# Optimization: We only check for a new target if:
	# 1. We don't have one
	# 2. The current one is invalid (died/freed)
	# 3. We just fired (handled in shoot(), but we check validity here)
	
	if !is_auto_aiming:
		target_pos = get_mouse_world_position()
	else:
		if not is_instance_valid(auto_aim_target):
			auto_aim_target = get_nearest_enemy()
			
		if auto_aim_target:
			target_pos = auto_aim_target.global_position
	
	if target_pos != Vector3.ZERO:
		target_pos.y = tank_turret_mesh.global_position.y
		

		# Calculate the target direction
		# Using global_transform.looking_at handles the math for us
		var target_xform = tank_turret_mesh.global_transform.looking_at(target_pos)
		var target_angle = target_xform.basis.get_euler().y
		
		# Get current angle
		var current_angle = tank_turret_mesh.global_rotation.y
		
		# Calculate the difference, ensuring consistent wrapping (-PI to PI)
		# wrapf(diff, -PI, PI) ensures we take the shortest path
		var angle_diff = wrapf(target_angle - current_angle, -PI, PI)
		
		# Clamp the movement to our speed limits
		# This creates the "constant speed" traversal effect
		var turret_speed = GameManager.player_turret_speed.get_value()
		var rotation_change = clamp(angle_diff, -turret_speed * delta, turret_speed * delta)
		
		# Apply rotation
		tank_turret_mesh.global_rotation.y += rotation_change
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle rotation
	var rotation_direction := Input.get_axis("turn_clockwise", "turn_counter_clockwise")
	if rotation_direction:
		tank_body_mesh.rotate_y(rotation_direction * GameManager.player_rotation_speed.get_value() * delta)
		if tank_collision:
			tank_collision.rotation.y = tank_body_mesh.rotation.y
		if tank_hitbox:
			tank_hitbox.rotation.y = tank_body_mesh.rotation.y

	# Handle movement
	var input_dir := Input.get_axis("move_backward", "move_forward")
	if input_dir:
		# Move in the direction the tank body is facing
		var direction = - tank_body_mesh.global_transform.basis.z * input_dir
		var pd_speed = GameManager.player_speed.get_value()
		velocity.x = direction.x * pd_speed
		velocity.z = direction.z * pd_speed
	else:
		var pd_speed = GameManager.player_speed.get_value()
		velocity.x = move_toward(velocity.x, 0, pd_speed)
		velocity.z = move_toward(velocity.z, 0, pd_speed)

	if input_dir or rotation_direction:
		if not engine_sound.playing:
			engine_sound.play()
	else:
		if engine_sound.playing:
			engine_sound.stop()

	move_and_slide()
