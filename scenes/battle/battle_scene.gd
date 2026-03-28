extends Control

## Terminal-style battle scene — thin UI layer over BattleManager

@onready var output: RichTextLabel = %Output
@onready var input: LineEdit = %Input

var state: CombatState
var combat_log: Array[String] = []

func _ready() -> void:
	input.text_submitted.connect(_on_input_submitted)
	_start_combat()

# --- Combat Setup ---

var _use_run_state: bool = false

func _start_combat() -> void:
	var strike_data = load("res://resources/cards/strike.tres") as CardData
	var defend_data = load("res://resources/cards/defend.tres") as CardData
	var bash_data = load("res://resources/cards/bash.tres") as CardData

	var deck: Array[CardInstance] = []
	var id_counter := 0
	for i in 5:
		var c = CardInstance.new(strike_data)
		c.instance_id = id_counter; id_counter += 1
		deck.append(c)
	for i in 4:
		var c = CardInstance.new(defend_data)
		c.instance_id = id_counter; id_counter += 1
		deck.append(c)
	var bash_card = CardInstance.new(bash_data)
	bash_card.instance_id = id_counter
	deck.append(bash_card)

	# Use RunState if available (map → battle transition)
	var player_hp := 80
	var enemy_datas: Array[EnemyData] = []
	if RunState != null and RunState.map != null:
		_use_run_state = true
		player_hp = RunState.player_hp
		var node = RunState.map.layers[RunState.current_layer][RunState.current_node]
		enemy_datas = RunState.get_enemies_for_node(node.node_type)
	if enemy_datas.is_empty():
		enemy_datas = [
			load("res://resources/enemies/slime.tres") as EnemyData,
			load("res://resources/enemies/goblin.tres") as EnemyData,
		]

	state = BattleManager.create_combat(player_hp, 3, deck, enemy_datas)

	_log("=== COMBAT START ===")
	_log("You face: %s" % _enemy_names())
	_begin_player_turn()

# --- Turn Flow (delegates to BattleManager) ---

func _begin_player_turn() -> void:
	var log = BattleManager.begin_player_turn(state)
	_log("")
	for msg in log:
		_log(msg)
	_refresh_display()

func _end_player_turn() -> void:
	_log("You end your turn.")
	var log = BattleManager.end_turn(state)
	for msg in log:
		_log(msg)

	if state.is_combat_over:
		_show_combat_end()
		return

	_begin_player_turn()

func _show_combat_end() -> void:
	_log("")
	if state.combat_result == "victory":
		_log("[color=green]*** VICTORY ***[/color]")
	else:
		_log("[color=red]*** DEFEAT ***[/color]")

	if _use_run_state:
		RunState.player_hp = state.player.hp
		RunState.last_combat_result = state.combat_result
		_log("Returning to map...")
		_refresh_display()
		# Delay briefly so player sees the result
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
	else:
		_log("Type 'restart' to play again.")
		_refresh_display()

# --- Player Actions ---

func _play_card(card_index: int, target_index: int) -> void:
	if state.is_combat_over:
		_log("Combat is over.")
		_refresh_display()
		return

	var result = BattleManager.play_card(state, card_index, target_index)
	for msg in result.log:
		_log(msg)

	if state.is_combat_over:
		_show_combat_end()
		return

	_refresh_display()

# --- Input Handling ---

func _on_input_submitted(text: String) -> void:
	input.clear()
	var parts = text.strip_edges().to_lower().split(" ", false)
	if parts.is_empty():
		return

	match parts[0]:
		"help":
			_log("[color=yellow]Commands:[/color]")
			_log("  play <card#> [enemy#]  — Play a card (1-indexed)")
			_log("  end                    — End your turn")
			_log("  hand                   — Show hand details")
			_log("  restart                — Start a new combat")
			_log("  help                   — Show this help")
			_refresh_display()

		"play":
			if parts.size() < 2:
				_log("Usage: play <card#> [enemy#]")
				_refresh_display()
				return
			var card_idx = parts[1].to_int() - 1
			var target_idx = -1
			if parts.size() >= 3:
				target_idx = parts[2].to_int() - 1
			_play_card(card_idx, target_idx)

		"end":
			if state.is_combat_over:
				_log("Combat is over. Type 'restart'.")
				_refresh_display()
				return
			_end_player_turn()

		"hand":
			_log_hand_details()
			_refresh_display()

		"restart":
			combat_log.clear()
			_start_combat()

		_:
			_log("Unknown command. Type 'help'.")
			_refresh_display()

# --- Display (UI only) ---

func _refresh_display() -> void:
	var lines: Array[String] = []

	lines.append("[color=gray]═══════════════════════════════════════[/color]")

	lines.append("[color=yellow]ENEMIES:[/color]")
	for i in state.enemies.size():
		var e = state.enemies[i]
		if not e.is_alive():
			lines.append("  [%d] %s — [color=red]DEAD[/color]" % [i + 1, e.enemy_data.enemy_name])
			continue
		var hp_color = "green" if float(e.hp) / e.max_hp > 0.5 else ("yellow" if float(e.hp) / e.max_hp > 0.25 else "red")
		var block_str = " [color=cyan](%d block)[/color]" % e.block if e.block > 0 else ""
		var intent = EnemyAI.get_intent(e)
		var intent_str = _format_intent(intent)
		var status_str = _format_status(e)
		lines.append("  [%d] %s — [color=%s]%d/%d HP[/color]%s  Intent: %s%s" % [
			i + 1, e.enemy_data.enemy_name, hp_color, e.hp, e.max_hp, block_str, intent_str, status_str
		])

	lines.append("")

	var p = state.player
	var hp_color = "green" if float(p.hp) / p.max_hp > 0.5 else ("yellow" if float(p.hp) / p.max_hp > 0.25 else "red")
	var block_str = " [color=cyan](%d block)[/color]" % p.block if p.block > 0 else ""
	var status_str = _format_status(p)
	lines.append("[color=yellow]PLAYER:[/color] [color=%s]%d/%d HP[/color]%s  Energy: [color=white]%d/%d[/color]%s" % [
		hp_color, p.hp, p.max_hp, block_str, p.energy, p.max_energy, status_str
	])

	lines.append("")
	lines.append("[color=yellow]HAND:[/color]")
	if state.hand.is_empty():
		lines.append("  (empty)")
	else:
		for i in state.hand.size():
			var card = state.hand[i]
			var d = card.data
			var cost_str = "X" if d.cost == -1 else str(d.cost)
			var playable = state.player.energy >= d.cost and d.cost >= 0
			var color = "white" if playable else "gray"
			lines.append("  [color=%s][%d] %s (%s) — %s[/color]" % [
				color, i + 1, d.card_name, cost_str, d.effect_text
			])

	lines.append("")
	lines.append("[color=gray]Draw: %d | Discard: %d | Exhaust: %d[/color]" % [
		state.draw_pile.size(), state.discard_pile.size(), state.exhaust_pile.size()
	])

	lines.append("[color=gray]═══════════════════════════════════════[/color]")

	lines.append("")
	var log_start = max(0, combat_log.size() - 8)
	for i in range(log_start, combat_log.size()):
		lines.append(combat_log[i])

	lines.append("")

	output.text = ""
	output.bbcode_enabled = true
	output.text = "\n".join(lines)

func _format_intent(intent: Dictionary) -> String:
	var type = intent.get("type", "???")
	var value = intent.get("value", 0)
	match type:
		"attack":
			return "[color=red]Attack %d[/color]" % value
		"multi_attack":
			return "[color=red]Attack %d x%d[/color]" % [value, intent.get("hits", 1)]
		"defend":
			return "[color=cyan]Block %d[/color]" % value
		"attack_debuff":
			return "[color=red]Attack %d[/color] + %s" % [value, intent.get("debuff", "?")]
		"buff":
			return "[color=orange]Buff %s[/color]" % intent.get("buff", "?")
		_:
			return type

func _format_status(combatant: Combatant) -> String:
	if combatant.status_effects.is_empty():
		return ""
	var parts: Array[String] = []
	for effect in combatant.status_effects:
		var stacks = combatant.status_effects[effect]
		if stacks > 0:
			parts.append("%s(%d)" % [effect, stacks])
	if parts.is_empty():
		return ""
	return "  [%s]" % ", ".join(parts)

func _log_hand_details() -> void:
	_log("[color=yellow]--- Hand Details ---[/color]")
	for i in state.hand.size():
		var d = state.hand[i].data
		var cost_str = "X" if d.cost == -1 else str(d.cost)
		var details = "[%d] %s | Cost: %s | Type: %s" % [i + 1, d.card_name, cost_str, d.card_type]
		if d.base_damage > 0:
			details += " | Dmg: %d" % d.base_damage
		if d.base_block > 0:
			details += " | Block: %d" % d.base_block
		if not d.keywords.is_empty():
			details += " | Keywords: %s" % ", ".join(d.keywords)
		details += " | Target: %s" % d.target_mode
		_log(details)

func _log(msg: String) -> void:
	combat_log.append(msg)

func _enemy_names() -> String:
	var names: Array[String] = []
	for e in state.enemies:
		names.append(e.enemy_data.enemy_name)
	return ", ".join(names)
