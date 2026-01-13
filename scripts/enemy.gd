extends CharacterBody2D

@export var move_speed: float = 180.0
@export var turn_speed: float = 2.0
@export var max_health: int = 50

@export_group("Combat")
@export var missile_scene: PackedScene = preload("res://scenes/missile.tscn")
@export var fire_rate: float = 1.0
@export var projectile_damage: int = 5
@export var projectile_speed: float = 300.0

var health: int
var reload_timer: float = 0.0

@onready var tank_body: Node2D = $TankBodyMesh
@onready var tank_turret: Node2D = $TankTurretSprite
@onready var muzzle: Marker2D = $TankTurretSprite/Muzzle

func _ready() -> void:
	add_to_group("enemy")
	health = max_health

func _physics_process(delta: float) -> void:
	if reload_timer > 0:
		reload_timer -= delta

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Fallback try to find sibling named Player
		player = get_node_or_null("../Player")
		
	if player:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * move_speed
		
		# Optional: Rotate towards player
		tank_body.rotation = lerp_angle(tank_body.rotation, direction.angle() - (PI/2), turn_speed * delta)
		
		# Rotate turret towards player
		tank_turret.look_at(player.global_position)
		tank_turret.rotation += PI/2
		
		if reload_timer <= 0:
			shoot()
		
		move_and_slide()

func shoot() -> void:
	if missile_scene:
		var missile = missile_scene.instantiate()
		get_parent().add_child(missile)
		missile.global_position = muzzle.global_position
		missile.rotation = tank_turret.global_rotation
		missile.speed = projectile_speed
		missile.damage = projectile_damage
		missile.shooter = self
		reload_timer = fire_rate