class_name ChasePlayerBehavior
extends EnemyBehavior

## Enemy behavior that makes the entity chase the player.

func process_behavior(enemy: CharacterBody3D, delta: float) -> void:
	# Basic chase logic
	var target_pos: Vector3 = Vector3.ZERO
	if GameManager.player_position:
		target_pos = GameManager.player_position
	
	var direction: Vector3 = enemy.global_position.direction_to(target_pos)
	
	# We need to know the enemy's speed. EnemyBase has a 'speed' property.
	if "speed" in enemy:
		enemy.velocity = direction * enemy.get("speed")
	else:
		enemy.velocity = direction * 5.0 # Fallback
