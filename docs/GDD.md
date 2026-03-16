# Game Design Document — DarkPath

> Slay the Spire-inspired Roguelike Deckbuilder · Godot 4.x · Windows

---

## 1. Overview

| Item | Description |
|------|-------------|
| Genre | Roguelike Deckbuilder |
| Engine | Godot 4.x (GDScript) |
| Platform | Windows |
| Perspective | 2D Side-view |
| Session Length | 20-40 minutes |
| Class | Warrior (sole launch class) |

---

## 2. Core Game Loop

```
Start Run → Choose Route (Tree Map) → Enter Node Event → ... → Defeat Boss → Summary
                ↑                                                   |
                └──── Death / Abandon ──────────────────────────────┘
```

Single run flow:
1. Receive starting deck (10 cards) + starting relic
2. Navigate a tree-shaped map, advancing layer by layer
3. Complete node events at each layer (Combat / Event / Shop / Rest)
4. Layer 10 is the Boss fight
5. Victory or death triggers a summary screen; unlock new cards/relics into the pool

---

## 3. Map System

### 3.1 Structure

- **10 layers total**, each with 2-4 nodes connected in a tree pattern
- Player picks one node per layer; choices are irreversible
- Connections guarantee that any node can reach at least 2 nodes on the next layer

### 3.2 Node Types

| Icon | Type | Appears On | Description |
|------|------|------------|-------------|
| ⚔️ | Normal Combat | 1-9 | Encounter 1-3 enemies |
| 💀 | Elite Combat | 3, 6, 8 | Tough enemies, drops a relic |
| ❓ | Random Event | Any | Branching choices with risk/reward |
| 🛒 | Shop | 4, 7 | Buy/remove cards, buy relics and potions |
| 🔥 | Rest Site | 5, 9 | Restore HP or upgrade a card |
| 👹 | Boss | 10 | Fixed; defeat to win the run |

### 3.4 Rest Site Options

- **Rest**: Restore **30% of max HP** (rounded up)
- **Upgrade**: Choose one un-upgraded card in your deck to upgrade

### 3.3 Map Generation Rules

- Layer 1 is always Normal Combat
- Layer 10 is always Boss
- Elite, Shop, and Rest nodes appear on fixed layers as listed above
- Remaining layers randomly assign Normal Combat or Random Event
- No duplicate node types within the same layer (when node count ≤ available types)

---

## 4. Combat System

### 4.1 Core Rules

- **Turn-based**: Player Turn → Enemy Turn → repeat
- At the start of each turn:
  - Gain **3 Energy** (default)
  - **Draw 5 cards**
- At end of turn: unplayed hand cards go to the **Discard Pile**
- When the Draw Pile is empty, shuffle the Discard Pile back into the Draw Pile

### 4.2 Core Stats

| Stat | Description |
|------|-------------|
| HP (Health) | Warrior starts at 80; persists across battles; 0 = death |
| Energy | Resets to 3 each turn; spent to play cards |
| Block (Armor) | Resets to 0 at turn start; absorbs damage |
| Gold | Earned from combat rewards; spent at shops |

### 4.3 Status Effects (Buffs / Debuffs)

| Effect | Type | Description |
|--------|------|-------------|
| Strength | Buff | +1 attack damage per stack |
| Dexterity | Buff | +1 block gained per stack |
| Vulnerable | Debuff | Take 50% more damage, lasts X turns |
| Weak | Debuff | Deal 25% less damage, lasts X turns |
| Thorns | Buff | Reflect X damage when attacked |
| Auto-Block | Buff | Gain X block at start of each turn |

### 4.4 Enemy Intent System

- Enemies **display their intent** at the start of each turn (Attack, Defend, Buff, etc.)
- Players use intent info to plan their card plays
- Intent shown as icon + value preview (attacks show damage numbers)

### 4.5 Targeting Rules

- **Single-target Attack cards**: Player must drag the card onto a specific enemy to select the target
- **AOE cards** (e.g., Whirlwind, Fire Potion): Automatically hit ALL enemies; no target selection needed
- **Skill / Power cards**: No target selection needed; effects apply to the player or globally

### 4.6 Combat Rewards

| Battle Type | Gold | Card Reward | Extra |
|-------------|------|-------------|-------|
| Normal Combat | 10-20 | Pick 1 of 3 random cards (can skip) | — |
| Elite Combat | 25-35 | Pick 1 of 3 random cards (can skip) | +1 random relic |
| Boss | 50 | Pick 1 of 3 Rare cards | — |

- Card reward pool is filtered by class (Warrior only at launch)
- Rarity distribution for Normal/Elite rewards: 60% Common, 30% Uncommon, 10% Rare

---

## 5. Card System

### 5.1 Card Attributes

```
┌─────────────────────┐
│ [Cost]   Card Name   │
│                     │
│     [Card Art]      │
│                     │
│  Type: Attack/Skill/ │
│        Power        │
│  Effect text        │
│                     │
│  Rarity border color │
└─────────────────────┘
```

- **Cost**: 0-3 Energy
- **Type**: Attack / Skill / Power
  - Attack: Deals damage
  - Skill: Gains block, applies statuses, etc.
  - Power: Permanent effect for the rest of combat once played
- **Rarity**: Common (white) / Uncommon (blue) / Rare (gold)
- **Upgrade**: Each card can be upgraded once, improving values or adding effects

#### Keywords

| Keyword | Rule |
|---------|------|
| **Exhaust** | After playing, the card is moved to the Exhaust Pile and cannot be used again this combat |
| **Innate** | This card is always in your opening hand at the start of combat |
| **Ethereal** | If still in hand at end of turn, this card is automatically Exhausted |

### 5.2 Starting Deck (Warrior · 10 cards)

| Card | Cost | Type | Effect | Upgraded |
|------|------|------|--------|----------|
| Strike ×5 | 1 | Attack | Deal 6 damage | 9 damage |
| Defend ×4 | 1 | Skill | Gain 5 block | 8 block |
| Bash ×1 | 2 | Attack | Deal 14 damage, apply 2 Vulnerable | 18 damage |

### 5.3 Warrior Extended Card Pool (Examples)

| Card | Cost | Type | Rarity | Effect |
|------|------|------|--------|--------|
| Whirlwind | X | Attack | Uncommon | Deal X×5 damage to ALL enemies |
| War Cry | 1 | Skill | Common | Gain 2 Strength |
| Sword & Shield | 2 | Skill | Uncommon | Gain 12 block, draw 1 extra card next turn |
| War Stomp | 2 | Attack | Rare | Deal 20 damage, Exhaust (removed after use) |
| Iron Fortress | 3 | Power | Rare | Gain 6 block at start of each turn |
| Double Strike | 1 | Attack | Common | Deal 4×2 damage |
| Bloodlust | 1 | Attack | Uncommon | Deal 8 damage, heal equal HP |
| Armor Break | 1 | Attack | Common | Deal 7 damage, remove enemy block |

> Full card pool target: 40-60 cards, designed in phases.

---

## 6. Relic System

- Relics provide **passive effects** for the entire run
- Obtained from: Elite combat drops, shop purchases, random events
- Multiple relics can be held; effects stack

### Example Relics

| Relic | Rarity | Effect |
|-------|--------|--------|
| Iron Bracers | Common | Gain 4 block at the start of each combat |
| War Drum | Common | Draw 1 extra card each turn |
| Cracked Crown | Rare | +1 Energy, but draw 1 fewer card per turn |
| Blood Pendant | Uncommon | Heal 2 HP at the start of each combat |
| Rage Mask | Uncommon | Attack cards deal +3 damage |
| Thorn Armor | Rare | Gain 3 Thorns |

> Full relic target: 20-30 relics.

---

## 7. Potion System

- Carry up to **3 potions**
- Used during combat, **costs no energy**, single-use
- Obtained from: combat drops, shop purchases, random events

| Potion | Effect |
|--------|--------|
| Health Potion | Restore 20 HP |
| Strength Potion | +2 Strength for this combat |
| Block Potion | Immediately gain 12 block |
| Fire Potion | Deal 10 damage to ALL enemies |

---

## 8. Enemy Design

### 8.0 Enemy AI Rules

- Each enemy has a **fixed behavior sequence (Pattern)** and cycles through it in order
- Intent for the current turn is displayed at the start of the player's turn
- Some enemies have **conditional branches**: when HP drops below a threshold, they switch to a different Pattern
- Boss enemies use a **Phase system** (see 8.3): Phase transitions are triggered by HP thresholds
- When multiple enemies are present, each acts independently with its own Pattern position

### 8.1 Normal Enemies (Examples)

| Name | HP | Behavior Pattern |
|------|----|-----------------|
| Slime | 12 | Alternates: Attack(6) / Defend(4) |
| Goblin | 18 | Pattern: Attack(8) → Attack(8) → Defend(6) |
| Skeleton | 24 | Attack(5) + apply 1 Vulnerable / Attack(10) |
| Bat Swarm | 15 | Attack(4×2) / Buff self +1 Strength |

### 8.2 Elite Enemies (Examples)

| Name | HP | Special Ability |
|------|----|----------------|
| Dark Knight | 50 | Attacks double after turn 3 |
| Fire Elemental | 40 | Applies 1 Vulnerable to player each turn |

### 8.3 Boss

| Name | HP | Mechanics |
|------|----|-----------|
| Shadow Lord | 100 | Three phases:<br>Phase 1 (HP>60): Standard attack/defend<br>Phase 2 (HP 30-60): Summons minions + self-buff<br>Phase 3 (HP<30): Enrage, gains +2 Strength each turn |

---

## 9. Random Events (Examples)

### Mysterious Altar
> You discover a faintly glowing altar...
- **Blood Offering**: Lose 10 HP, gain a random relic
- **Walk Away**: Nothing happens

### Wandering Merchant
> A mysterious merchant blocks your path...
- **Trade**: Lose 50 gold, gain a random Uncommon card
- **Rob**: Gain 30 gold, take 8 damage
- **Leave**: Nothing happens

### Training Dummy
> A worn training dummy stands by the road...
- **Practice**: Upgrade a card
- **Dismantle**: Gain 15 gold

---

## 10. Economy

| Source | Gold |
|--------|------|
| Normal Combat victory | 10-20 |
| Elite Combat victory | 25-35 |
| Boss defeat | 50 |
| Random Events | Varies |

| Shop Item | Price Range |
|-----------|------------|
| Common card | 30-50 |
| Uncommon card | 60-90 |
| Rare card | 100-150 |
| Remove a card | 75 |
| Relic | 80-200 |
| Potion | 30-50 |

---

## 11. Meta Progression (Cross-Run Unlocks)

- Not implemented in first version
- Reserved design: unlock new cards/relics into the pool based on clears or cumulative plays
- Expandable: new classes, higher difficulty modes

---

## 11.5 Save System

- **Auto-save**: Game state is saved automatically when entering a new map node
- **Exit save**: Current state is saved when quitting the game
- **Permadeath**: Save file is deleted upon death or successful run completion
- **Save contents**: Current deck, relics, potions, HP, gold, map layout, current layer, seed

---

## 12. UI / UX Overview

### Main Screens

1. **Main Menu**: New Game / Continue / Settings / Quit
2. **Map Screen**: Tree-shaped node graph; current position highlighted, selectable nodes glow
3. **Battle Screen**:
   - Top: Enemy area (HP bars, intent icons)
   - Center: Battlefield
   - Bottom: Hand area (horizontal card layout, drag-to-play)
   - Bottom-left: Draw Pile / Discard Pile counts
   - Bottom-right: Energy display, End Turn button
   - Top-left: Player HP, block, status effects
   - Top-right: Relic bar, potion slots
4. **Reward Screen**: Post-combat card pick (choose 1 of 3) + gold
5. **Shop Screen**: Cards / relics / potions display
6. **Event Screen**: Narrative text + choice buttons
7. **Summary Screen**: Victory/defeat stats

### Controls

- Mouse primary: drag cards to target OR click card + click target
- Right-click to view card details
- Scroll wheel to browse hand (when many cards)

### Deck & Collection Viewing

- **Click Draw Pile icon** (in combat): View remaining cards in draw pile (displayed in random order)
- **Click Discard Pile icon** (in combat): View all cards in discard pile
- **Click Exhaust Pile icon** (in combat): View all exhausted cards
- **Deck button** (map screen / top bar): View full current deck and relic list

---

## 13. Technical Architecture (Overview)

```
project/
├── scenes/
│   ├── main_menu/        # Main menu
│   ├── map/              # Map scene
│   ├── battle/           # Battle scene
│   ├── event/            # Event scene
│   ├── shop/             # Shop scene
│   ├── reward/           # Reward scene
│   └── ui/               # Shared UI components
├── scripts/
│   ├── core/             # Core game logic
│   │   ├── game_manager.gd
│   │   ├── battle_manager.gd
│   │   ├── card_manager.gd
│   │   ├── map_generator.gd
│   │   └── run_data.gd   # Single-run data
│   ├── cards/            # Card definitions & logic
│   ├── enemies/          # Enemy AI
│   ├── relics/           # Relic logic
│   └── events/           # Event scripts
├── resources/
│   ├── cards/            # Card data (.tres)
│   ├── enemies/          # Enemy data (.tres)
│   ├── relics/           # Relic data (.tres)
│   └── events/           # Event data (.tres)
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
└── docs/
    ├── GDD.md
    ├── PLAN.md
    └── SCRATCHPAD.md
```

### Data-Driven Design

- Cards, enemies, relics, and events are all defined using Godot **Resources (.tres)**
- Allows tuning values without modifying code logic

---

## 14. Development Phases

| Phase | Content | Milestone |
|-------|---------|-----------|
| P0 | Core battle system (card play, enemy AI, turn flow) | Can complete one battle |
| P1 | Map system + node linking | Can travel from layer 1 to layer 10 |
| P2 | Card rewards + shop + rest sites | Complete single-run loop |
| P3 | Relics + potions + random events | Richer strategic depth |
| P4 | Boss design + balance tuning | Playable complete run |
| P5 | UI polish + audio + packaging | Shippable build |

---

## Appendix: Glossary

| Term | Description |
|------|-------------|
| Roguelike | Genre with procedural generation and permadeath |
| Deckbuilding | Gradually building a deck during gameplay |
| Run | One complete game session from start to death/victory |
| Exhaust | Card is permanently removed from the battle after use |
| Innate | Card always appears in the opening hand |
| Ethereal | Card is exhausted if still in hand at end of turn |
