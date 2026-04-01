# DarkPath

A browser-based roguelike deckbuilder inspired by Slay the Spire, built with Godot 4.x.

**Play now**: [https://ggame.nphunter.net](https://ggame.nphunter.net)

---

## Gameplay

Terminal-style UI. Type commands, press Enter. Build a deck, fight enemies across 3 acts, defeat the final boss.

- **3 acts** × 10 layers each = 30 total floors
- Each act ends with a boss fight
- Between acts: 30% HP heal
- Permadeath: one run, no continues

### Node types per layer

Combat | Elite (relic drop) | Shop | Rest (heal/upgrade) | Event | Boss

---

## Characters

### Warrior (from Ironclad)
- **HP**: 80
- **Deck**: 10 cards — 5 Strike, 4 Defend, 1 Bash
- **Identity**: Strength scaling, block, direct damage
- **31 cards** (commons through rares)

### Silent (from Silent)
- **HP**: 70
- **Deck**: 12 cards — 5 Strike, 5 Defend, 1 Neutralize, 1 Survivor
- **Relic**: Ring of the Snake (+2 draw on first turn)
- **Identity**: Poison (bypasses block, stacks), Shivs (0-cost exhaust tokens), discard synergies
- **25 cards** including Deadly Poison, Blade Dance, Catalyst, Noxious Fumes, Wraith Form

---

## Enemies

| Act | Normal | Elite | Boss |
|-----|--------|-------|------|
| 1 | Slime, Goblin, Skeleton, Bat Swarm | Dark Knight, Fire Elemental | Shadow Lord (3 phases) |
| 2 | Fungus, Bandit, Golem | Assassin | Crystal King (3 phases) |
| 3 | Wraith, Demon, Dark Mage | Lich | Void Dragon (3 phases) |

---

## Balance Algorithm

Uses **tabular Q-learning** to evaluate card balance:

- Two Q-tables: combat decisions + deck-building picks
- Epsilon-greedy policy (explores early, exploits late)
- Trains over thousands of simulated runs
- Produces card power rankings by average Q-value, pick rate, and win contribution

### Win rates (random AI, 1000 runs)

| Metric | Value |
|--------|-------|
| Overall (3-act) | ~0% |
| Survive Act 1 | ~5% |
| Avg death layer | 6 / 30 |

### Win rates (Q-learning, 500 episodes)

| Metric | Value |
|--------|-------|
| Avg death layer | 9 / 30 (+50% deeper) |

The Q-agent learns to survive significantly longer than random play. With more training episodes, it continues improving.

---

## Tech Stack

- **Engine**: Godot 4.6.1 (GDScript)
- **UI**: Terminal-style (RichTextLabel + LineEdit, no graphics)
- **Export**: HTML5/WebAssembly
- **Hosting**: AWS EC2 + nginx + Let's Encrypt SSL
- **CI/CD**: GitHub Actions → S3 artifact → EC2 systemd timer auto-deploy
- **Tests**: 200 GUT tests, all passing
