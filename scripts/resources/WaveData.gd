extends Resource
class_name WaveData

@export var wave_duration: float = 60.0
@export var spawn_interval: float = 1.0
@export var total_budget: int = 100
## Array of EnemyData resources available in this wave
@export var available_enemies: Array[EnemyData] = []
## Weights corresponding to available_enemies by index. 
## If empty, all have equal weight.
@export var spawn_weights: Array[float] = []

func get_random_enemy() -> EnemyData:
	if available_enemies.is_empty():
		return null
		
	if spawn_weights.size() != available_enemies.size():
		return available_enemies.pick_random()
	
	var total_weight = 0.0
	for w in spawn_weights:
		total_weight += w
	
	var roll = randf() * total_weight
	var current = 0.0
	for i in range(available_enemies.size()):
		current += spawn_weights[i]
		if roll <= current:
			return available_enemies[i]
			
	return available_enemies[0]
