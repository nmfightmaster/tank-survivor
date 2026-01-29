extends Node3D

## Manages enemy wave spawning and scaling.
##
## Uses WaveData resources to determine spawn composition and intervals.
## Scales difficulty based on loop count and game level.

@export var waves: Array[WaveData] = []
@export var spawn_path: PathFollow3D

var current_wave_index: int = 0
var current_wave_time: float = 0.0
var spawn_timer: float = 0.0
var current_budget_spent: int = 0

func _ready() -> void:
    # Wait for vehicle to register if not ready
    if GameManager.main_vehicle:
        _assign_path_from_vehicle(GameManager.main_vehicle)
    else:
        GameManager.vehicle_registered.connect(func(v): 
            if GameManager.main_vehicle == v and not spawn_path:
                _assign_path_from_vehicle(v)
        )
        
    # Fallback search
    if not spawn_path:
        var vehicle_node: Node = get_tree().current_scene.find_child("TankVehicle", true, false)
        if vehicle_node:
            _assign_path_from_vehicle(vehicle_node)

func _assign_path_from_vehicle(vehicle: Node) -> void:
    var p: Node = vehicle.get_node_or_null("Path3D/PathFollow3D")
    if p and p is PathFollow3D:
        spawn_path = p
        print("WaveManager: Found and assigned vehicle spawn path.")
    else:
        print("WaveManager: Vehicle found but no Path3D/PathFollow3D found on it.")

func _process(delta: float) -> void:
    var wave: WaveData
    var difficulty_multiplier: float = 1.0
    
    if current_wave_index >= waves.size():
        if waves.size() > 0:
            # Loop the last wave indefinitely
            wave = waves[-1]
            # Increase difficulty based on how many "extra" waves we've passed
            var extra_waves: int = current_wave_index - waves.size() + 1
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
    var actual_interval: float = wave.spawn_interval / ((1.0 + (GameManager.level - 1) * 0.1) * difficulty_multiplier)
    
    if spawn_timer >= actual_interval:
        spawn_timer = 0.0
        attempt_spawn(wave, difficulty_multiplier)

func attempt_spawn(wave: WaveData, difficulty_multiplier: float = 1.0) -> void:
    # Virtual budget increases with difficulty
    var adjusted_budget: float = wave.total_budget * difficulty_multiplier
    
    if current_budget_spent >= adjusted_budget:
        return # Budget exhausted for this wave
        
    var enemy_data: EnemyData = wave.get_random_enemy()
    if not enemy_data:
        return
        
    # Check if we can afford it (cost = base_health + damage roughly? or defined cost)
    var cost: int = 1
    
    spawn_enemy(enemy_data)
    current_budget_spent += cost

func spawn_enemy(data: EnemyData) -> void:
    if not spawn_path:
        # Retry finding path if we lost it or never found it
        if GameManager.main_vehicle:
            _assign_path_from_vehicle(GameManager.main_vehicle)
            
        if not spawn_path:
            print("WaveManager: No Spawn Path assigned!")
            return

    # Instantiate generic EnemyBase (which has the logic)
    var enemy_scene: PackedScene = load("res://scenes/base/enemy_base.tscn")
    var enemy: EnemyBase = enemy_scene.instantiate()
    
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
