extends GutTest

# --- T4: Rest Site ---

func test_T4_1_heal_amount():
	# Max HP = 80, current HP = 50 → HP = 50 + ceil(80 × 0.3) = 74
	var result = RestSite.rest(50, 80)
	assert_eq(result, 74, "Heal should be 50 + ceil(80*0.3) = 74")

func test_T4_2_heal_cap():
	# Max HP = 80, current HP = 75 → HP = 80 (cannot exceed max)
	var result = RestSite.rest(75, 80)
	assert_eq(result, 80, "HP should not exceed max HP")

func test_T4_3_upgrade_card():
	# Upgrade Strike: damage 6 → 9
	var strike = load("res://resources/cards/strike.tres") as CardData
	var upgraded = CardUpgrade.upgrade(strike)
	assert_true(upgraded.is_upgraded, "Card should be marked as upgraded")
	assert_eq(upgraded.base_damage, 9, "Strike+ should deal 9 damage")
	assert_true(upgraded.card_name.ends_with("+"), "Upgraded card name should end with +")

# --- T5: Run State Persistence ---

func test_T5_1_hp_persists():
	# Player finishes combat with 55 HP → enters next node with 55 HP
	var run = RunData.create_new(12345)
	run.player_hp = 55
	assert_eq(run.player_hp, 55, "HP should persist in RunData")

func test_T5_2_deck_persists():
	# Add a card to deck → card exists
	var run = RunData.create_new(12345)
	var initial_size = run.deck.size()
	var war_cry = load("res://resources/cards/war_cry.tres") as CardData
	var new_card = CardInstance.new(war_cry)
	new_card.instance_id = 99
	run.deck.append(new_card)
	assert_eq(run.deck.size(), initial_size + 1, "Deck should grow by 1 after adding card")

func test_T5_3_serialize_round_trip():
	# Serialize RunData → deserialize → all fields match
	var run = RunData.create_new(12345)
	run.player_hp = 55
	run.gold = 42
	run.relics.append("Iron Bracers")
	run.potions.append("Health Potion")
	run.current_layer = 3
	run.current_node = 1

	var data = run.to_dict()
	# Build card pool lookup for deserialization
	var card_pool := {}
	for card in run.deck:
		card_pool[card.data.card_name] = card.data

	var restored = RunData.from_dict(data, card_pool)
	assert_eq(restored.player_hp, 55, "HP should match")
	assert_eq(restored.player_max_hp, 80, "Max HP should match")
	assert_eq(restored.gold, 42, "Gold should match")
	assert_eq(restored.relics.size(), 1, "Relics should match")
	assert_eq(restored.potions.size(), 1, "Potions should match")
	assert_eq(restored.current_layer, 3, "Layer should match")
	assert_eq(restored.current_node, 1, "Node should match")
	assert_eq(restored.deck.size(), run.deck.size(), "Deck size should match")
	assert_eq(restored.seed_value, 12345, "Seed should match")
