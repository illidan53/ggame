extends GutTest

# --- Helpers ---

func _make_run_data() -> Dictionary:
	return {
		"hp": 80,
		"max_hp": 80,
		"gold": 100,
		"relics": [] as Array[String],
		"deck": [] as Array[CardInstance],
	}

# --- T4: Random Events ---

# Mysterious Altar
func test_T4_1_blood_offering():
	var data = _make_run_data()
	var result = EventSystem.execute_choice("mysterious_altar", "blood_offering", data, 12345)
	assert_eq(data["hp"], 70, "Blood Offering should lose 10 HP")
	assert_true(result.has("relic"), "Should gain a relic")
	assert_true(result["relic"] != "", "Relic name should not be empty")

func test_T4_2_walk_away():
	var data = _make_run_data()
	EventSystem.execute_choice("mysterious_altar", "walk_away", data, 12345)
	assert_eq(data["hp"], 80, "Walk Away should not change HP")

# Wandering Merchant
func test_T4_3_trade():
	var data = _make_run_data()
	var result = EventSystem.execute_choice("wandering_merchant", "trade", data, 12345)
	assert_eq(data["gold"], 50, "Trade should cost 50 gold")
	assert_true(result.has("card"), "Should gain a card")

func test_T4_4_rob():
	var data = _make_run_data()
	EventSystem.execute_choice("wandering_merchant", "rob", data, 12345)
	assert_eq(data["gold"], 130, "Rob should gain 30 gold")
	assert_eq(data["hp"], 72, "Rob should take 8 damage")

func test_T4_5_leave():
	var data = _make_run_data()
	EventSystem.execute_choice("wandering_merchant", "leave", data, 12345)
	assert_eq(data["gold"], 100, "Leave should not change gold")
	assert_eq(data["hp"], 80, "Leave should not change HP")

# Training Dummy
func test_T4_6_practice():
	var data = _make_run_data()
	var result = EventSystem.execute_choice("training_dummy", "practice", data, 12345)
	assert_true(result.get("upgrade", false), "Practice should signal upgrade")

func test_T4_7_dismantle():
	var data = _make_run_data()
	EventSystem.execute_choice("training_dummy", "dismantle", data, 12345)
	assert_eq(data["gold"], 115, "Dismantle should gain 15 gold")

# Edge case
func test_T4_8_insufficient_gold_trade():
	var data = _make_run_data()
	data["gold"] = 30
	var result = EventSystem.execute_choice("wandering_merchant", "trade", data, 12345)
	assert_eq(data["gold"], 30, "Gold should be unchanged if insufficient")
	assert_true(result.get("blocked", false), "Should signal blocked")
