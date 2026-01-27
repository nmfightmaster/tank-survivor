extends EnemyBehavior
class_name ChasePlayerBehavior

func process_behavior(enemy: CharacterBody3D, delta: float) -> void:
	# Basic chase logic
	var target_pos = Vector3.ZERO
	if GameManager.player_position:
		target_pos = GameManager.player_position
	
	var direction = enemy.global_position.direction_to(target_pos)
	# We add to velocity, assuming EnemyBase handles move_and_slide separately, 
	# OR we set velocity directly. EnemyBase calls move_and_slide.
	# To keep it simple and consistent with previous logic:
	
	# We need to know the enemy's speed. EnemyBase has a 'speed' property.
	if "speed" in enemy:
		enemy.velocity = direction * enemy.speed
	else:
		enemy.velocity = direction * 5.0 # Fallback
