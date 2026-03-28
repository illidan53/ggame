class_name EventSystem
extends RefCounted

## All known relic names for random relic rewards
const ALL_RELICS: Array[String] = ["Iron Bracers", "War Drum", "Cracked Crown", "Blood Pendant", "Rage Mask", "Thorn Armor"]

## Execute an event choice and mutate the run data dictionary
## data keys: hp, max_hp, gold, relics, deck
## Returns a result dictionary with any extra info (relic gained, card gained, etc.)
static func execute_choice(event_id: String, choice_id: String, data: Dictionary, seed_value: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var result := {}

	match event_id:
		"mysterious_altar":
			match choice_id:
				"blood_offering":
					data["hp"] = data["hp"] - 10
					# Pick a random relic
					var available = RelicSystem.get_available_relics(ALL_RELICS, data.get("relics", []))
					if not available.is_empty():
						var relic = available[rng.randi_range(0, available.size() - 1)]
						result["relic"] = relic
					else:
						result["relic"] = ""
				"walk_away":
					pass  # Nothing happens

		"wandering_merchant":
			match choice_id:
				"trade":
					if data["gold"] < 50:
						result["blocked"] = true
					else:
						data["gold"] -= 50
						# Gain a random Uncommon card
						result["card"] = _roll_uncommon_card(rng)
				"rob":
					data["gold"] += 30
					data["hp"] -= 8
				"leave":
					pass  # Nothing happens

		"training_dummy":
			match choice_id:
				"practice":
					result["upgrade"] = true  # UI handles card selection
				"dismantle":
					data["gold"] += 15

	return result

## Roll a random uncommon card name from the pool
static func _roll_uncommon_card(rng: RandomNumberGenerator) -> String:
	var pool: Array[String] = []
	var dir = DirAccess.open("res://resources/cards/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var card = load("res://resources/cards/" + file_name) as CardData
				if card and card.rarity == "Uncommon":
					pool.append(card.card_name)
			file_name = dir.get_next()
	if pool.is_empty():
		return "Unknown Card"
	return pool[rng.randi_range(0, pool.size() - 1)]

## Get all available events
static func get_event_list() -> Array[String]:
	return ["mysterious_altar", "wandering_merchant", "training_dummy"]

## Get choices for an event
static func get_choices(event_id: String) -> Array[Dictionary]:
	match event_id:
		"mysterious_altar":
			return [
				{"id": "blood_offering", "text": "Blood Offering — Lose 10 HP, gain a random relic"},
				{"id": "walk_away", "text": "Walk Away — Nothing happens"},
			]
		"wandering_merchant":
			return [
				{"id": "trade", "text": "Trade — Lose 50 gold, gain a random Uncommon card"},
				{"id": "rob", "text": "Rob — Gain 30 gold, take 8 damage"},
				{"id": "leave", "text": "Leave — Nothing happens"},
			]
		"training_dummy":
			return [
				{"id": "practice", "text": "Practice — Upgrade a card"},
				{"id": "dismantle", "text": "Dismantle — Gain 15 gold"},
			]
		_:
			return []
