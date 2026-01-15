extends Node3D

@export var mob_scene: PackedScene
@export var spawn_path: PathFollow3D

func _on_timer_timeout() -> void:
	spawn_mob()

func spawn_mob() -> void:
	var mob = mob_scene.instantiate()
	
	spawn_path.progress_ratio = randf()
	mob.position = spawn_path.global_position
	
	get_tree().current_scene.add_child(mob)