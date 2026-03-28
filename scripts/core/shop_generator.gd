class_name ShopGenerator
extends RefCounted

const CARD_REMOVAL_COST := 75

## Generate random prices for shop items
static func generate_prices(seed_value: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	return {
		"Common": rng.randi_range(30, 50),
		"Uncommon": rng.randi_range(60, 90),
		"Rare": rng.randi_range(100, 150),
		"Relic": rng.randi_range(80, 200),
		"Potion": rng.randi_range(30, 50),
	}

## Try to purchase an item. Returns {success: bool, remaining_gold: int}
static func try_purchase(current_gold: int, price: int) -> Dictionary:
	if current_gold < price:
		return {"success": false, "remaining_gold": current_gold}
	return {"success": true, "remaining_gold": current_gold - price}
