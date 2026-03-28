extends GutTest

# --- T1: Combat Rewards ---

func test_T1_1_normal_combat_gold():
	# Gold reward for normal combat should be in range [10, 20]
	for i in 50:
		var gold = RewardGenerator.roll_gold("combat", i)
		assert_true(gold >= 10 and gold <= 20,
			"Normal combat gold should be 10-20, got %d" % gold)

func test_T1_2_elite_combat_gold():
	# Gold reward for elite combat should be in range [25, 35]
	for i in 50:
		var gold = RewardGenerator.roll_gold("elite", i)
		assert_true(gold >= 25 and gold <= 35,
			"Elite combat gold should be 25-35, got %d" % gold)

func test_T1_3_boss_gold():
	# Boss gold is exactly 50
	var gold = RewardGenerator.roll_gold("boss", 12345)
	assert_eq(gold, 50, "Boss gold should be exactly 50")

func test_T1_4_card_reward_options():
	# 3 cards offered; result has exactly 3 entries
	var card_pool = _load_card_pool()
	var cards = RewardGenerator.roll_card_rewards(card_pool, "combat", 12345)
	assert_eq(cards.size(), 3, "Should offer exactly 3 card rewards")
	# All should be valid CardData
	for card in cards:
		assert_not_null(card, "Card reward should not be null")
		assert_true(card is CardData, "Each reward should be a CardData")

func test_T1_5_rarity_distribution():
	# Over 100 Normal/Elite reward rolls: ~60% Common, ~30% Uncommon, ~10% Rare (±10% tolerance)
	var card_pool = _load_card_pool()
	var counts = {"Common": 0, "Uncommon": 0, "Rare": 0}
	var total := 0
	for i in 300:
		var cards = RewardGenerator.roll_card_rewards(card_pool, "combat", i)
		for card in cards:
			if counts.has(card.rarity):
				counts[card.rarity] += 1
				total += 1

	var common_pct = float(counts["Common"]) / total * 100
	var uncommon_pct = float(counts["Uncommon"]) / total * 100
	var rare_pct = float(counts["Rare"]) / total * 100

	assert_true(common_pct >= 50 and common_pct <= 70,
		"Common should be ~60%%, got %.1f%%" % common_pct)
	assert_true(uncommon_pct >= 20 and uncommon_pct <= 40,
		"Uncommon should be ~30%%, got %.1f%%" % uncommon_pct)
	assert_true(rare_pct >= 0 and rare_pct <= 20,
		"Rare should be ~10%%, got %.1f%%" % rare_pct)

# --- T2: Elite Rewards ---

func test_T2_1_elite_drops_relic():
	# After Elite victory, exactly 1 relic name is returned
	var relic = RewardGenerator.roll_relic_reward(12345)
	assert_true(relic != "", "Elite should drop a relic name")

func test_T2_2_boss_card_rarity():
	# All 3 card options from Boss reward are Rare
	var card_pool = _load_card_pool()
	var cards = RewardGenerator.roll_card_rewards(card_pool, "boss", 12345)
	assert_eq(cards.size(), 3, "Boss should offer 3 cards")
	for card in cards:
		assert_eq(card.rarity, "Rare", "Boss reward cards should all be Rare")

# --- Helpers ---

func _load_card_pool() -> Array[CardData]:
	var pool: Array[CardData] = []
	var dir = DirAccess.open("res://resources/cards/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var card = load("res://resources/cards/" + file_name) as CardData
				if card:
					pool.append(card)
			file_name = dir.get_next()
	return pool
