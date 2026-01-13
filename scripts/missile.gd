extends Area2D

var speed: float = 400.0
var damage: int = 10
var shooter: Node2D = null

func _physics_process(delta: float) -> void:
	position += Vector2.UP.rotated(rotation) * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)
	elif "health" in body:
		body.health -= damage
		if body.health <= 0:
			body.queue_free()
	
	queue_free()
