extends Node

signal stats_changed

var player: CharacterBody3D
var player_position: Vector3 = Vector3.ZERO
var player_health: int = 100
var xp: int = 0
var xp_to_next_level: int = 100
var level: int = 1

# Tank Stats - initialized with base values
var player_speed: Stat
var player_rotation_speed: Stat
var player_turret_speed: Stat
var player_damage: Stat
var player_fire_rate: Stat
var player_projectile_speed: Stat

# Projectile Behaviors
var active_projectile_behaviors: Array[ProjectileBehavior] = []


# Enemy Stats
var enemy_health: float = 10.0
var enemy_speed: float = 20.0
var enemy_spawn_rate: float = 0.5 

# Upgrade Pool
@export var upgrade_pool: UpgradePool

func _ready() -> void:
	_init_stats()
	calculate_enemy_stats()

func _init_stats() -> void:
	player_speed = Stat.new(10.0)
	player_rotation_speed = Stat.new(2.0)
	player_turret_speed = Stat.new(4.0)
	player_damage = Stat.new(10.0)
	player_fire_rate = Stat.new(0.5) # Shots per second
	player_projectile_speed = Stat.new(50.0)
	
	# Emit change when any stat changes
	var stats = [player_speed, player_rotation_speed, player_turret_speed, player_damage, player_fire_rate, player_projectile_speed]
	for s in stats:
		s.value_changed.connect(func(_val): stats_changed.emit())

func calculate_enemy_stats() -> void:
	# Enemy scaling - kept simple and linear for now
	var enemy_scaling_factor = 1.0 + (level - 1) * 0.1
	enemy_health = int(20 * enemy_scaling_factor)
	enemy_speed = 9.0 * (1.0 + (level - 1) * 0.05)
	enemy_spawn_rate = 0.5 + (level - 1) * 0.2

func reset() -> void:
	xp = 0
	level = 1
	xp_to_next_level = 100
	player_health = 100
	_init_stats() # Reset stats to base
	active_projectile_behaviors.clear()
	calculate_enemy_stats()

func gain_xp(amount: int):
	xp += amount
	if xp >= xp_to_next_level:
		level_up()

func level_up():
	level += 1
	xp -= xp_to_next_level
	xp_to_next_level = int(xp_to_next_level * 1.2)
	
	calculate_enemy_stats()
	print("Level Up! New Level: ", level)
	
	trigger_upgrade_selection()

func trigger_upgrade_selection():
	if upgrade_pool == null:
		print("No UpgradePool assigned to GameManager!")
		return
		
	get_tree().paused = true
	# TODO: Instantiate UI and populate it (Handled by UI Logic usually, but we need to signal it)
	# For now, we will assume a UI listener or direct instantiation. 
	# Actually, the plan said "Instantiate UI".
	var ui_scene = load("res://scenes/ui/UpgradeSelectionUI.tscn")
	if ui_scene:
		var ui_instance = ui_scene.instantiate()
		get_tree().current_scene.add_child(ui_instance)
		var options = upgrade_pool.pick_random_upgrades(3, active_projectile_behaviors)
		ui_instance.set_options(options)
	else:
		print("UpgradeSelectionUI scene not found at res://scenes/ui/UpgradeSelectionUI.tscn")
		get_tree().paused = false # Fail safe

func apply_upgrade(upgrade: UpgradeData):
	print("Applying upgrade: ", upgrade.title)
	var stat_name = upgrade.target_stat
	var modifier = upgrade.get_modifier()
	
	var stat_obj = get(stat_name)
	if stat_obj and stat_obj is Stat:
		stat_obj.add_modifier(modifier)
	else:
		if stat_name != "":
			print("Error: Could not find stat named ", stat_name)
			
	# Handle granted behaviors
	if upgrade.granted_behavior:
		var behavior = upgrade.granted_behavior
		
		# Case 1: Assigned a Script (e.g. RicochetBehavior.gd)
		if behavior is Script:
			var instance = behavior.new()
			if instance is ProjectileBehavior:
				active_projectile_behaviors.append(instance)
				print("Added behavior from script: ", upgrade.title)
				
		# Case 2: Assigned a Configured Resource (e.g. Ricochet.tres)
		elif behavior is ProjectileBehavior:
			# We duplicate it so if it has state (like cooldowns), it's unique per run? 
			# Actually, this list is a blueprint. The ProjectileBase duplicates it again.
			# But 'granted_behavior' is a Resource, so it's shared.
			# We'll just add it to the list.
			active_projectile_behaviors.append(behavior)
			print("Added behavior from resource: ", upgrade.title)
		else:
			print("Error: Granted behavior is not a ProjectileBehavior or Script: ", behavior)

	# Handle behavior upgrades (Smart Upgrades)
	if upgrade.target_behavior_script and upgrade.target_behavior_stat != "":
		# Find the behavior instance to upgrade
		var target_instance = null
		for b in active_projectile_behaviors:
			if b.get_script() == upgrade.target_behavior_script:
				target_instance = b
				break
		
		if target_instance:
			var current_val = target_instance.get(upgrade.target_behavior_stat)
			var new_val = current_val + upgrade.modifier_value
			target_instance.set(upgrade.target_behavior_stat, new_val)
			print("Upgraded Behavior: ", upgrade.title, " | New Value: ", new_val)
		else:
			print("Error: Could not find active behavior to upgrade: ", upgrade.target_behavior_script)



	# Resume game
	get_tree().paused = false

func get_player_stats_dict() -> Dictionary:
	return {
		"player_speed": player_speed.get_value(),
		"player_rotation_speed": player_rotation_speed.get_value(),
		"player_turret_speed": player_turret_speed.get_value(),
		"player_damage": player_damage.get_value(),
		"player_fire_rate": player_fire_rate.get_value(),
		"player_projectile_speed": player_projectile_speed.get_value()
	}