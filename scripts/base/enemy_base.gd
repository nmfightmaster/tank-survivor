extends CharacterBody3D
class_name EnemyBase

## Base class for enemies.
##
## Handles health, basic movement, and death.
## Driven by EnemyData and EnemyBehavior resources.

var health: int
var damage: int
var speed: float
var behaviors: Array[EnemyBehavior] = []
var xp_reward: int = 10 

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

const XP_SCENE: PackedScene = preload("res://scenes/entities/xp_orb.tscn")

func setup(data: EnemyData) -> void:
	health = data.base_health
	speed = data.base_speed
	damage = data.damage
	xp_reward = data.xp_reward
	behaviors = data.behaviors
	
	if data.enemy_model:
		var model_instance: Node = data.enemy_model.instantiate()
		add_child(model_instance)
		
func _physics_process(delta: float) -> void:
	for behavior in behaviors:
		behavior.process_behavior(self, delta)
	
	move_and_slide()

func take_damage(amount: int, source: Node = null) -> void:
	health -= amount
	if health <= 0:
		die(source)

func die(source: Node = null) -> void:
	if XP_SCENE:
		var xp: Node3D = XP_SCENE.instantiate()
		get_tree().current_scene.add_child(xp)
		xp.global_position = global_position
		
		# Set XP amount if supported
		if xp.has_method("set_amount"):
			xp.set_amount(xp_reward)
		elif "amount" in xp:
			xp.set("amount", xp_reward)
	
	# Attribute Kill
	if source:
		if source.has_method("increment_kills"):
			source.increment_kills()
		elif "owner_vehicle" in source and source.owner_vehicle:
			source.owner_vehicle.increment_kills()
	
	queue_free()
