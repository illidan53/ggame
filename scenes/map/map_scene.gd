extends Control

## Terminal-style map scene with reward, shop, and rest flows

@onready var output: RichTextLabel = %Output
@onready var input: LineEdit = %Input

enum State { MAP, REWARD_CARDS, SHOP, REST, EVENT }
var current_state: State = State.MAP

# Reward flow
var reward_cards: Array[CardData] = []

# Shop flow
var shop_cards: Array[CardData] = []
var shop_prices: Dictionary = {}

# Event flow
var current_event: String = ""
var event_choices: Array[Dictionary] = []

func _ready() -> void:
	input.text_submitted.connect(_on_input_submitted)
	input.keep_editing_on_text_submit = true
	input.grab_focus()
	if RunState.map == null:
		_start_run()
	else:
		_handle_combat_return()

func _start_run() -> void:
	RunState.start_new_run()
	RunState.combat_log.clear()
	current_state = State.MAP
	_log("=== NEW RUN ===")
	_log("A 10-layer dungeon stretches before you...")
	_log("Type 'go <node#>' to choose your path.")
	_log("")
	_show_available_nodes()
	_refresh_display()

# --- Combat Return ---

func _handle_combat_return() -> void:
	var result = RunState.last_combat_result
	RunState.last_combat_result = ""
	if result == "victory":
		_log("[color=green]Victory![/color]")
		# Determine combat type for rewards
		var node = RunState.map.layers[RunState.current_layer][RunState.current_node]
		var gold = RewardGenerator.roll_gold(node.node_type, randi())
		RunState.gold += gold
		_log("Gained %d gold. (Total: %d)" % [gold, RunState.gold])

		if node.node_type == "elite":
			var available = RelicSystem.get_available_relics(
				EventSystem.ALL_RELICS, RunState.relics)
			if not available.is_empty():
				var rng = RandomNumberGenerator.new()
				rng.seed = randi()
				var relic = available[rng.randi_range(0, available.size() - 1)]
				RunState.relics.append(relic)
				_log("Found relic: [color=yellow]%s[/color]" % relic)

		# Offer card rewards
		var pool = _load_card_pool()
		reward_cards = RewardGenerator.roll_card_rewards(pool, node.node_type, randi())
		if not reward_cards.is_empty():
			current_state = State.REWARD_CARDS
			_log("")
			_log("[color=yellow]Choose a card reward (or 'skip'):[/color]")
			for i in reward_cards.size():
				var c = reward_cards[i]
				_log("  [%d] %s (%s, %s) — %s" % [i + 1, c.card_name, c.rarity, c.card_type, c.effect_text])
			_refresh_display()
			return

		_post_reward()
	elif result == "defeat":
		_log("[color=red]You have been defeated...[/color]")
		_log("")
		_log("[color=red]=== GAME OVER ===[/color]")
		_log("HP: 0/%d | Gold: %d | Layer: %d" % [RunState.player_max_hp, RunState.gold, RunState.current_layer + 1])
		SaveSystem.delete_save()
		_log("Type 'menu' to return to main menu.")
		_refresh_display()
	else:
		current_state = State.MAP
		if RunState.current_layer < 9:
			_show_available_nodes()
		_refresh_display()

func _post_reward() -> void:
	current_state = State.MAP
	_log("HP: %d/%d" % [RunState.player_hp, RunState.player_max_hp])
	if RunState.current_layer >= 9:
		_log("")
		_log("[color=green]=== RUN COMPLETE — YOU WIN! ===[/color]")
		_log("HP: %d/%d | Gold: %d" % [RunState.player_hp, RunState.player_max_hp, RunState.gold])
		SaveSystem.delete_save()
		_log("Type 'menu' to return to main menu.")
	else:
		_log("")
		_show_available_nodes()
	_refresh_display()

# --- Input ---

func _on_input_submitted(text: String) -> void:
	input.clear()
	var parts = text.strip_edges().to_lower().split(" ", false)
	if parts.is_empty():
		return

	match current_state:
		State.MAP:
			_handle_map_input(parts)
		State.REWARD_CARDS:
			_handle_reward_input(parts)
		State.SHOP:
			_handle_shop_input(parts)
		State.REST:
			_handle_rest_input(parts)
		State.EVENT:
			_handle_event_input(parts)

func _handle_map_input(parts: Array) -> void:
	match parts[0]:
		"go":
			if parts.size() < 2:
				_log("Usage: go <node#>")
				_refresh_display()
				return
			_select_node(parts[1].to_int() - 1)
		"map":
			_show_full_map()
			_refresh_display()
		"help":
			_log("[color=yellow]Commands:[/color]")
			_log("  go <node#>  — Move to a node")
			_log("  map         — Show full map")
			_log("  deck        — View your deck")
			_log("  restart     — Start a new run")
			_refresh_display()
		"deck":
			_show_deck()
			_refresh_display()
		"restart":
			_start_run()
		"menu":
			get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
		_:
			_log("Unknown command. Type 'help'.")
			_refresh_display()

func _handle_reward_input(parts: Array) -> void:
	if parts[0] == "skip":
		_log("Skipped card reward.")
		_post_reward()
		return
	var idx = parts[0].to_int() - 1
	if idx < 0 or idx >= reward_cards.size():
		_log("Pick 1-%d or 'skip'." % reward_cards.size())
		_refresh_display()
		return
	var picked = reward_cards[idx]
	var card = CardInstance.new(picked)
	card.instance_id = randi()
	RunState.deck.append(card)
	_log("Added [color=white]%s[/color] to your deck." % picked.card_name)
	_post_reward()

func _handle_shop_input(parts: Array) -> void:
	if parts[0] == "leave":
		_log("You leave the shop.")
		current_state = State.MAP
		_log("")
		_show_available_nodes()
		_refresh_display()
		return
	if parts[0] == "remove":
		if RunState.gold < ShopGenerator.CARD_REMOVAL_COST:
			_log("Not enough gold (need %d)." % ShopGenerator.CARD_REMOVAL_COST)
			_refresh_display()
			return
		_log("[color=yellow]Choose a card to remove (1-%d):[/color]" % RunState.deck.size())
		for i in RunState.deck.size():
			_log("  [%d] %s" % [i + 1, RunState.deck[i].data.card_name])
		_refresh_display()
		return
	var idx = parts[0].to_int() - 1
	if idx < 0 or idx >= shop_cards.size():
		_log("Pick 1-%d, 'remove', or 'leave'." % shop_cards.size())
		_refresh_display()
		return
	var card = shop_cards[idx]
	var price = shop_prices.get(card.rarity, 50)
	var result = ShopGenerator.try_purchase(RunState.gold, price)
	if not result.success:
		_log("Not enough gold (need %d, have %d)." % [price, RunState.gold])
		_refresh_display()
		return
	RunState.gold = result.remaining_gold
	var inst = CardInstance.new(card)
	inst.instance_id = randi()
	RunState.deck.append(inst)
	_log("Bought [color=white]%s[/color] for %d gold. (Remaining: %d)" % [card.card_name, price, RunState.gold])
	_refresh_display()

func _handle_rest_input(parts: Array) -> void:
	match parts[0]:
		"rest":
			RunState.player_hp = RestSite.rest(RunState.player_hp, RunState.player_max_hp)
			_log("You rest by the fire. HP: %d/%d" % [RunState.player_hp, RunState.player_max_hp])
			current_state = State.MAP
			_log("")
			_show_available_nodes()
			_refresh_display()
		"upgrade":
			# Show deck for upgrade selection
			var upgradeable: Array = []
			for i in RunState.deck.size():
				if not RunState.deck[i].data.is_upgraded:
					upgradeable.append(i)
			if upgradeable.is_empty():
				_log("No cards to upgrade.")
				_refresh_display()
				return
			_log("[color=yellow]Choose a card to upgrade:[/color]")
			for idx in upgradeable:
				_log("  [%d] %s" % [idx + 1, RunState.deck[idx].data.card_name])
			_refresh_display()
		_:
			# Check if it's a number for upgrade selection
			var idx = parts[0].to_int() - 1
			if idx >= 0 and idx < RunState.deck.size() and not RunState.deck[idx].data.is_upgraded:
				var old_name = RunState.deck[idx].data.card_name
				RunState.deck[idx].data = CardUpgrade.upgrade(RunState.deck[idx].data)
				_log("Upgraded %s → [color=white]%s[/color]" % [old_name, RunState.deck[idx].data.card_name])
				current_state = State.MAP
				_log("")
				_show_available_nodes()
				_refresh_display()
			else:
				_log("Type 'rest' or 'upgrade'.")
				_refresh_display()

# --- Node Selection ---

func _select_node(node_idx: int) -> void:
	var next_layer = RunState.current_layer + 1
	if next_layer >= RunState.map.layers.size():
		_log("Map complete.")
		_refresh_display()
		return

	if node_idx < 0 or node_idx >= RunState.map.layers[next_layer].size():
		_log("Invalid node number.")
		_refresh_display()
		return

	if RunState.current_layer >= 0:
		if not MapNavigator.can_select_node(RunState.map, RunState.current_layer, RunState.current_node, next_layer, node_idx):
			_log("You can't reach that node from here.")
			_refresh_display()
			return

	RunState.current_layer = next_layer
	RunState.current_node = node_idx
	# Auto-save on node entry
	_auto_save()
	var node = RunState.map.layers[RunState.current_layer][RunState.current_node]
	_log("")
	_log(">> Entered Layer %d: [color=white]%s[/color]" % [RunState.current_layer + 1, _format_node_type(node.node_type)])

	match node.node_type:
		"combat", "elite", "boss":
			_log("Entering battle...")
			_refresh_display()
			get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")
			return
		"shop":
			_enter_shop()
			return
		"rest":
			current_state = State.REST
			_log("[color=cyan]A warm campfire crackles nearby.[/color]")
			_log("  'rest'    — Heal %d HP (30%%)" % ceili(RunState.player_max_hp * 0.3))
			_log("  'upgrade' — Upgrade a card")
			_refresh_display()
			return
		"event":
			_enter_event()
			return

	if RunState.current_layer < 9:
		_log("")
		_show_available_nodes()
	else:
		_log("")
		_log("[color=green]=== RUN COMPLETE — YOU WIN! ===[/color]")
		_log("Type 'restart' for a new run.")
	_refresh_display()

func _enter_event() -> void:
	current_state = State.EVENT
	var events = EventSystem.get_event_list()
	current_event = events[randi() % events.size()]
	event_choices = EventSystem.get_choices(current_event)
	_log("[color=yellow]Something unusual catches your eye...[/color]")
	_log("")
	for i in event_choices.size():
		_log("  [%d] %s" % [i + 1, event_choices[i]["text"]])
	_refresh_display()

func _handle_event_input(parts: Array) -> void:
	var idx = parts[0].to_int() - 1
	if idx < 0 or idx >= event_choices.size():
		_log("Pick 1-%d." % event_choices.size())
		_refresh_display()
		return
	var choice = event_choices[idx]
	var data := {
		"hp": RunState.player_hp,
		"max_hp": RunState.player_max_hp,
		"gold": RunState.gold,
		"relics": RunState.relics,
		"deck": RunState.deck,
	}
	var result = EventSystem.execute_choice(current_event, choice["id"], data, randi())
	# Write back
	RunState.player_hp = data["hp"]
	RunState.gold = data["gold"]
	# Log outcome
	if result.has("relic") and result["relic"] != "":
		RunState.relics.append(result["relic"])
		_log("Gained relic: [color=yellow]%s[/color]" % result["relic"])
	if result.has("card") and result["card"] != "":
		_log("Gained card: [color=white]%s[/color]" % result["card"])
	if result.get("blocked", false):
		_log("[color=red]Not enough gold![/color]")
		_refresh_display()
		return
	if result.get("upgrade", false):
		_log("(Card upgrade not yet available in events)")
	_log("HP: %d/%d | Gold: %d" % [RunState.player_hp, RunState.player_max_hp, RunState.gold])
	current_state = State.MAP
	if RunState.current_layer < 9:
		_log("")
		_show_available_nodes()
	_refresh_display()

func _enter_shop() -> void:
	current_state = State.SHOP
	shop_prices = ShopGenerator.generate_prices(randi())
	var pool = _load_card_pool()
	# Offer 3 cards (mixed rarities)
	shop_cards = []
	var rng = RandomNumberGenerator.new()
	rng.seed = randi()
	for rarity in ["Common", "Uncommon", "Rare"]:
		var filtered = pool.filter(func(c): return c.rarity == rarity)
		if not filtered.is_empty():
			shop_cards.append(filtered[rng.randi_range(0, filtered.size() - 1)])
	_log("[color=green]Welcome to the shop! Gold: %d[/color]" % RunState.gold)
	for i in shop_cards.size():
		var c = shop_cards[i]
		var price = shop_prices.get(c.rarity, 50)
		_log("  [%d] %s (%s) — %s [%d gold]" % [i + 1, c.card_name, c.rarity, c.effect_text, price])
	_log("  'remove' — Remove a card [%d gold]" % ShopGenerator.CARD_REMOVAL_COST)
	_log("  'leave'  — Leave shop")
	_refresh_display()

# --- Display Helpers ---

func _show_available_nodes() -> void:
	var next_layer = RunState.current_layer + 1
	if next_layer >= RunState.map.layers.size():
		_log("You have reached the end of the map.")
		return
	_log("[color=yellow]Layer %d — Choose a node:[/color]" % (next_layer + 1))
	if RunState.current_layer < 0:
		for i in RunState.map.layers[0].size():
			var node = RunState.map.layers[0][i]
			_log("  [%d] %s" % [i + 1, _format_node_type(node.node_type)])
	else:
		var source = RunState.map.layers[RunState.current_layer][RunState.current_node]
		for conn in source.connections:
			var node = RunState.map.layers[next_layer][conn]
			_log("  [%d] %s" % [conn + 1, _format_node_type(node.node_type)])

func _show_full_map() -> void:
	_log("")
	_log("[color=yellow]--- FULL MAP ---[/color]")
	# Each node gets a fixed-width column slot for alignment
	var col_width := 12
	var max_nodes := 4

	for layer_idx in RunState.map.layers.size():
		var layer = RunState.map.layers[layer_idx]
		var node_count = layer.size()
		# Center nodes within max_nodes columns
		var padding = (max_nodes - node_count) * col_width / 2

		# Build node row
		var row = " ".repeat(padding)
		for i in node_count:
			var node = layer[i]
			var label = _short_type(node.node_type)
			var is_current = (layer_idx == RunState.current_layer and i == RunState.current_node)
			var is_past = (layer_idx < RunState.current_layer) or (layer_idx == RunState.current_layer and not is_current)
			var is_future = layer_idx > RunState.current_layer or (RunState.current_layer == -1)

			if is_current:
				label = "[color=green][%s][/color]" % label
			elif is_past:
				label = "[color=gray]%s[/color]" % label
			else:
				label = "%s" % label
			# Pad each column
			row += _center_text(label, col_width)

		var layer_label = "L%02d" % (layer_idx + 1)
		if layer_idx == RunState.current_layer:
			layer_label = "[color=green]%s[/color]" % layer_label
		_log("  %s %s" % [layer_label, row])

		# Draw connection lines between this layer and next
		if layer_idx < 9:
			var next_layer = RunState.map.layers[layer_idx + 1]
			var next_count = next_layer.size()
			var next_padding = (max_nodes - next_count) * col_width / 2
			# Build a connection line showing which nodes connect
			var conn_chars: Array[String] = []
			for _c in max_nodes * col_width + 4:
				conn_chars.append(" ")

			for i in node_count:
				var src_x = padding + i * col_width + col_width / 2
				var node = layer[i]
				for conn in node.connections:
					var dst_x = next_padding + conn * col_width + col_width / 2
					# Draw a simple connector character at midpoint
					var mid_x = (src_x + dst_x) / 2
					if mid_x >= 0 and mid_x < conn_chars.size():
						if src_x < dst_x:
							conn_chars[mid_x] = "/"
						elif src_x > dst_x:
							conn_chars[mid_x] = "\\"
						else:
							conn_chars[mid_x] = "|"
					# Also mark source and dest vertical
					if src_x >= 0 and src_x < conn_chars.size():
						conn_chars[src_x] = "|" if conn_chars[src_x] == " " else conn_chars[src_x]

			var conn_line = "[color=gray]       %s[/color]" % "".join(conn_chars).rstrip(" ")
			if conn_line.strip_edges() != "[color=gray][/color]":
				_log(conn_line)

func _short_type(node_type: String) -> String:
	match node_type:
		"combat": return "Bat"
		"elite": return "[color=red]Eli[/color]"
		"shop": return "[color=green]Shp[/color]"
		"rest": return "[color=cyan]Rst[/color]"
		"event": return "[color=yellow]Evt[/color]"
		"boss": return "[color=red]BOS[/color]"
		_: return "???"

func _center_text(text: String, width: int) -> String:
	# Strip BBCode for length calculation
	var plain = text
	while plain.find("[") != -1:
		var start = plain.find("[")
		var end = plain.find("]", start)
		if end == -1:
			break
		plain = plain.substr(0, start) + plain.substr(end + 1)
	var pad_total = max(0, width - plain.length())
	var pad_left = pad_total / 2
	var pad_right = pad_total - pad_left
	return " ".repeat(pad_left) + text + " ".repeat(pad_right)

func _show_deck() -> void:
	_log("")
	_log("[color=yellow]--- YOUR DECK (%d cards) ---[/color]" % RunState.deck.size())
	for i in RunState.deck.size():
		var d = RunState.deck[i].data
		var cost_str = "X" if d.cost == -1 else str(d.cost)
		_log("  %s (%s) — %s [%s]" % [d.card_name, cost_str, d.effect_text, d.rarity])

func _format_node_type(node_type: String) -> String:
	match node_type:
		"combat": return "Combat"
		"elite": return "[color=red]Elite[/color]"
		"shop": return "[color=green]Shop[/color]"
		"rest": return "[color=cyan]Rest[/color]"
		"event": return "[color=yellow]Event[/color]"
		"boss": return "[color=red]BOSS[/color]"
		_: return node_type

func _refresh_display() -> void:
	var lines: Array[String] = []
	lines.append("[color=gray]═══════════════════════════════════════[/color]")

	if RunState.current_layer >= 0:
		var node = RunState.map.layers[RunState.current_layer][RunState.current_node]
		lines.append("[color=yellow]Position:[/color] Layer %d — %s  |  HP: %d/%d  |  Gold: %d  |  Deck: %d" % [
			RunState.current_layer + 1, _format_node_type(node.node_type),
			RunState.player_hp, RunState.player_max_hp, RunState.gold, RunState.deck.size()])
	else:
		lines.append("[color=yellow]Position:[/color] Map entrance  |  HP: %d/%d  |  Gold: %d" % [
			RunState.player_hp, RunState.player_max_hp, RunState.gold])

	lines.append("[color=gray]═══════════════════════════════════════[/color]")

	lines.append("")
	var log_start = max(0, RunState.combat_log.size() - 18)
	for i in range(log_start, RunState.combat_log.size()):
		lines.append(RunState.combat_log[i])
	lines.append("")

	output.text = ""
	output.bbcode_enabled = true
	output.text = "\n".join(lines)

func _log(msg: String) -> void:
	RunState.combat_log.append(msg)

func _auto_save() -> void:
	var run = RunData.new()
	run.player_hp = RunState.player_hp
	run.player_max_hp = RunState.player_max_hp
	run.gold = RunState.gold
	run.deck = RunState.deck
	run.relics = RunState.relics
	run.potions = RunState.potions
	run.map = RunState.map
	run.current_layer = RunState.current_layer
	run.current_node = RunState.current_node
	run.seed_value = 0  # Map already generated
	SaveSystem.save_game(run)

func _load_card_pool() -> Array[CardData]:
	var pool: Array[CardData] = []
	var dir = DirAccess.open("res://resources/cards/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var card = load("res://resources/cards/" + file_name) as CardData
				if card and card.card_name not in ["Strike", "Defend", "Bash"]:
					pool.append(card)
			file_name = dir.get_next()
	return pool
