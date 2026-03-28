extends GutTest

# --- T3: Shop ---

func test_T3_1_price_ranges():
	# Common card: 30-50, Uncommon: 60-90, Rare: 100-150, Relic: 80-200, Potion: 30-50
	for i in 50:
		var prices = ShopGenerator.generate_prices(i)
		assert_true(prices["Common"] >= 30 and prices["Common"] <= 50,
			"Common card price should be 30-50, got %d" % prices["Common"])
		assert_true(prices["Uncommon"] >= 60 and prices["Uncommon"] <= 90,
			"Uncommon card price should be 60-90, got %d" % prices["Uncommon"])
		assert_true(prices["Rare"] >= 100 and prices["Rare"] <= 150,
			"Rare card price should be 100-150, got %d" % prices["Rare"])
		assert_true(prices["Relic"] >= 80 and prices["Relic"] <= 200,
			"Relic price should be 80-200, got %d" % prices["Relic"])
		assert_true(prices["Potion"] >= 30 and prices["Potion"] <= 50,
			"Potion price should be 30-50, got %d" % prices["Potion"])

func test_T3_2_card_removal_cost():
	assert_eq(ShopGenerator.CARD_REMOVAL_COST, 75, "Card removal should cost 75 gold")

func test_T3_3_insufficient_gold():
	# Attempting to buy a 50-gold item with 30 gold → rejected
	var result = ShopGenerator.try_purchase(30, 50)
	assert_false(result.success, "Should fail with insufficient gold")
	assert_eq(result.remaining_gold, 30, "Gold should be unchanged")

func test_T3_4_purchase_succeeds():
	# Buy with enough gold
	var result = ShopGenerator.try_purchase(100, 50)
	assert_true(result.success, "Should succeed with enough gold")
	assert_eq(result.remaining_gold, 50, "Gold should be reduced by price")
