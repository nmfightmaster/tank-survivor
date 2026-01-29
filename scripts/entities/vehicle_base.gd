class_name VehicleBase
extends CharacterBody3D

## Base class for all controlled vehicles (Player Main + Escorts).
## Handles Stats, Shooting, Auto-Aim, and Health.

signal died

@export_group("Base Stats")
@export var base_speed: float = 10.0
@export var base_rotation_speed: float = 2.0
@export var base_damage: float = 10.0
@export var base_fire_rate: float = 0.5
@export var base_projectile_speed: float = 50.0
@export var base_lifesteal: float = 0.0
@export var base_armor: float = 0.0
@export var base_max_health: float = 100.0

@export_group("Combat References")
@export var bullet_scene: PackedScene
@export var muzzle: Marker3D

# Actual Stat Objects
var speed: Stat
var rotation_speed: Stat
var damage: Stat
var fire_rate: Stat
var projectile_speed: Stat
var lifesteal: Stat
var armor: Stat
var max_health: Stat

var current_health: float

var enemies_touching: int = 0
var damage_timer: Timer
var animation_player: AnimationPlayer

# Projectile Behaviors (Local)
var active_projectile_behaviors: Array[ProjectileBehavior] = []

# Aiming
var auto_aim_target: Node3D = null
var shoot_timer: Timer

func _ready() -> void:
	_init_stats()
	_init_timers()
	
	# Register with GameManager (Global scaling application happens here)
	if GameManager.has_method("register_vehicle"):
		GameManager.register_vehicle(self)

func _init_stats() -> void:
	speed = Stat.new(base_speed)
	rotation_speed = Stat.new(base_rotation_speed)
	damage = Stat.new(base_damage)
	fire_rate = Stat.new(base_fire_rate)
	projectile_speed = Stat.new(base_projectile_speed)
	lifesteal = Stat.new(base_lifesteal)
	armor = Stat.new(base_armor)
	max_health = Stat.new(base_max_health)
	
	current_health = max_health.get_value()

func _init_timers() -> void:
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)
	
	# Kickoff shooting
	shoot_timer.start(1.0 / fire_rate.get_value())

	# Find helpers
	damage_timer = get_node_or_null("Hitbox/DamageTimer")
	animation_player = get_node_or_null("AnimationPlayer")

func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		enemies_touching += 1
		if damage_timer and damage_timer.is_stopped():
			take_damage(10.0) # Default contact damage
			damage_timer.start()

func _on_hitbox_body_exited(body: Node) -> void:
	if body.is_in_group("enemy"):
		enemies_touching -= 1
		if enemies_touching <= 0:
			enemies_touching = 0
			if damage_timer: damage_timer.stop()

func _on_damage_timer_timeout() -> void:
	take_damage(10.0)


func get_nearest_enemy() -> Node3D:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return null
		
	var nearest: Node3D = null
	var min_dist: float = INF
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is Node3D:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = enemy
	
	return nearest

func _physics_process(_delta: float) -> void:
	# Auto-Aim Logic: Always look for target
	if not is_instance_valid(auto_aim_target):
		auto_aim_target = get_nearest_enemy()
	
	# If we have a target but it moves out of range or dies, we might want to re-evaluate,
	# but for now, we just check validity.

func _on_shoot_timer_timeout() -> void:
	shoot()

func shoot() -> void:
	if not bullet_scene or not muzzle:
		return
		
	# Refresh target if needed
	if not is_instance_valid(auto_aim_target):
		auto_aim_target = get_nearest_enemy()
	
	# Only fire if we have a target? Or fire blindly forward?
	# "Vampire Survivors" usually fires at nearest, or random if none.
	# For now, we fire even if no target, just straight ahead (muzzle direction).
	
	var bullet: Node3D = bullet_scene.instantiate()
	bullet.position = muzzle.global_position
	bullet.rotation = muzzle.global_rotation # Turret rotation handles aiming direction
	
	# Apply Stats
	if "damage" in bullet: bullet.damage = damage.get_value()
	if "speed" in bullet: bullet.speed = projectile_speed.get_value()
	
	# Inject Behaviors
	if bullet is ProjectileBase:
		bullet.owner_vehicle = self
		for behavior in active_projectile_behaviors:
			bullet.add_behavior(behavior.duplicate())
	
	get_tree().current_scene.add_child(bullet)
	
	# Reset Timer
	shoot_timer.wait_time = 1.0 / max(0.1, fire_rate.get_value())
	shoot_timer.start()

func take_damage(amount: float) -> void:
	if animation_player:
		animation_player.play("take_damage")
		
	var armor_val = armor.get_value()
	var reduction_mult = clamp(1.0 - (armor_val / 100.0), 0.0, 1.0)
	var final_damage = amount * reduction_mult
	
	current_health -= final_damage
	print(name, " took ", final_damage, " damage. Health: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	died.emit()
	queue_free()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health.get_value())

# Apply a stat modifier to this specific vehicle
func apply_stat_modifier(stat_name: String, modifier: StatModifier) -> void:
	var stat_obj = get(stat_name)
	if stat_obj and stat_obj is Stat:
		stat_obj.add_modifier(modifier)
