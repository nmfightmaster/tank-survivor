extends CanvasLayer

func _ready() -> void:
	# Keep the menu paused logic independent
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_resume_pressed() -> void:
	GameManager.resume_game()
	queue_free()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# If user hits Esc while menu is open, just resume
		_on_resume_pressed()
