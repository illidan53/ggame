extends Node

## Singleton autoload — persists run state across scene transitions

var map: MapData = null
var current_layer: int = -1
var current_node: int = 0
var player_hp: int = 80
var player_max_hp: int = 80
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
	combat_log.clear()
	last_combat_result = ""

func get_enemies_for_node(node_type: String) -> Array[EnemyData]:
	var enemies: Array[EnemyData] = []
	match node_type:
		"combat":
			# 1-2 random normal enemies
			var pool: Array[EnemyData] = [
				load("res://resources/enemies/slime.tres"),
				load("res://resources/enemies/goblin.tres"),
			]
			enemies.append(pool[randi() % pool.size()])
			if randf() > 0.5:
				enemies.append(pool[randi() % pool.size()])
		"elite":
			# Tougher: skeleton or bat_swarm
			var pool: Array[EnemyData] = [
				load("res://resources/enemies/skeleton.tres"),
				load("res://resources/enemies/bat_swarm.tres"),
			]
			enemies.append(pool[randi() % pool.size()])
		"boss":
			# Placeholder: use skeleton as stand-in boss until P4
			enemies.append(load("res://resources/enemies/skeleton.tres"))
	return enemies
