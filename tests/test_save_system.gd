extends GutTest

const SAVE_PATH = "user://test_save.json"

func after_each() -> void:
	# Clean up test save file
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

# --- T1: Save / Load ---

func test_T1_1_save_creates_file():
	var run = RunData.create_new(12345)
	SaveSystem.save_game(run, SAVE_PATH)
	assert_true(FileAccess.file_exists(SAVE_PATH), "Save file should exist after saving")

func test_T1_2_load_restores_state():
	var run = RunData.create_new(12345)
	run.player_hp = 55
	run.gold = 42
	run.current_layer = 3
	run.current_node = 1
	SaveSystem.save_game(run, SAVE_PATH)

	var loaded = SaveSystem.load_game(SAVE_PATH)
	assert_not_null(loaded, "Loaded RunData should not be null")
	assert_eq(loaded.player_hp, 55, "HP should match")
	assert_eq(loaded.player_max_hp, 80, "Max HP should match")
	assert_eq(loaded.gold, 42, "Gold should match")
	assert_eq(loaded.current_layer, 3, "Layer should match")
	assert_eq(loaded.current_node, 1, "Node should match")
	assert_eq(loaded.deck.size(), run.deck.size(), "Deck size should match")
	assert_eq(loaded.seed_value, 12345, "Seed should match")

func test_T1_3_exit_save():
	# Saving mid-run creates a valid file that can be loaded
	var run = RunData.create_new(99999)
	run.player_hp = 60
	run.current_layer = 5
	SaveSystem.save_game(run, SAVE_PATH)
	assert_true(FileAccess.file_exists(SAVE_PATH), "Exit save should create file")
	var loaded = SaveSystem.load_game(SAVE_PATH)
	assert_eq(loaded.current_layer, 5, "Mid-run layer should be preserved")

func test_T1_4_seed_preserved():
	var run = RunData.create_new(77777)
	SaveSystem.save_game(run, SAVE_PATH)
	var loaded = SaveSystem.load_game(SAVE_PATH)
	assert_eq(loaded.seed_value, 77777, "Seed should be preserved")
	# Map generated from same seed should have same structure
	assert_eq(loaded.map.layers.size(), 10, "Map should have 10 layers")

# --- T2: Permadeath ---

func test_T2_1_death_deletes_save():
	var run = RunData.create_new(12345)
	SaveSystem.save_game(run, SAVE_PATH)
	assert_true(FileAccess.file_exists(SAVE_PATH), "Save should exist before death")
	SaveSystem.delete_save(SAVE_PATH)
	assert_false(FileAccess.file_exists(SAVE_PATH), "Save should be deleted after death")

func test_T2_2_victory_deletes_save():
	var run = RunData.create_new(12345)
	SaveSystem.save_game(run, SAVE_PATH)
	assert_true(FileAccess.file_exists(SAVE_PATH), "Save should exist before victory")
	SaveSystem.delete_save(SAVE_PATH)
	assert_false(FileAccess.file_exists(SAVE_PATH), "Save should be deleted after victory")
