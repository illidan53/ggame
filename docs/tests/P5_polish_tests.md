# P5 Test Specification — Save System & Data Integrity

> GDD References: Section 11.5 (Save System), Section 12 (UI)
> Prerequisite: All P0 + P1 + P2 + P3 + P4 tests pass

---

## T1. Save / Load (4 cases)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T1.1 | Auto-save on node entry | After entering a new map node, a save file exists on disk |
| T1.2 | Load restores state | Save → quit → load → RunData matches: deck, relics, potions, HP, gold, map layer |
| T1.3 | Exit save | Quitting mid-run creates a valid save file |
| T1.4 | Seed preserved | Loaded game uses the same seed → map layout matches original |

---

## T2. Permadeath (2 cases)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T2.1 | Death deletes save | Player HP reaches 0 → save file is deleted |
| T2.2 | Victory deletes save | Player defeats boss → save file is deleted |

---

## T3. Data Integrity (4 cases)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T3.1 | Card resources valid | All .tres card files have: name, cost (≥0), type (Attack/Skill/Power), rarity, effect text |
| T3.2 | Enemy resources valid | All .tres enemy files have: name, HP (>0), at least 1 behavior pattern entry |
| T3.3 | Relic resources valid | All .tres relic files have: name, rarity, effect description |
| T3.4 | No orphan resources | Every card/enemy/relic referenced in game logic exists as a .tres file |

---

## Summary

| Category | Case Count |
|----------|-----------|
| T1. Save / Load | 4 |
| T2. Permadeath | 2 |
| T3. Data Integrity | 4 |
| **Total** | **10** |

All 10 tests + all prior tests (109) must pass before P5 is complete.

---

## Cumulative Test Count

| Phase | Scope | New Tests | Cumulative |
|-------|-------|-----------|-----------|
| P0 | Battle | 37 | 37 |
| P1 | Map | 12 | 49 |
| P2 | Run loop | 17 | 66 |
| P3 | Depth | 23 | 89 |
| P4 | Boss/Elite | 12 | 101 |
| P4-bal | Balance | 8 | 109 |
| P5 | Polish | 10 | **119** |
