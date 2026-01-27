class_name ProjectileData
extends Resource

## Data resource for Projectile configuration.

@export var speed: float = 50.0
@export var damage_multiplier: float = 1.0
@export var lifetime: float = 3.0
@export var projectile_model: PackedScene # Scene containing Mesh + CollisionShape
@export var fire_sound: AudioStream
@export var hit_sound: AudioStream

@export var particle_trail: PackedScene
@export var default_behaviors: Array[ProjectileBehavior] = []
