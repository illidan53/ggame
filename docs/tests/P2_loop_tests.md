# P2 Test Specification — Single-Run Loop

> GDD References: Section 4.6 (Rewards), Section 3.4 (Rest), Section 10 (Economy)
> Prerequisite: All P0 + P1 tests pass

---

## T1. Combat Rewards (5 cases)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T1.1 | Normal combat gold | Gold reward is in range [10, 20] |
| T1.2 | Elite combat gold | Gold reward is in range [25, 35] |
| T1.3 | Boss gold | Gold reward is exactly 50 |
| T1.4 | Card reward options | 3 cards offered; player can pick 1 or skip |
| T1.5 | Rarity distribution | Over 100 Normal/Elite reward rolls: ~60% Common, ~30% Uncommon, ~10% Rare (within ±10% tolerance) |

---

## T2. Elite Rewards (2 cases)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T2.1 | Elite drops relic | After Elite victory, exactly 1 relic is awarded |
| T2.2 | Boss card rarity | All 3 card options from Boss reward are Rare |

---

## T3. Shop (4 cases)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T3.1 | Price ranges | Common card: 30-50, Uncommon: 60-90, Rare: 100-150, Relic: 80-200, Potion: 30-50 |
| T3.2 | Card removal cost | Removing a card costs 75 gold |
| T3.3 | Insufficient gold | Attempting to buy a 50-gold item with 30 gold → purchase rejected, gold unchanged |
| T3.4 | Purchase adds item | Buy a card → card added to deck; buy potion → potion added to inventory |

---

## T4. Rest Site (3 cases)

| ID | Scenario | Setup | Expected Result |
|----|----------|-------|-----------------|
| T4.1 | Heal amount | Max HP = 80, current HP = 50 | After rest: HP = 50 + ceil(80 × 0.3) = 74 |
| T4.2 | Heal cap | Max HP = 80, current HP = 75 | After rest: HP = 80 (cannot exceed max) |
| T4.3 | Upgrade card | Choose un-upgraded Strike to upgrade | Strike becomes Strike+ with upgraded values (9 damage) |

---

## T5. Run State Persistence (3 cases)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T5.1 | HP persists | Player finishes combat with 55 HP → enters next node with 55 HP |
| T5.2 | Deck persists | Player picks a card reward → card exists in deck at next combat |
| T5.3 | Serialize round-trip | Serialize RunData → deserialize → all fields match (deck, relics, potions, HP, gold, map position) |

---

## Summary

| Category | Case Count |
|----------|-----------|
| T1. Combat Rewards | 5 |
| T2. Elite/Boss Rewards | 2 |
| T3. Shop | 4 |
| T4. Rest Site | 3 |
| T5. Run State Persistence | 3 |
| **Total** | **17** |

All 17 tests + all P0+P1 tests (49) must pass before P2 is complete.
