class_name EnemyBehavior
extends Resource

## Base class for enemy behaviors.
##
## Defines logic for enemy AI, movement, or actions.
## Override process_behavior to implement custom logic efficiently.

func process_behavior(enemy: CharacterBody3D, delta: float) -> void:
	pass
