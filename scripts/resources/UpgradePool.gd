class_name UpgradePool
extends Resource

@export var upgrades: Array[UpgradeData] = []
# Later we can add weights or rarity buckets here

# 'active_behaviors' is a list of ProjectileBehavior INSTANCES currently owned by the player.
func pick_random_upgrades(count: int = 3, active_behaviors: Array[ProjectileBehavior] = []) -> Array[UpgradeData]:
	var available = upgrades.duplicate()
	var picked: Array[UpgradeData] = []
	
	for i in range(count):
		if available.is_empty():
			break
		var idx = randi() % available.size()
		var candidate = available[idx]
		
		# SMART LOGIC: Check if this is a behavior unlock that we already possess
		var behavior_script = _get_behavior_script(candidate)
		var existing_instance = _find_matching_behavior(active_behaviors, behavior_script)
		
		if existing_instance:
			# Player already has this behavior. Convert the "Unlock" card into an "Upgrade" card.
			var valid_upgrades = existing_instance.get_valid_upgrades()
			
			if valid_upgrades.size() > 0:
				# Pick a random substat to upgrade
				var option = valid_upgrades.pick_random()
				
				# Create dynamic card
				var smart_card = candidate.duplicate()
				smart_card.title = "Upgrade: " + option.get("title", "Unknown")
				smart_card.description = "Improves " + candidate.title
				smart_card.target_behavior_script = behavior_script
				smart_card.target_behavior_stat = option.get("stat", "")
				smart_card.modifier_value = option.get("value", 0.0)
				smart_card.granted_behavior = null # No longer an unlock
				
				picked.append(smart_card)
			else:
				# No upgrades available (maxed out?), just skip or pick anyway?
				# For now, let's pick the original (maybe it allows duplicates? Ricochet doesn't make sense as duplicate)
				# Actually, if we own it, and no upgrades, maybe we shouldn't show it?
				# But to keep simple, we'll just add the candidate (which might do nothing or add a second copy).
				picked.append(candidate)
		else:
			# Don't have it, or it's just a stat upgrade.
			picked.append(candidate)
			
		available.remove_at(idx)
		
	return picked

func _get_behavior_script(upgrade: UpgradeData) -> Script:
	if upgrade.granted_behavior:
		if upgrade.granted_behavior is Script:
			return upgrade.granted_behavior
		elif upgrade.granted_behavior is ProjectileBehavior:
			return upgrade.granted_behavior.get_script()
	return null

func _find_matching_behavior(active: Array[ProjectileBehavior], script: Script) -> ProjectileBehavior:
	if script == null: return null
	for b in active:
		if b.get_script() == script:
			return b
	return null
