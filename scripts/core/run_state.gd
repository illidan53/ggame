extends Node

## Singleton autoload — persists run state across scene transitions

var map: MapData = null
var current_layer: int = -1
var current_node: int = 0
var player_hp: int = 80
var player_max_hp: int = 80
var gold: int = 0
var deck: Array[CardInstance] = []
var combat_log: Array[String] = []

## Set after battle to signal result back to map
var last_combat_result: String = ""  # "victory", "defeat", ""

func start_new_run(seed_value: int = 0) -> void:
	if seed_value == 0:
		seed_value = randi()
	map = MapGenerator.generate(seed_value)
	current_layer = -1
	current_node = 0
	player_hp = 80
	player_max_hp = 80
	gold = 0
	combat_log.clear()
	last_combat_result = ""
	# Build starting deck
	deck = _make_starting_deck()

func _make_starting_deck() -> Array[CardInstance]:
	var strike = load("res://resources/cards/strike.tres") as CardData
	var defend = load("res://resources/cards/defend.tres") as CardData
	var bash = load("res://resources/cards/bash.tres") as CardData
	var d: Array[CardInstance] = []
	var id := 0
	for i in 5:
		var c = CardInstance.new(strike)
		c.instance_id = id; id += 1
		d.append(c)
	for i in 4:
		var c = CardInstance.new(defend)
		c.instance_id = id; id += 1
		d.append(c)
	var b = CardInstance.new(bash)
	b.instance_id = id
	d.append(b)
	return d

func get_enemies_for_node(node_type: String) -> Array[EnemyData]:
	var enemies: Array[EnemyData] = []
	match node_type:
		"combat":
			var pool: Array[EnemyData] = [
				load("res://resources/enemies/slime.tres"),
				load("res://resources/enemies/goblin.tres"),
			]
			enemies.append(pool[randi() % pool.size()])
			if randf() > 0.5:
				enemies.append(pool[randi() % pool.size()])
		"elite":
			var pool: Array[EnemyData] = [
				load("res://resources/enemies/skeleton.tres"),
				load("res://resources/enemies/bat_swarm.tres"),
			]
			enemies.append(pool[randi() % pool.size()])
		"boss":
			enemies.append(load("res://resources/enemies/skeleton.tres"))
	return enemies
