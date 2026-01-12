extends CharacterBody2D

@export var move_speed: float = 200.0
@export var turn_speed: float = 2.0

@onready var tank_body: Node2D = $TankBodyMesh

func _physics_process(delta: float) -> void:
    var rotation_direction := Input.get_axis("turn_counter_clockwise", "turn_clockwise")
    tank_body.rotation += rotation_direction * turn_speed * delta

    var move_direction := Input.get_axis("move_backward", "move_forward")
    velocity = Vector2.UP.rotated(tank_body.rotation) * move_direction * move_speed
    
    move_and_slide()
