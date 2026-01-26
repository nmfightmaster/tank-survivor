extends CanvasLayer

@onready var container = $Control/HBoxContainer

# We expect the scene tree to look like:
# UpgradeSelectionUI (CanvasLayer)
#   Control (Control) - Full rect, maybe bad background
#     HBoxContainer (HBoxContainer) - Center
#       UpgradeButton1 (Button)
#       UpgradeButton2 (Button)
#       UpgradeButton3 (Button)

func set_options(upgrades: Array[UpgradeData]):
	# Clear existing children if any (or just assuming we have 3 static ones)
	# For robustness, let's remove children and create new buttons
	for child in container.get_children():
		child.queue_free()
		
	for upgrade in upgrades:
		var btn = Button.new()
		btn.text = upgrade.title + "\n" + upgrade.description
		if upgrade.icon:
			btn.icon = upgrade.icon
		btn.custom_minimum_size = Vector2(200, 300)
		
		# Connect pressed signal using a callable to capture the upgrade data
		btn.pressed.connect(func(): _on_upgrade_selected(upgrade))
		
		container.add_child(btn)

func _on_upgrade_selected(upgrade: UpgradeData):
	GameManager.apply_upgrade(upgrade)
	queue_free() # Close the UI
