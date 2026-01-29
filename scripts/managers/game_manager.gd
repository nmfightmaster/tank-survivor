extends Node

## Central manager for game state, player stats, and upgrade application.
##
## Tracks XP, level, and manages the squadron.
## Acts as a bridge between UI, Upgrades, and Vehicles.

signal stats_changed
signal vehicle_registered(vehicle: VehicleBase)

# Squadron Management
var squadron_vehicles: Array[VehicleBase] = []
var main_vehicle: VehicleBase = null

# Global Stats Modifiers
# Dictionary[String, Array[StatModifier]]
# key = stat_name (e.g. "speed"), value = list of modifiers to apply to every new vehicle
var global_stat_modifiers: Dictionary = {}
var current_upgrading_vehicle: VehicleBase = null

# Game State
var xp: int = 0
var xp_to_next_level: int = 100
var level: int = 1

# Upgrade Pool
@export var upgrade_pool: UpgradePool

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Ensure GameManager runs even when paused (needed for UI)

func reset() -> void:
	xp = 0
	level = 1
	xp_to_next_level = 100
	
	squadron_vehicles.clear()
	main_vehicle = null
	global_stat_modifiers.clear()
	current_upgrading_vehicle = null

# --- Vehicle Management ---

func register_vehicle(vehicle: VehicleBase) -> void:
	if not squadron_vehicles.has(vehicle):
		squadron_vehicles.append(vehicle)
		
		# Connect signals
		vehicle.died.connect(func(): _on_vehicle_died(vehicle))
		if not vehicle.request_upgrade.is_connected(_on_vehicle_request_upgrade):
			vehicle.request_upgrade.connect(_on_vehicle_request_upgrade)
		
		# Apply existing global modifiers
		for stat_name in global_stat_modifiers:
			for modifier in global_stat_modifiers[stat_name]:
				vehicle.apply_stat_modifier(stat_name, modifier)
		
		# If this is the first vehicle, assume it's main for now (unless set otherwise)
		if main_vehicle == null:
			main_vehicle = vehicle
		
		print("GameManager: Registered vehicle ", vehicle.name)
		vehicle_registered.emit(vehicle)

func _on_vehicle_died(vehicle: VehicleBase) -> void:
	squadron_vehicles.erase(vehicle)
	if vehicle == main_vehicle:
		# Generic game over or switch to next available
		if squadron_vehicles.size() > 0:
			main_vehicle = squadron_vehicles[0]
			print("GameManager: Main vehicle died. Switched to ", main_vehicle.name)
		else:
			print("GameManager: All vehicles lost. Game Over.")
			# Trigger Game Over logic here (reload scene)
			get_tree().reload_current_scene()
			reset()

# --- XP & Levelling ---

func gain_xp(amount: int) -> void:
	xp += amount
	if xp >= xp_to_next_level:
		level_up()

func level_up() -> void:
	level += 1
	xp -= xp_to_next_level
	xp_to_next_level = int(xp_to_next_level * 1.2)
	
	print("Level Up! New Level: ", level)
	trigger_upgrade_selection("stats")

func _on_vehicle_request_upgrade(vehicle: VehicleBase) -> void:
	print("Upgrade requested for: ", vehicle.name)
	current_upgrading_vehicle = vehicle
	trigger_upgrade_selection("behaviors")

func trigger_upgrade_selection(pool_type: String = "stats") -> void:
	if upgrade_pool == null:
		print("GameManager: No UpgradePool assigned!")
		return
		
	get_tree().paused = true

	var ui_scene: PackedScene = load("res://scenes/ui/UpgradeSelectionUI.tscn")
	if ui_scene:
		var ui_instance: Node = ui_scene.instantiate()
		get_tree().current_scene.add_child(ui_instance)
		if ui_instance.has_method("set_options"):
			var options: Array[UpgradeData] = []
			
			if pool_type == "stats":
				# Level Up -> Global Stats
				options = upgrade_pool.pick_random_upgrades(3, [])
				current_upgrading_vehicle = null # Ensure global
				
			elif pool_type == "behaviors":
				# Kill Threshold -> Specific Vehicle Behaviors
				if is_instance_valid(current_upgrading_vehicle):
					# If pick_behavior_upgrades is not yet available/working, fallback:
					if upgrade_pool.has_method("pick_behavior_upgrades"):
						options = upgrade_pool.pick_behavior_upgrades(3, current_upgrading_vehicle.active_projectile_behaviors)
					else:
						# Fallback logic if method missing (shouldn't happen if prev step worked)
						options = upgrade_pool.pick_random_upgrades(3, current_upgrading_vehicle.active_projectile_behaviors)
			
			ui_instance.set_options(options)
	else:
		print("GameManager: UpgradeSelectionUI scene not found.")
		get_tree().paused = false

# --- Upgrades ---

func apply_upgrade(upgrade: UpgradeData) -> void:
	print("Applying upgrade: ", upgrade.title)
	
	# 1. Apply Stat Modifier (Global)
	if upgrade.target_stat != "":
		# Map legacy names (e.g. "player_speed") to new vehicle stat names ("speed")
		var stat_name = upgrade.target_stat.replace("player_", "")
		
		var modifier: StatModifier = upgrade.get_modifier()
		
		# Store globally
		if not global_stat_modifiers.has(stat_name):
			global_stat_modifiers[stat_name] = []
		global_stat_modifiers[stat_name].append(modifier)
		
		# Apply to all current vehicles
		for v in squadron_vehicles:
			v.apply_stat_modifier(stat_name, modifier)
			
	# 2. Apply Granted Behaviors (Local)
	var target_vehicle = current_upgrading_vehicle
	if target_vehicle == null:
		target_vehicle = main_vehicle

	if upgrade.granted_behavior:
		if is_instance_valid(target_vehicle):
			var behavior = upgrade.granted_behavior
			
			if behavior is Script:
				var instance = behavior.new()
				if instance is ProjectileBehavior:
					target_vehicle.active_projectile_behaviors.append(instance)
			elif behavior is ProjectileBehavior:
				target_vehicle.active_projectile_behaviors.append(behavior)
			
			print("Granted behavior to ", target_vehicle.name)
		else:
			print("GameManager: Cannot apply behavior - No Target Vehicle!")

	# 3. Apply Behavior Upgrades (Smart)
	if upgrade.target_behavior_script and upgrade.target_behavior_stat != "":
		if is_instance_valid(target_vehicle):
			var target_instance: ProjectileBehavior = null
			for b in target_vehicle.active_projectile_behaviors:
				if b.get_script() == upgrade.target_behavior_script:
					target_instance = b
					break
			
			if target_instance:
				var current_val = target_instance.get(upgrade.target_behavior_stat)
				if typeof(current_val) == TYPE_FLOAT or typeof(current_val) == TYPE_INT:
					var new_val = current_val + upgrade.modifier_value
					target_instance.set(upgrade.target_behavior_stat, new_val)
					print("Upgraded behavior on ", target_vehicle.name)

	stats_changed.emit()
	current_upgrading_vehicle = null
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func info_toggle_pause() -> void:
	# This function is here to show up in the outline, the real logic is below
	pass

func toggle_pause() -> void:
	# Check if we already have a pause menu open (or other blocking UI?)
	var existing_menu = get_tree().current_scene.find_child("PauseMenu", false, false)
	if existing_menu:
		# If it exists, let the menu handle closing itself via its own input or resume button
		# But we can also force close it here if we want toggle behavior
		existing_menu.queue_free()
		get_tree().paused = false
		resume_game() # Ensure any extra logic runs
	else:
		# Avoid opening pause menu if we are in Upgrade Selection
		if get_tree().paused and get_tree().current_scene.find_child("UpgradeSelectionUI", false, false):
			return

		var menu_scene = load("res://scenes/ui/pause_menu.tscn")
		if menu_scene:
			var menu = menu_scene.instantiate()
			get_tree().current_scene.add_child(menu)
			get_tree().paused = true

func resume_game() -> void:
	get_tree().paused = false

# --- UI Helper ---

## Returns stats dict for the Main Vehicle (for UI display)
func get_player_stats_dict() -> Dictionary:
	if not is_instance_valid(main_vehicle):
		# Return base safe defaults/zeros if no vehicle
		return {
			"player_speed": 0, "player_damage": 0, "player_max_health": 0
		}
	
	# We map back to "player_X" keys because existing UI likely expects them
	return {
		"player_speed": main_vehicle.speed.get_value(),
		"player_rotation_speed": main_vehicle.rotation_speed.get_value(),
		"player_turret_speed": main_vehicle.turret_speed.get_value() if "turret_speed" in main_vehicle else 0,
		"player_damage": main_vehicle.damage.get_value(),
		"player_fire_rate": main_vehicle.fire_rate.get_value(),
		"player_projectile_speed": main_vehicle.projectile_speed.get_value(),
		"player_lifesteal": main_vehicle.lifesteal.get_value(),
		"player_armor": main_vehicle.armor.get_value(),
		"player_max_health": main_vehicle.max_max_health.get_value() if "max_max_health" in main_vehicle else main_vehicle.max_health.get_value()
	}