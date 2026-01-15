extends Node3D

@export var mob_scene: PackedScene

func _on_timer_timeout() -> void:
	spawn_mob()

func spawn_mob() -> void:
	var random_x = randf_range(-20.0, 20.0)
	var random_z = randf_range(-20.0, 20.0)

	var mob = mob_scene.instantiate()
	add_child(mob)
	mob.position = Vector3(random_x, 1.5, random_z)