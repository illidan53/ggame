extends Control

## Terminal-style map scene — displays map and handles node selection
## Uses RunState autoload to persist state across scene transitions

@onready var output: RichTextLabel = %Output
@onready var input: LineEdit = %Input

func _ready() -> void:
	input.text_submitted.connect(_on_input_submitted)
	if RunState.map == null:
		_start_run()
	else:
		# Returning from battle
		_handle_combat_return()

func _start_run() -> void:
	RunState.start_new_run()
	RunState.combat_log.clear()
	_log("=== NEW RUN ===")
	_log("A 10-layer dungeon stretches before you...")
	_log("Type 'go <node#>' to choose your path.")
	_log("")
	_show_available_nodes()
	_refresh_display()

func _handle_combat_return() -> void:
	var result = RunState.last_combat_result
	RunState.last_combat_result = ""
	if result == "victory":
		_log("[color=green]Victory! You press onward.[/color]")
		_log("HP: %d/%d" % [RunState.player_hp, RunState.player_max_hp])
		if RunState.current_layer < 9:
			_log("")
			_show_available_nodes()
		else:
			_log("")
			_log("[color=green]=== RUN COMPLETE — YOU WIN! ===[/color]")
			_log("Type 'restart' for a new run.")
	elif result == "defeat":
		_log("[color=red]You have been defeated...[/color]")
		_log("")
		_log("[color=red]=== GAME OVER ===[/color]")
		_log("Type 'restart' for a new run.")
	else:
		# No result — just show available nodes
		if RunState.current_layer < 9:
			_show_available_nodes()
	_refresh_display()

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

func _on_input_submitted(text: String) -> void:
	input.clear()
	var parts = text.strip_edges().to_lower().split(" ", false)
	if parts.is_empty():
		return

	match parts[0]:
		"go":
			if parts.size() < 2:
				_log("Usage: go <node#>")
				_refresh_display()
				return
			var node_idx = parts[1].to_int() - 1
			_select_node(node_idx)

		"map":
			_show_full_map()
			_refresh_display()

		"help":
			_log("[color=yellow]Commands:[/color]")
			_log("  go <node#>  — Move to a node")
			_log("  map         — Show full map")
			_log("  restart     — Start a new run")
			_log("  help        — Show this help")
			_refresh_display()

		"restart":
			_start_run()

		_:
			_log("Unknown command. Type 'help'.")
			_refresh_display()

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
	var node = RunState.map.layers[RunState.current_layer][RunState.current_node]
	_log("")
	_log(">> Entered Layer %d: [color=white]%s[/color]" % [RunState.current_layer + 1, _format_node_type(node.node_type)])

	match node.node_type:
		"combat", "elite", "boss":
			_log("Entering battle...")
			_refresh_display()
			# Transition to battle scene
			get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")
			return
		"shop":
			_log("[color=green]A merchant displays their wares.[/color]")
			_log("[color=gray](Shop not yet implemented — skipping)[/color]")
		"rest":
			_log("[color=cyan]A warm campfire crackles nearby.[/color]")
			var heal = ceili(RunState.player_max_hp * 0.3)
			RunState.player_hp = mini(RunState.player_hp + heal, RunState.player_max_hp)
			_log("You rest and recover. HP: %d/%d" % [RunState.player_hp, RunState.player_max_hp])
		"event":
			_log("[color=yellow]Something unusual catches your eye...[/color]")
			_log("[color=gray](Events not yet implemented — skipping)[/color]")

	if RunState.current_layer < 9:
		_log("")
		_show_available_nodes()
	else:
		_log("")
		_log("[color=green]=== RUN COMPLETE — YOU WIN! ===[/color]")
		_log("Type 'restart' for a new run.")

	_refresh_display()

func _show_full_map() -> void:
	_log("")
	_log("[color=yellow]--- FULL MAP ---[/color]")
	for layer_idx in RunState.map.layers.size():
		var layer = RunState.map.layers[layer_idx]
		var marker = " <<" if layer_idx == RunState.current_layer else ""
		var nodes_str: Array[String] = []
		for i in layer.size():
			var node = layer[i]
			var prefix = "[%d]" % (i + 1)
			if layer_idx == RunState.current_layer and i == RunState.current_node:
				nodes_str.append("[color=green]%s %s[/color]" % [prefix, _format_node_type(node.node_type)])
			else:
				nodes_str.append("%s %s" % [prefix, _format_node_type(node.node_type)])
		_log("  L%02d: %s%s" % [layer_idx + 1, "  ".join(nodes_str), marker])

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
		lines.append("[color=yellow]Position:[/color] Layer %d — %s  |  HP: %d/%d" % [
			RunState.current_layer + 1, _format_node_type(node.node_type),
			RunState.player_hp, RunState.player_max_hp])
	else:
		lines.append("[color=yellow]Position:[/color] Map entrance  |  HP: %d/%d" % [
			RunState.player_hp, RunState.player_max_hp])

	lines.append("[color=gray]═══════════════════════════════════════[/color]")

	lines.append("")
	var log_start = max(0, RunState.combat_log.size() - 15)
	for i in range(log_start, RunState.combat_log.size()):
		lines.append(RunState.combat_log[i])
	lines.append("")

	output.text = ""
	output.bbcode_enabled = true
	output.text = "\n".join(lines)

func _log(msg: String) -> void:
	RunState.combat_log.append(msg)
