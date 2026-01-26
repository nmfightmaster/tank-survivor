class_name UpgradeData
extends Resource

@export var title: String = "New Upgrade"
@export_multiline var description: String = "Description"
@export var icon: Texture2D

# We define what stat this touches and how
@export var target_stat: String = "" # e.g. "player_speed"
@export var modifier_value: float = 0.0
@export var modifier_type: StatModifier.Type = StatModifier.Type.ADDITIVE

func get_modifier() -> StatModifier:
	return StatModifier.new(modifier_value, modifier_type, title)
