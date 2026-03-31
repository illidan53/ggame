class_name SaveSystem
extends RefCounted

const DEFAULT_SAVE_PATH = "user://save.json"

## Save RunData to a JSON file
static func save_game(run: RunData, path: String = DEFAULT_SAVE_PATH) -> void:
	var data = run.to_dict()
	var json_string = JSON.stringify(data, "  ")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

## Load RunData from a JSON file. Returns null if file doesn't exist or is invalid.
static func load_game(path: String = DEFAULT_SAVE_PATH) -> RunData:
	if not FileAccess.file_exists(path):
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return null
	var data = json.data
	if not data is Dictionary:
		return null

	var card_pool = CardRegistry.get_card_lookup()
	return RunData.from_dict(data, card_pool)

## Delete save file (permadeath)
static func delete_save(path: String = DEFAULT_SAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

## Check if a save file exists
static func has_save(path: String = DEFAULT_SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)
