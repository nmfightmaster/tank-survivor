extends CanvasLayer

@onready var stats_label: RichTextLabel = $RichTextLabel

func _process(delta: float) -> void:
	var text = "[b]Level:[/b] " + str(GameManager.level) + "\n"
	text += "[b]XP:[/b] " + str(GameManager.xp) + " / " + str(GameManager.xp_to_next_level) + "\n"
	text += "\n[b]Stats:[/b]\n"
	
	var stats = GameManager.get_player_stats_dict()
	for stat_name in stats:
		var pretty_name = stat_name.replace("player_", "").capitalize()
		var value = stats[stat_name]
		# Format float to 2 decimal places if it is a float
		if typeof(value) == TYPE_FLOAT:
			text += pretty_name + ": " + "%.2f" % value + "\n"
		else:
			text += pretty_name + ": " + str(value) + "\n"
			
	stats_label.text = text
