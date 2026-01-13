extends ParallaxBackground

func _ready() -> void:
	var layer = $ParallaxLayer
	var sprite = $ParallaxLayer/Sprite2D

	if sprite and sprite.texture:
		if sprite.region_enabled:
			layer.motion_mirroring = sprite.region_rect.size
		else:
			layer.motion_mirroring = sprite.texture.get_size() * sprite.scale
