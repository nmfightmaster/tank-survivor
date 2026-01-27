class_name UpgradeData
extends Resource

## Data resource for Upgrades.

@export var title: String = "New Upgrade"
@export_multiline var description: String = "Description"
@export var icon: Texture2D

# We define what stat this touches and how
@export var target_stat: String = "" # e.g. "player_speed"
@export var modifier_value: float = 0.0
@export var modifier_type: StatModifier.Type = StatModifier.Type.ADDITIVE

@export var granted_behavior: Resource # ProjectileBehavior resource

# For upgrading existing behaviors
@export var target_behavior_script: Script 
@export var target_behavior_stat: String = ""

func get_modifier() -> StatModifier:
	return StatModifier.new(modifier_value, modifier_type, title)
