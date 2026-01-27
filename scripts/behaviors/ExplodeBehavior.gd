class_name ExplodeBehavior
extends ProjectileBehavior

@export var explosion_radius: float = 5.0
@export var explosion_damage: float = 20.0
@export var explosion_vfx: PackedScene # Optional
@export var explosion_sound: AudioStream

func on_destroyed(projectile: Node) -> void:
	# Logic to deal AoE damage
	var origin = projectile.global_position
	var enemies = projectile.get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		if origin.distance_to(enemy.global_position) <= explosion_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(explosion_damage)
				
	print("Explosion triggered at ", origin)
	
	if projectile.has_method("play_sound"):
		projectile.play_sound(explosion_sound)
	
	if explosion_vfx:
		var fx = explosion_vfx.instantiate()
		projectile.get_tree().current_scene.add_child(fx)
		fx.global_position = origin

