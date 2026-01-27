class_name Stat
extends Resource

signal value_changed(new_value: float)

@export var base_value: float = 0.0:
	set(v):
		base_value = v
		_is_dirty = true
		emit_signal("value_changed", get_value())

var _modifiers: Array[StatModifier] = []
var _cached_value: float = 0.0
var _is_dirty: bool = true

func _init(_base_value: float = 0.0):
	base_value = _base_value

func get_value() -> float:
	if _is_dirty:
		_calculate_value()
	return _cached_value

func add_modifier(modifier: StatModifier) -> void:
	_modifiers.append(modifier)
	_is_dirty = true
	emit_signal("value_changed", get_value())

func remove_modifier(modifier: StatModifier) -> void:
	_modifiers.erase(modifier)
	_is_dirty = true
	emit_signal("value_changed", get_value())

func _calculate_value() -> void:
	var final_value = base_value
	var sum_percent_add = 0.0
	
	for mod in _modifiers:
		if mod.type == StatModifier.Type.ADDITIVE:
			final_value += mod.value
		elif mod.type == StatModifier.Type.MULTIPLICATIVE:
			sum_percent_add += mod.value
			
	final_value *= (1.0 + sum_percent_add)
	_cached_value = final_value
	_is_dirty = false
