class_name UpgradePool
extends Resource

@export var upgrades: Array[UpgradeData] = []
# Later we can add weights or rarity buckets here

func pick_random_upgrades(count: int = 3) -> Array[UpgradeData]:
	var available = upgrades.duplicate()
	var picked: Array[UpgradeData] = []
	
	for i in range(count):
		if available.is_empty():
			break
		var idx = randi() % available.size()
		picked.append(available[idx])
		available.remove_at(idx)
		
	return picked
