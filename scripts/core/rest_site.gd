class_name RestSite
extends RefCounted

## Heal player: restore 30% of max HP (rounded up), capped at max
static func rest(current_hp: int, max_hp: int) -> int:
	var heal = ceili(max_hp * 0.3)
	return mini(current_hp + heal, max_hp)
