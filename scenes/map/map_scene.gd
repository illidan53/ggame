extends Control

## Terminal-style map scene — displays map and handles node selection

@onready var output: RichTextLabel = %Output
@onready var input: LineEdit = %Input

var map: MapData
var current_layer: int = -1  # -1 = haven't started yet
var current_node: int = 0
var combat_log: Array[String] = []

func _ready() -> void:
	input.text_submitted.connect(_on_input_submitted)
	_start_run()

func _start_run() -> void:
	map = MapGenerator.generate(randi())
	current_layer = -1
	combat_log.clear()
	_log("=== NEW RUN ===")
	_log("A 10-layer dungeon stretches before you...")
	_log("Type 'go <node#>' to choose your path.")
	_log("")
	_show_available_nodes()
	_refresh_display()

func _show_available_nodes() -> void:
	var next_layer = current_layer + 1
	if next_layer >= map.layers.size():
		_log("You have reached the end of the map.")
		return

	_log("[color=yellow]Layer %d — Choose a node:[/color]" % (next_layer + 1))

	if current_layer < 0:
		# First layer: all nodes available
		for i in map.layers[0].size():
			var node = map.layers[0][i]
			_log("  [%d] %s" % [i + 1, _format_node_type(node.node_type)])
	else:
		# Show only connected nodes
		var source = map.layers[current_layer][current_node]
		for conn in source.connections:
			var node = map.layers[next_layer][conn]
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
	var next_layer = current_layer + 1
	if next_layer >= map.layers.size():
		_log("Map complete.")
		_refresh_display()
		return

	# Validate
	if node_idx < 0 or node_idx >= map.layers[next_layer].size():
		_log("Invalid node number.")
		_refresh_display()
		return

	if current_layer >= 0:
		if not MapNavigator.can_select_node(map, current_layer, current_node, next_layer, node_idx):
			_log("You can't reach that node from here.")
			_refresh_display()
			return

	# Move
	current_layer = next_layer
	current_node = node_idx
	var node = map.layers[current_layer][current_node]
	_log("")
	_log(">> Entered Layer %d: [color=white]%s[/color]" % [current_layer + 1, _format_node_type(node.node_type)])

	# Handle node type
	match node.node_type:
		"combat":
			_log("A group of enemies blocks your path!")
			_log("[color=gray](Combat would start here — use battle scene)[/color]")
		"elite":
			_log("[color=red]A powerful foe appears![/color]")
			_log("[color=gray](Elite combat would start here)[/color]")
		"shop":
			_log("[color=green]A merchant displays their wares.[/color]")
			_log("[color=gray](Shop not yet implemented)[/color]")
		"rest":
			_log("[color=cyan]A warm campfire crackles nearby.[/color]")
			_log("[color=gray](Rest site not yet implemented)[/color]")
		"event":
			_log("[color=yellow]Something unusual catches your eye...[/color]")
			_log("[color=gray](Events not yet implemented)[/color]")
		"boss":
			_log("[color=red]The Shadow Lord awaits![/color]")
			_log("[color=gray](Boss fight not yet implemented)[/color]")

	if current_layer < 9:
		_log("")
		_show_available_nodes()
	else:
		_log("")
		_log("[color=green]=== MAP COMPLETE ===[/color]")
		_log("Type 'restart' for a new run.")

	_refresh_display()

func _show_full_map() -> void:
	_log("")
	_log("[color=yellow]--- FULL MAP ---[/color]")
	for layer_idx in map.layers.size():
		var layer = map.layers[layer_idx]
		var marker = " <<" if layer_idx == current_layer else ""
		var nodes_str: Array[String] = []
		for i in layer.size():
			var node = layer[i]
			var prefix = "[%d]" % (i + 1)
			if layer_idx == current_layer and i == current_node:
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

	# Current position
	if current_layer >= 0:
		var node = map.layers[current_layer][current_node]
		lines.append("[color=yellow]Position:[/color] Layer %d — %s" % [
			current_layer + 1, _format_node_type(node.node_type)])
	else:
		lines.append("[color=yellow]Position:[/color] Map entrance")

	lines.append("[color=gray]═══════════════════════════════════════[/color]")

	# Combat log (last 15 lines)
	lines.append("")
	var log_start = max(0, combat_log.size() - 15)
	for i in range(log_start, combat_log.size()):
		lines.append(combat_log[i])
	lines.append("")

	output.text = ""
	output.bbcode_enabled = true
	output.text = "\n".join(lines)

func _log(msg: String) -> void:
	combat_log.append(msg)
