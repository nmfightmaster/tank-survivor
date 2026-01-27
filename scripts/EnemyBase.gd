extends CharacterBody3D
class_name EnemyBase

var health: int
var damage: int
var speed: float
var behaviors: Array[EnemyBehavior] = []
var xp_reward: int = 10 

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
# Assuming the model will be added as a child or is the parent structure.
# For this implementation, we will instantiate the model as a child.

func setup(data: EnemyData) -> void:
	health = data.base_health
	speed = data.base_speed
	damage = data.damage
	xp_reward = data.xp_reward
	behaviors = data.behaviors
	
	if data.enemy_model:
		var model_instance = data.enemy_model.instantiate()
		add_child(model_instance)
		# Handle collision shapes if they are part of the model, 
		# or assume the EnemyBase scene has a generic one.
		
func _physics_process(delta: float) -> void:
	for behavior in behaviors:
		behavior.process_behavior(self, delta)
	
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	var xp_scene = load("res://scenes/xp.tscn")
	if xp_scene:
		var xp = xp_scene.instantiate()
		get_tree().current_scene.add_child(xp)
		xp.global_position = global_position
		# If XP script supports custom amount, set it here. 
		# Looking at xp.gd (Step 107), it gives hardcoded 10.
		# I should update xp.gd to accept an amount or keep it simple for now.
		# But the user asked for "XP drops per enemy should also be a configurable variable."
		if xp.has_method("set_amount"):
			xp.set_amount(xp_reward)
		elif "amount" in xp:
			xp.amount = xp_reward
	
	queue_free()
