class_name RewardGenerator
extends RefCounted

## Roll gold reward based on combat type
static func roll_gold(combat_type: String, seed_value: int) -> int:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	match combat_type:
		"combat":
			return rng.randi_range(10, 20)
		"elite":
			return rng.randi_range(25, 35)
		"boss":
			return 50
		_:
			return 0

## Roll 3 card rewards from pool based on combat type and rarity distribution
## Normal/Elite: 60% Common, 30% Uncommon, 10% Rare
## Boss: all Rare
static func roll_card_rewards(card_pool: Array[CardData], combat_type: String, seed_value: int) -> Array[CardData]:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var result: Array[CardData] = []

	if combat_type == "boss":
		var rare_cards = card_pool.filter(func(c): return c.rarity == "Rare")
		for i in 3:
			if rare_cards.is_empty():
				break
			var idx = rng.randi_range(0, rare_cards.size() - 1)
			result.append(rare_cards[idx])
		return result

	# Normal/Elite: rarity distribution
	for i in 3:
		var rarity = _roll_rarity(rng)
		var filtered = card_pool.filter(func(c): return c.rarity == rarity)
		if filtered.is_empty():
			# Fallback to any card
			filtered = card_pool
		if not filtered.is_empty():
			var idx = rng.randi_range(0, filtered.size() - 1)
			result.append(filtered[idx])

	return result

## Roll a relic reward (returns relic name placeholder until P3)
static func roll_relic_reward(seed_value: int) -> String:
	# Placeholder — returns a relic name. Full relic system in P3.
	var relic_names = ["Iron Bracers", "War Drum", "Blood Pendant", "Rage Mask", "Thorn Armor", "Cracked Crown"]
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	return relic_names[rng.randi_range(0, relic_names.size() - 1)]

## Roll rarity: 60% Common, 30% Uncommon, 10% Rare
static func _roll_rarity(rng: RandomNumberGenerator) -> String:
	var roll = rng.randf()
	if roll < 0.6:
		return "Common"
	elif roll < 0.9:
		return "Uncommon"
	else:
		return "Rare"
