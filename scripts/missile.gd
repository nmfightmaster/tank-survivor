extends Area2D

var speed: float = 600.0
var damage: int = 10
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
    # Rotate the missile to face its direction of travel
    rotation = direction.angle()

func _physics_process(delta: float) -> void:
    position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("enemy") and body.has_method("take_damage"):
        body.take_damage(damage)
        queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
    queue_free()
