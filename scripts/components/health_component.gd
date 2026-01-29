class_name HealthComponent
extends Node

signal died
signal health_changed(new_value, max_value)

@export var max_health_stat: Stat
var current_health: float

func _ready() -> void:
	if not max_health_stat:
		max_health_stat = Stat.new(100.0)
	
	current_health = max_health_stat.get_value()
	max_health_stat.value_changed.connect(_on_max_health_changed)

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health_stat.get_value())
	
	if current_health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	current_health = min(max_health_stat.get_value(), current_health + amount)
	health_changed.emit(current_health, max_health_stat.get_value())

func _on_max_health_changed(_new_max: float) -> void:
	# If max health changes, we might want to adjust current health proportionally or just cap it
	# For now, let's just ensure we don't exceed it
	if current_health > max_health_stat.get_value():
		current_health = max_health_stat.get_value()
	health_changed.emit(current_health, max_health_stat.get_value())
