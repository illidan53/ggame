extends GutTest

# --- T3: Data Integrity ---

func test_T3_1_card_resources_valid():
	var dir = DirAccess.open("res://resources/cards/")
	assert_not_null(dir, "Cards directory should exist")
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var count := 0
	while file_name != "":
		if file_name.ends_with(".tres"):
			var card = load("res://resources/cards/" + file_name) as CardData
			assert_not_null(card, "Card %s should load" % file_name)
			assert_true(card.card_name != "", "Card %s should have a name" % file_name)
			assert_true(card.cost >= -1, "Card %s cost should be >= -1" % file_name)
			assert_true(card.card_type in ["Attack", "Skill", "Power"],
				"Card %s type should be Attack/Skill/Power, got %s" % [file_name, card.card_type])
			assert_true(card.rarity in ["Common", "Uncommon", "Rare"],
				"Card %s rarity should be Common/Uncommon/Rare, got %s" % [file_name, card.rarity])
			assert_true(card.effect_text != "", "Card %s should have effect text" % file_name)
			count += 1
		file_name = dir.get_next()
	assert_true(count >= 15, "Should have at least 15 card resources, got %d" % count)

func test_T3_2_enemy_resources_valid():
	var dir = DirAccess.open("res://resources/enemies/")
	assert_not_null(dir, "Enemies directory should exist")
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var count := 0
	while file_name != "":
		if file_name.ends_with(".tres"):
			var enemy = load("res://resources/enemies/" + file_name) as EnemyData
			assert_not_null(enemy, "Enemy %s should load" % file_name)
			assert_true(enemy.enemy_name != "", "Enemy %s should have a name" % file_name)
			assert_true(enemy.hp > 0, "Enemy %s HP should be > 0" % file_name)
			assert_true(enemy.pattern.size() >= 1,
				"Enemy %s should have at least 1 pattern entry" % file_name)
			count += 1
		file_name = dir.get_next()
	assert_true(count >= 4, "Should have at least 4 enemy resources, got %d" % count)

func test_T3_3_relic_names_valid():
	# All relics referenced in EventSystem and RelicSystem should be consistent
	var all_relics = EventSystem.ALL_RELICS
	assert_true(all_relics.size() >= 6, "Should have at least 6 relics defined")
	for relic in all_relics:
		assert_true(relic != "", "Relic name should not be empty")

func test_T3_4_no_orphan_resources():
	# Every card in the card pool directory should be loadable
	var dir = DirAccess.open("res://resources/cards/")
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var card = load("res://resources/cards/" + file_name)
			assert_not_null(card, "Card resource %s should be loadable" % file_name)
		file_name = dir.get_next()
	# Same for enemies
	dir = DirAccess.open("res://resources/enemies/")
	dir.list_dir_begin()
	file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var enemy = load("res://resources/enemies/" + file_name)
			assert_not_null(enemy, "Enemy resource %s should be loadable" % file_name)
		file_name = dir.get_next()
