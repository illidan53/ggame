extends Control

## Terminal-style main menu

@onready var output: RichTextLabel = %Output
@onready var input: LineEdit = %Input

func _ready() -> void:
	input.text_submitted.connect(_on_input_submitted)
	input.keep_editing_on_text_submit = true
	input.grab_focus()
	_show_menu()

func _show_menu() -> void:
	var lines: Array[String] = []
	lines.append("")
	lines.append("[color=gray]═══════════════════════════════════════[/color]")
	lines.append("")
	lines.append("        [color=red]D A R K P A T H[/color]")
	lines.append("")
	lines.append("    [color=gray]A Roguelike Deckbuilder[/color]")
	lines.append("")
	lines.append("[color=gray]═══════════════════════════════════════[/color]")
	lines.append("")

	if SaveSystem.has_save():
		lines.append("  [color=white][1] Continue[/color]")
	else:
		lines.append("  [color=gray][1] Continue (no save)[/color]")
	lines.append("  [color=white][2] New Game[/color]")
	lines.append("  [color=white][3] Quit[/color]")
	lines.append("")

	output.text = ""
	output.bbcode_enabled = true
	output.text = "\n".join(lines)

func _on_input_submitted(text: String) -> void:
	input.clear()
	var cmd = text.strip_edges().to_lower()

	match cmd:
		"1", "continue":
			if SaveSystem.has_save():
				var run = SaveSystem.load_game()
				if run:
					RunState.map = run.map
					RunState.current_layer = run.current_layer
					RunState.current_node = run.current_node
					RunState.player_hp = run.player_hp
					RunState.player_max_hp = run.player_max_hp
					RunState.gold = run.gold
					RunState.deck = run.deck
					RunState.relics = run.relics
					RunState.potions = run.potions
					RunState.combat_log.clear()
					get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
		"2", "new", "new game":
			RunState.map = null  # Signal map scene to start fresh
			get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
		"3", "quit", "exit":
			get_tree().quit()
