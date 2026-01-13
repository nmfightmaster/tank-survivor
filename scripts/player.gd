extends CharacterBody2D

@export var move_speed: float = 200.0
@export var turn_speed: float = 2.0
@export var turret_turn_speed: float = 4.0
@export var max_health: int = 100

@export_group("Combat")
@export var missile_scene: PackedScene = preload("res://scenes/missile.tscn")
@export var fire_rate: float = 0.5
@export var projectile_damage: int = 10
@export var projectile_speed: float = 400.0

var health: int
var reload_timer: float = 0.0

@onready var tank_body: Node2D = $TankBodyMesh
@onready var tank_turret: Sprite2D = $TankTurretSprite
@onready var muzzle: Marker2D = $TankTurretSprite/Muzzle

func _ready() -> void:
	health = max_health

func _physics_process(delta: float) -> void:
	if reload_timer > 0:
		reload_timer -= delta

	var rotation_direction := Input.get_axis("turn_counter_clockwise", "turn_clockwise")
	tank_body.rotation += rotation_direction * turn_speed * delta

	var move_direction := Input.get_axis("move_backward", "move_forward")
	velocity = Vector2.UP.rotated(tank_body.rotation) * move_direction * move_speed
	
	# Turret aiming
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest_enemy = null
	if enemies.size() > 0:
		var min_dist = INF
		
		for enemy in enemies:
			var dist = global_position.distance_squared_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_enemy = enemy
		
		if nearest_enemy:
			var target_phase = global_position.direction_to(nearest_enemy.global_position).angle()
			tank_turret.rotation = lerp_angle(tank_turret.rotation, target_phase + (PI/2), turret_turn_speed * delta)
			
			# Auto-fire
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
