extends Node

## Central manager for game state, player stats, and upgrade application.
##
## Tracks XP, level, and manages the upgrade pool.
## Provides a central access point for player stats.

signal stats_changed

var player: CharacterBody3D
var player_position: Vector3 = Vector3.ZERO
var player_health: float = 100.0
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
var player_lifesteal: Stat
var player_armor: Stat
var player_max_health: Stat

# Projectile Behaviors
var active_projectile_behaviors: Array[ProjectileBehavior] = []

# Upgrade Pool
@export var upgrade_pool: UpgradePool

func _ready() -> void:
	_init_stats()

func _init_stats() -> void:
	player_speed = Stat.new(10.0)
	player_rotation_speed = Stat.new(2.0)
	player_turret_speed = Stat.new(4.0)
	player_damage = Stat.new(10.0)
	player_fire_rate = Stat.new(0.5) # Shots per second
	player_projectile_speed = Stat.new(50.0)
	player_lifesteal = Stat.new(0.0) # Percentage of damage dealt returned as health
	player_armor = Stat.new(0.0) # Percentage reduction in incoming damage
	player_max_health = Stat.new(100.0)
	
	# Emit change when any stat changes
	var stats: Array[Stat] = [player_speed, player_rotation_speed, player_turret_speed, player_damage, player_fire_rate, player_projectile_speed, player_lifesteal, player_armor, player_max_health]
	for s in stats:
		s.value_changed.connect(func(_val: float) -> void: stats_changed.emit())

func reset() -> void:
	xp = 0
	level = 1
	xp_to_next_level = 100
	player_health = 100
	_init_stats() # Reset stats to base
	player_health = player_max_health.get_value()
	active_projectile_behaviors.clear()

func gain_xp(amount: int) -> void:
	xp += amount
	if xp >= xp_to_next_level:
		level_up()

func level_up() -> void:
	level += 1
	xp -= xp_to_next_level
	xp_to_next_level = int(xp_to_next_level * 1.2)
	
	print("Level Up! New Level: ", level)
	
	trigger_upgrade_selection()

func trigger_upgrade_selection() -> void:
	if upgrade_pool == null:
		print("GameManager: No UpgradePool assigned!")
		return
		
	get_tree().paused = true

	var ui_scene: PackedScene = load("res://scenes/ui/UpgradeSelectionUI.tscn")
	if ui_scene:
		var ui_instance: Node = ui_scene.instantiate()
		get_tree().current_scene.add_child(ui_instance)
		if ui_instance.has_method("set_options"):
			var options: Array[UpgradeData] = upgrade_pool.pick_random_upgrades(3, active_projectile_behaviors)
			ui_instance.set_options(options)
	else:
		print("GameManager: UpgradeSelectionUI scene not found.")
		get_tree().paused = false # Fail safe

func apply_upgrade(upgrade: UpgradeData) -> void:
	print("Applying upgrade: ", upgrade.title)
	var stat_name: String = upgrade.target_stat
	var modifier: StatModifier = upgrade.get_modifier()
	
	var stat_obj = get(stat_name)
	if stat_obj and stat_obj is Stat:
		stat_obj.add_modifier(modifier)
	elif stat_name != "":
		print("GameManager: Error - Could not find stat named ", stat_name)
			
	# Handle granted behaviors
	if upgrade.granted_behavior:
		var behavior = upgrade.granted_behavior
		
		# Case 1: Assigned a Script
		if behavior is Script:
			var instance = behavior.new()
			if instance is ProjectileBehavior:
				active_projectile_behaviors.append(instance)
				print("Added behavior from script: ", upgrade.title)
				
		# Case 2: Assigned a Configured Resource
		elif behavior is ProjectileBehavior:
			active_projectile_behaviors.append(behavior)
			print("Added behavior from resource: ", upgrade.title)
		else:
			print("GameManager: Error - Granted behavior is invalid type: ", behavior)

	# Handle behavior upgrades (Smart Upgrades)
	if upgrade.target_behavior_script and upgrade.target_behavior_stat != "":
		# Find the behavior instance to upgrade
		var target_instance: ProjectileBehavior = null
		for b in active_projectile_behaviors:
			if b.get_script() == upgrade.target_behavior_script:
				target_instance = b
				break
		
		if target_instance:
			var current_val = target_instance.get(upgrade.target_behavior_stat)
			if typeof(current_val) == TYPE_FLOAT or typeof(current_val) == TYPE_INT:
				var new_val = current_val + upgrade.modifier_value
				target_instance.set(upgrade.target_behavior_stat, new_val)
				print("Upgraded Behavior: ", upgrade.title, " | New Value: ", new_val)
		else:
			print("GameManager: Could not find active behavior to upgrade: ", upgrade.target_behavior_script)

	# Resume game
	get_tree().paused = false

func get_player_stats_dict() -> Dictionary:
	return {
		"player_speed": player_speed.get_value(),
		"player_rotation_speed": player_rotation_speed.get_value(),
		"player_turret_speed": player_turret_speed.get_value(),
		"player_damage": player_damage.get_value(),
		"player_fire_rate": player_fire_rate.get_value(),
		"player_projectile_speed": player_projectile_speed.get_value(),
		"player_lifesteal": player_lifesteal.get_value(),
		"player_armor": player_armor.get_value(),
		"player_max_health": player_max_health.get_value()
	}