extends Node

var player_position: Vector3 = Vector3.ZERO
var player_health: int = 100
var xp: int = 0
var xp_to_next_level: int = 100
var level: int = 1

# Tank Stats
# Movement
var player_speed: float = 10.0
var player_rotation_speed: float = 2.0
var player_turret_speed: float = 4.0

# Combat
var player_damage: float = 10.0
var player_fire_rate: float = 2.0 # Shots per second
var player_projectile_speed: float = 50.0

# Enemy Stats
var enemy_health: int = 20
var enemy_speed: float = 9.0
var enemy_spawn_rate: float = 0.5 # Mobs per second

func _ready() -> void:
	calculate_stats()

func calculate_stats() -> void:
	# Simple scaling logic: +10% per level for most stats
	var scaling_factor = 1.0 + (level - 1) * 0.1
	
	player_speed = 10.0 * scaling_factor
	player_rotation_speed = 2.0 * scaling_factor
	player_turret_speed = 4.0 * scaling_factor
	
	player_damage = 10.0 * scaling_factor
	# Fire rate might need diminishing returns or linear addition, keeping it linear for now
	player_fire_rate = 2.0 + (level - 1) * 0.2 

	player_projectile_speed = 50.0 * scaling_factor

	# Enemy scaling
	var enemy_scaling_factor = 1.0 + (level - 1) * 0.1
	enemy_health = int(20 * enemy_scaling_factor)
	enemy_speed = 9.0 * (1.0 + (level - 1) * 0.05) # Slower scaling for speed
	enemy_spawn_rate = 0.5 + (level - 1) * 0.2

func reset() -> void:
	xp = 0
	level = 1
	xp_to_next_level = 100
	player_health = 100
	calculate_stats()

func gain_xp(amount: int):
	xp += amount
	if xp >= xp_to_next_level:
		level += 1
		xp -= xp_to_next_level
		xp_to_next_level = int(xp_to_next_level * 1.2)
		
		calculate_stats()
		
		print("Level Up! New Level: ", level)
		print("Stats:")
		print("  Speed: ", player_speed)
		print("  Damage: ", player_damage)
		print("  Fire Rate: ", player_fire_rate)
		print("  Projectile Speed: ", player_projectile_speed)
		print("Enemy Stats:")
		print("  Health: ", enemy_health)
		print("  Speed: ", enemy_speed)
		print("  Spawn Rate: ", enemy_spawn_rate)

func get_player_stats_dict() -> Dictionary:
	var stats = {}
	var property_list = get_script().get_script_property_list()
	for p in property_list:
		if p.name.begins_with("player_") and p.name != "player_position":
			stats[p.name] = get(p.name)
	return stats