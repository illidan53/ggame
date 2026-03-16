# P3 Test Specification — Relics, Potions & Events

> GDD References: Section 6 (Relics), Section 7 (Potions), Section 9 (Events)
> Prerequisite: All P0 + P1 + P2 tests pass

---

## T1. Relic Effects (6 cases)

| ID | Relic | Trigger | Expected Result |
|----|-------|---------|-----------------|
| T1.1 | Iron Bracers | Combat start | Player gains 4 block at the start of each combat |
| T1.2 | War Drum | Turn start | Player draws 6 cards instead of 5 |
| T1.3 | Cracked Crown | Turn start | Player energy = 4 (base 3 + 1) but draws 4 cards (base 5 - 1) |
| T1.4 | Blood Pendant | Combat start | Player heals 2 HP at start of each combat |
| T1.5 | Rage Mask | Play Attack card | All Attack cards deal +3 damage |
| T1.6 | Thorn Armor | Permanent | Player gains 3 Thorns status at combat start |

---

## T2. Relic Stacking (2 cases)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T2.1 | Multiple relics active | Player has Iron Bracers + War Drum → combat starts with 4 block AND draws 6 cards |
| T2.2 | Duplicate relic prevention | Relic pool does not offer a relic the player already owns |

---

## T3. Potion System (5 cases)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T3.1 | Health Potion | Use Health Potion during combat → restore 20 HP (capped at max HP) |
| T3.2 | Strength Potion | Use Strength Potion → gain 2 Strength for this combat only |
| T3.3 | Block Potion | Use Block Potion → gain 12 block immediately |
| T3.4 | Fire Potion | Use Fire Potion with 3 enemies → all 3 take 10 damage |
| T3.5 | Carry limit | Player has 3 potions, tries to add another → rejected |

### Potion usage rules
| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T3.6 | No energy cost | Use potion with 0 energy → still works |
| T3.7 | Single use | After using a potion → potion removed from inventory |

---

## T4. Random Events (8 cases)

### Mysterious Altar
| ID | Choice | Expected Result |
|----|--------|-----------------|
| T4.1 | Blood Offering | Player loses 10 HP, gains 1 random relic |
| T4.2 | Walk Away | No HP change, no relic gained |

### Wandering Merchant
| ID | Choice | Expected Result |
|----|--------|-----------------|
| T4.3 | Trade | Player loses 50 gold, gains 1 random Uncommon card |
| T4.4 | Rob | Player gains 30 gold, takes 8 damage |
| T4.5 | Leave | No gold change, no damage |

### Training Dummy
| ID | Choice | Expected Result |
|----|--------|-----------------|
| T4.6 | Practice | Player chooses a card to upgrade; card is upgraded |
| T4.7 | Dismantle | Player gains 15 gold |

### Event edge case
| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T4.8 | Insufficient gold for Trade | Player has < 50 gold → Trade option is disabled or shows warning |

---

## Summary

| Category | Case Count |
|----------|-----------|
| T1. Relic Effects | 6 |
| T2. Relic Stacking | 2 |
| T3. Potion System | 7 |
| T4. Random Events | 8 |
| **Total** | **23** |

All 23 tests + all P0+P1+P2 tests (69) must pass before P3 is complete.
