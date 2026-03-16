extends GutTest

# T1. Damage Calculation (9 cases)
# T2. Block Calculation (3 cases)

# --- T1: Damage Calculation ---

func test_T1_1_base_damage():
	# Card deals 6 damage, target has 0 block, 20 HP → Target HP = 14
	var result = CombatCalc.calculate_damage(6, 0, false, false)
	assert_eq(result, 6, "Base damage should equal card value")

func test_T1_2_strength_buff():
	# Card deals 6 damage, attacker has 3 Strength → Damage dealt = 9
	var result = CombatCalc.calculate_damage(6, 3, false, false)
	assert_eq(result, 9, "Damage should be base + strength")

func test_T1_3_vulnerable_debuff():
	# Card deals 6 damage, target has Vulnerable → Damage dealt = 9
	var result = CombatCalc.calculate_damage(6, 0, false, true)
	assert_eq(result, 9, "Vulnerable should increase damage by 50%")

func test_T1_4_weak_debuff():
	# Card deals 6 damage, attacker has Weak → Damage dealt = 4
	var result = CombatCalc.calculate_damage(6, 0, true, false)
	assert_eq(result, 4, "Weak should reduce damage by 25% (floor)")

func test_T1_5_strength_plus_vulnerable():
	# Card deals 6, attacker has 2 Strength, target Vulnerable → floor((6+2) × 1.5) = 12
	var result = CombatCalc.calculate_damage(6, 2, false, true)
	assert_eq(result, 12, "Strength + Vulnerable combo")

func test_T1_6_block_absorbs_damage():
	# Card deals 10, target has 6 block, 20 HP → Block=0, HP=16
	var target = Combatant.new()
	target.hp = 20
	target.max_hp = 20
	target.block = 6
	CombatCalc.apply_damage_to_target(target, 10)
	assert_eq(target.block, 0, "Block should be fully consumed")
	assert_eq(target.hp, 16, "HP should take overflow damage")

func test_T1_7_block_fully_absorbs():
	# Deal 5 damage to target with 8 block → Block=3, HP unchanged
	var target = Combatant.new()
	target.hp = 20
	target.max_hp = 20
	target.block = 8
	CombatCalc.apply_damage_to_target(target, 5)
	assert_eq(target.block, 3, "Block should partially remain")
	assert_eq(target.hp, 20, "HP should be unchanged")

func test_T1_8_zero_damage():
	# Deal 0 base damage with no Strength → 0 damage
	var result = CombatCalc.calculate_damage(0, 0, false, false)
	assert_eq(result, 0, "Zero base + zero strength = zero damage")

func test_T1_9_weak_plus_vulnerable():
	# Card deals 10, Weak + Vulnerable → floor(floor(10 × 0.75) × 1.5) = floor(7 × 1.5) = 10
	var result = CombatCalc.calculate_damage(10, 0, true, true)
	assert_eq(result, 10, "Weak then Vulnerable: floor(floor(10*0.75)*1.5) = 10")

# --- T2: Block Calculation ---

func test_T2_1_base_block():
	# Card gives 5 block → combatant block += 5
	var combatant = Combatant.new()
	combatant.block = 0
	CombatCalc.apply_block(combatant, 5, 0)
	assert_eq(combatant.block, 5, "Block should increase by card value")

func test_T2_2_dexterity_buff():
	# Card gives 5 block, combatant has 2 Dexterity → Block gained = 7
	var combatant = Combatant.new()
	combatant.block = 0
	CombatCalc.apply_block(combatant, 5, 2)
	assert_eq(combatant.block, 7, "Block should include dexterity bonus")

func test_T2_3_block_resets_each_turn():
	# Combatant has 10 block, new turn starts → Block = 0
	var combatant = Combatant.new()
	combatant.block = 10
	CombatCalc.reset_block(combatant)
	assert_eq(combatant.block, 0, "Block should reset to 0 at turn start")
