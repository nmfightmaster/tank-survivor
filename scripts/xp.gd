extends Area3D

var is_following = false
var move_speed = 1.0
var acceleration = 35.0 # Linear acceleration in units/sec^2

func _ready():
	is_following = true

func _physics_process(delta):
	if is_following:
		# Move toward the player's global position
		var target_pos = GameManager.player_position
		var distance_to_target = global_position.distance_to(target_pos)
		
		# Linear acceleration instead of exponential multiplication
		move_speed += acceleration * delta
		var move_amount = move_speed * delta
		
		# Check for overshoot
		if move_amount >= distance_to_target:
			global_position = target_pos
			collect()
		else:
			var direction = global_position.direction_to(target_pos)
			global_position += direction * move_amount

func collect():
	GameManager.gain_xp(10)
	queue_free()
