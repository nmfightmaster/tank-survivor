extends Area3D

## Experience Orb.
##
## Collectible that grants XP to the player.
## Accelerates towards player when in range.

@export var amount: int = 10

var is_following: bool = false
var move_speed: float = 1.0
var acceleration: float = 35.0 # Linear acceleration in units/sec^2

func _ready() -> void:
	is_following = true

func _physics_process(delta: float) -> void:
	if is_following:
		# Move toward the player's global position
		var target_pos: Vector3 = Vector3.ZERO
		if is_instance_valid(GameManager.main_vehicle):
			target_pos = GameManager.main_vehicle.global_position
		var distance_to_target: float = global_position.distance_to(target_pos)
		
		# Linear acceleration instead of exponential multiplication
		move_speed += acceleration * delta
		var move_amount: float = move_speed * delta
		
		# Check for overshoot
		if move_amount >= distance_to_target:
			global_position = target_pos
			collect()
		else:
			var direction: Vector3 = global_position.direction_to(target_pos)
			global_position += direction * move_amount

func collect() -> void:
	GameManager.gain_xp(amount)
	queue_free()
