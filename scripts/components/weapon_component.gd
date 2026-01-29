class_name WeaponComponent
extends Node3D

@export var projectile_data: ProjectileData
@export var projectile_scene: PackedScene # The base scene to instantiate (e.g. ProjectileBase)
@export var range_val: float = 300.0

# Stats - initialized in _ready
var fire_rate_stat: Stat
var damage_multiplier_stat: Stat

var _fire_timer: Timer
var _target_group: String = "enemy"

func _ready() -> void:
	fire_rate_stat = Stat.new(1.0) # Default 1 shot per second
	damage_multiplier_stat = Stat.new(1.0)
	
	_fire_timer = Timer.new()
	add_child(_fire_timer)
	_fire_timer.one_shot = true

func _physics_process(_delta: float) -> void:
	if _fire_timer.is_stopped():
		var target = get_nearest_target()
		if target:
			fire(target.global_position)
			# Cooldown = 1.0 / fire_rate (shots per second)
			var rate = fire_rate_stat.get_value()
			if rate <= 0.001: rate = 0.001 # Prevent div by zero
			_fire_timer.start(1.0 / rate)

func fire(target_pos: Vector3) -> void:
	if not projectile_scene or not projectile_data:
		return
	
	var projectile = projectile_scene.instantiate()
	if not projectile is Node3D:
		projectile.queue_free()
		return
		
	# Setup Transform
	projectile.global_position = global_position
	projectile.look_at(target_pos, Vector3.UP)
	
	# Configure ProjectileBase
	if projectile.get("projectile_data") == null:
		# If it's the base class we expect
		projectile.set("projectile_data", projectile_data)
	
	# If the projectile scene already has the data exported and assigned, checking is good.
	# But we usually want to OVERRIDE it with our weapon's data.
	projectile.set("projectile_data", projectile_data)
	
	# Apply Stats
	if "damage" in projectile:
		projectile.damage *= damage_multiplier_stat.get_value()
	
	get_tree().current_scene.add_child(projectile)

func get_nearest_target() -> Node3D:
	var nodes = get_tree().get_nodes_in_group(_target_group)
	var nearest: Node3D = null
	var min_dist = range_val * range_val # Squared
	
	for node in nodes:
		if node is Node3D:
			var dist_sq = global_position.distance_squared_to(node.global_position)
			if dist_sq < min_dist:
				min_dist = dist_sq
				nearest = node
	return nearest
