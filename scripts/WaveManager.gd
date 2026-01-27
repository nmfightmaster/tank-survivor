extends Node3D

@export var waves: Array[WaveData] = []
@export var spawn_path: PathFollow3D

var current_wave_index: int = 0
var current_wave_time: float = 0.0
var spawn_timer: float = 0.0
var current_budget_spent: int = 0

func _ready() -> void:
	# Always try to find the player's path first, as it's preferred for Survivor-like spawning
	var found_player_path = false
	
	if GameManager.player:
		var p = GameManager.player.get_node_or_null("Path3D/PathFollow3D")
		if p:
			spawn_path = p
			found_player_path = true
			print("WaveManager: Found and assigned player spawn path.")
	
	if not found_player_path:
		var player_node = get_tree().current_scene.find_child("Player", true, false)
		if player_node:
			var p = player_node.get_node_or_null("Path3D/PathFollow3D")
			if p:
				spawn_path = p
				found_player_path = true
				print("WaveManager: Found player spawn path via search.")
				
	# If we still haven't found the player path, we fall back to the exported/assigned path (e.g. static level path)
	if not spawn_path:
		print("WaveManager: Warning - No spawn path found (neither Player nor Exported).")

func _process(delta: float) -> void:
	var wave: WaveData
	var difficulty_multiplier: float = 1.0
	
	if current_wave_index >= waves.size():
		if waves.size() > 0:
			# Loop the last wave indefinitely
			wave = waves[-1]
			# Increase difficulty based on how many "extra" waves we've passed
			# e.g. each cycle increases budget/spawn rate
			var extra_waves = current_wave_index - waves.size() + 1
			difficulty_multiplier = 1.0 + (extra_waves * 0.2) 
		else:
			return # No waves defined at all
	else:
		wave = waves[current_wave_index]

	# Wave Timing
	current_wave_time += delta
	if current_wave_time >= wave.wave_duration:
		next_wave()
		return
		
	# Spawning
	spawn_timer += delta
	# Scale spawn rate by game level AND difficulty multiplier
	var actual_interval = wave.spawn_interval / ((1.0 + (GameManager.level - 1) * 0.1) * difficulty_multiplier)
	
	if spawn_timer >= actual_interval:
		spawn_timer = 0.0
		attempt_spawn(wave, difficulty_multiplier)

func attempt_spawn(wave: WaveData, difficulty_multiplier: float = 1.0) -> void:
	# Virtual budget increases with difficulty
	var adjusted_budget = wave.total_budget * difficulty_multiplier
	
	if current_budget_spent >= adjusted_budget:
		return # Budget exhausted for this wave
		
	var enemy_data = wave.get_random_enemy()
	if not enemy_data:
		return
		
	# Check if we can afford it (cost = base_health + damage roughly? or defined cost)
	# For now, let's assume cost = 1 per enemy, or add 'cost' to EnemyData.
	# User didn't specify 'cost' in EnemyData, but 'budget' implies it.
	# I'll default cost to 1 for now, or use health as proxy.
	var cost = 1
	
	spawn_enemy(enemy_data)
	current_budget_spent += cost

func spawn_enemy(data: EnemyData) -> void:
	if not spawn_path:
		print("WaveManager: No Spawn Path assigned!")
		return

	# Instantiate generic EnemyBase (which has the logic)
	var enemy_scene = load("res://scenes/enemy_base.tscn")
	var enemy = enemy_scene.instantiate()
	
	# Position logic (random on path)
	spawn_path.progress_ratio = randf()
	enemy.position = spawn_path.global_position
	
	# Add to scene
	get_tree().current_scene.add_child(enemy)
	
	# Setup stats and visuals
	enemy.setup(data)

func next_wave() -> void:
	current_wave_index += 1
	current_wave_time = 0.0
	spawn_timer = 0.0
	current_budget_spent = 0
	print("Starting Wave: ", current_wave_index)
