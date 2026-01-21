extends Area3D

var speed: float = 0.0
var damage: float = 0.0
@onready var fire_sound: AudioStreamPlayer3D = $FireSound
@onready var explosion_sound: AudioStreamPlayer3D = $ExplosionSound
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	fire_sound.play()

func _physics_process(delta):
	# Move the bullet forward based on its own orientation
	# In Godot, -basis.z is usually "forward" in 3D
	position -= transform.basis.z * speed * delta

# Connect the body_entered signal to destroy the bullet/hit enemies
func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage) # We'll add this to the enemy later
	
	explosion_sound.play()
	mesh.visible = false
	set_deferred("monitoring", false)
	await explosion_sound.finished
	queue_free() # Destroy bullet