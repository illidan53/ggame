class_name RunData
extends RefCounted

## Persistent state for a single run, serializable for save/load

var player_hp: int = 80
var player_max_hp: int = 80
var gold: int = 0
var deck: Array[CardInstance] = []
var relics: Array[String] = []
var potions: Array[String] = []
var map: MapData = null
var current_layer: int = -1
var current_node: int = 0
var seed_value: int = 0
var character_class: String = "Warrior"
var current_act: int = 1       # 1-3, three acts per full run
const TOTAL_ACTS: int = 3

## Create a fresh run. Defaults to Warrior for backward compatibility.
static func create_new(seed_val: int = 0, class_name_str: String = "Warrior") -> RunData:
	var data = RunData.new()
	if seed_val == 0:
		seed_val = randi()
	data.seed_value = seed_val
	data.character_class = class_name_str
	data.map = MapGenerator.generate(seed_val)

	var class_config = ClassData.get_class_config(class_name_str)
	if not class_config.is_empty():
		data.player_hp = class_config["max_hp"]
		data.player_max_hp = class_config["max_hp"]
		data.deck = ClassData.make_starting_deck(class_name_str)
		var starting_relic: String = class_config["starting_relic"]
		if starting_relic != "":
			data.relics.append(starting_relic)
	else:
		# Fallback to legacy Warrior deck
		data.deck = _make_starting_deck()
	return data

## Legacy starting deck builder (kept for backward compatibility)
static func _make_starting_deck() -> Array[CardInstance]:
	var strike = load("res://resources/cards/strike.tres") as CardData
	var defend = load("res://resources/cards/defend.tres") as CardData
	var bash = load("res://resources/cards/bash.tres") as CardData
	var deck: Array[CardInstance] = []
	var id := 0
	for i in 5:
		var c = CardInstance.new(strike)
		c.instance_id = id; id += 1
		deck.append(c)
	for i in 4:
		var c = CardInstance.new(defend)
		c.instance_id = id; id += 1
		deck.append(c)
	var b = CardInstance.new(bash)
	b.instance_id = id
	deck.append(b)
	return deck

## Serialize to Dictionary for save/load
func to_dict() -> Dictionary:
	var deck_data: Array[Dictionary] = []
	for card in deck:
		deck_data.append({
			"card_name": card.data.card_name,
			"instance_id": card.instance_id,
			"is_upgraded": card.data.is_upgraded,
		})
	return {
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"gold": gold,
		"deck": deck_data,
		"relics": relics,
		"potions": potions,
		"current_layer": current_layer,
		"current_node": current_node,
		"seed_value": seed_value,
	}

## Deserialize from Dictionary
static func from_dict(data: Dictionary, card_pool: Dictionary) -> RunData:
	var run = RunData.new()
	run.player_hp = data.get("player_hp", 80)
	run.player_max_hp = data.get("player_max_hp", 80)
	run.gold = data.get("gold", 0)
	var relics_raw = data.get("relics", [])
	run.relics = [] as Array[String]
	for r in relics_raw:
		run.relics.append(r)
	var potions_raw = data.get("potions", [])
	run.potions = [] as Array[String]
	for p in potions_raw:
		run.potions.append(p)
	run.current_layer = data.get("current_layer", -1)
	run.current_node = data.get("current_node", 0)
	run.seed_value = data.get("seed_value", 0)
	run.map = MapGenerator.generate(run.seed_value)

	# Reconstruct deck from card names
	var deck_data = data.get("deck", [])
	run.deck = [] as Array[CardInstance]
	for entry in deck_data:
		var card_name = entry.get("card_name", "")
		if card_pool.has(card_name):
			var card = CardInstance.new(card_pool[card_name])
			card.instance_id = entry.get("instance_id", 0)
			run.deck.append(card)

	return run
