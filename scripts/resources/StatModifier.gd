class_name StatModifier
extends Resource

enum Type {
	ADDITIVE,
	MULTIPLICATIVE
}

@export var value: float = 0.0
@export var type: Type = Type.ADDITIVE
@export var source: String = "" # Optional: to track where this mod came from (e.g. "Iron Plating")

func _init(_value: float = 0.0, _type: Type = Type.ADDITIVE, _source: String = ""):
	value = _value
	type = _type
	source = _source
