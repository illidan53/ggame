class_name CardUpgrade
extends RefCounted

## Upgrade table: card_name → {property: new_value, ...}
## GDD Sec 5.2: Strike 6→9, Defend 5→8, Bash 14→18
const UPGRADE_TABLE := {
	"Strike": {"base_damage": 9},
	"Defend": {"base_block": 8},
	"Bash": {"base_damage": 18},
}

## Upgrade a card, returning a new CardData with upgraded values
## The original CardData is not modified
static func upgrade(card: CardData) -> CardData:
	var upgraded = card.duplicate() as CardData
	upgraded.is_upgraded = true
	upgraded.card_name = card.card_name + "+"

	# Apply known upgrades
	if UPGRADE_TABLE.has(card.card_name):
		var changes = UPGRADE_TABLE[card.card_name]
		for key in changes:
			upgraded.set(key, changes[key])

	# Update effect text
	upgraded.effect_text = _generate_effect_text(upgraded)
	return upgraded

static func _generate_effect_text(card: CardData) -> String:
	var parts: Array[String] = []
	if card.base_damage > 0:
		parts.append("Deal %d damage." % card.base_damage)
	if card.base_block > 0:
		parts.append("Gain %d block." % card.base_block)
	if parts.is_empty():
		return card.effect_text  # Keep original for special effects
	return " ".join(parts)
