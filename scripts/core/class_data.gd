class_name ClassData
extends RefCounted

## Class definitions for character selection.

const CLASSES := {
	"Warrior": {
		"max_hp": 80,
		"starting_deck": [
			{"card": "res://resources/cards/strike.tres", "count": 5},
			{"card": "res://resources/cards/defend.tres", "count": 4},
			{"card": "res://resources/cards/bash.tres", "count": 1},
		],
		"starting_relic": "",  # Warrior has no starting relic in current design
		"card_pool_class": "Warrior",
	},
	"Silent": {
		"max_hp": 70,
		"starting_deck": [
			{"card": "res://resources/cards/strike_s.tres", "count": 5},
			{"card": "res://resources/cards/defend_s.tres", "count": 5},
			{"card": "res://resources/cards/neutralize.tres", "count": 1},
			{"card": "res://resources/cards/survivor.tres", "count": 1},
		],
		"starting_relic": "Ring of the Snake",  # Draw 2 extra on first turn
		"card_pool_class": "Silent",
	},
}

## Get class config. Returns empty dict if class doesn't exist.
static func get_class_config(class_name_str: String) -> Dictionary:
	return CLASSES.get(class_name_str, {})

## Get all available class names.
static func get_class_names() -> Array[String]:
	var names: Array[String] = []
	for k in CLASSES:
		names.append(k)
	return names

## Build starting deck for a class. Returns Array[CardInstance].
static func make_starting_deck(class_name_str: String) -> Array[CardInstance]:
	var config = get_class_config(class_name_str)
	if config.is_empty():
		return []
	var deck: Array[CardInstance] = []
	var id := 0
	for entry in config["starting_deck"]:
		var card_data = load(entry["card"]) as CardData
		if card_data:
			for _i in entry["count"]:
				var c = CardInstance.new(card_data)
				c.instance_id = id
				id += 1
				deck.append(c)
	return deck

## Load card pool for a class (excludes starter cards).
static func load_card_pool(class_name_str: String) -> Array[CardData]:
	var pool: Array[CardData] = []
	var config = get_class_config(class_name_str)
	if config.is_empty():
		return pool
	var pool_class: String = config["card_pool_class"]

	# Collect starter card names to exclude
	var starter_names := {}
	for entry in config["starting_deck"]:
		var card_data = load(entry["card"]) as CardData
		if card_data:
			starter_names[card_data.card_name] = true

	return CardRegistry.get_class_pool(pool_class, starter_names)
