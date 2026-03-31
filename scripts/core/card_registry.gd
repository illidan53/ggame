class_name CardRegistry
extends RefCounted

## Precomputed list of all card .tres paths.
## Replaces DirAccess.open() scanning, which fails in web/exported builds.
const CARD_PATHS: Array[String] = [
	"res://resources/cards/accuracy.tres",
	"res://resources/cards/acrobatics.tres",
	"res://resources/cards/adrenaline.tres",
	"res://resources/cards/armor_break.tres",
	"res://resources/cards/backflip.tres",
	"res://resources/cards/bane.tres",
	"res://resources/cards/bash.tres",
	"res://resources/cards/battle_cry.tres",
	"res://resources/cards/blade_dance.tres",
	"res://resources/cards/bloodlust.tres",
	"res://resources/cards/bludgeon.tres",
	"res://resources/cards/body_slam.tres",
	"res://resources/cards/bouncing_flask.tres",
	"res://resources/cards/burst.tres",
	"res://resources/cards/catalyst.tres",
	"res://resources/cards/cleave.tres",
	"res://resources/cards/cloak_and_dagger.tres",
	"res://resources/cards/corpse_explosion.tres",
	"res://resources/cards/crippling_cloud.tres",
	"res://resources/cards/dagger_spray.tres",
	"res://resources/cards/dash.tres",
	"res://resources/cards/deadly_poison.tres",
	"res://resources/cards/defend.tres",
	"res://resources/cards/defend_s.tres",
	"res://resources/cards/deflect.tres",
	"res://resources/cards/demon_form.tres",
	"res://resources/cards/die_die_die.tres",
	"res://resources/cards/disarm.tres",
	"res://resources/cards/double_strike.tres",
	"res://resources/cards/flame_barrier.tres",
	"res://resources/cards/footwork.tres",
	"res://resources/cards/headbutt.tres",
	"res://resources/cards/heavy_blow.tres",
	"res://resources/cards/impervious.tres",
	"res://resources/cards/inflame.tres",
	"res://resources/cards/iron_fortress.tres",
	"res://resources/cards/iron_wave.tres",
	"res://resources/cards/leg_sweep.tres",
	"res://resources/cards/malaise.tres",
	"res://resources/cards/metallicize.tres",
	"res://resources/cards/neutralize.tres",
	"res://resources/cards/noxious_fumes.tres",
	"res://resources/cards/offering.tres",
	"res://resources/cards/piercing_wail.tres",
	"res://resources/cards/poisoned_stab.tres",
	"res://resources/cards/pommel_strike.tres",
	"res://resources/cards/predator.tres",
	"res://resources/cards/quick_slash.tres",
	"res://resources/cards/rage.tres",
	"res://resources/cards/shield_bash.tres",
	"res://resources/cards/shiv.tres",
	"res://resources/cards/shrug_it_off.tres",
	"res://resources/cards/slice.tres",
	"res://resources/cards/strike.tres",
	"res://resources/cards/strike_s.tres",
	"res://resources/cards/sucker_punch.tres",
	"res://resources/cards/survivor.tres",
	"res://resources/cards/sword_and_shield.tres",
	"res://resources/cards/true_grit.tres",
	"res://resources/cards/uppercut.tres",
	"res://resources/cards/war_cry.tres",
	"res://resources/cards/war_stomp.tres",
	"res://resources/cards/whirlwind.tres",
	"res://resources/cards/wraith_form.tres",
]

static var _cache: Array[CardData] = []

## Load all cards (cached after first call).
static func get_all_cards() -> Array[CardData]:
	if not _cache.is_empty():
		return _cache
	for path in CARD_PATHS:
		var card = load(path) as CardData
		if card:
			_cache.append(card)
	return _cache

## Get non-starter Warrior card pool (legacy compatibility).
static func get_non_starter_pool(exclude_names: Array[String] = ["Strike", "Defend", "Bash"]) -> Array[CardData]:
	var pool: Array[CardData] = []
	for card in get_all_cards():
		if card.card_name not in exclude_names:
			pool.append(card)
	return pool

## Get cards for a specific class, excluding starter card names.
static func get_class_pool(pool_class: String, starter_names: Dictionary) -> Array[CardData]:
	var pool: Array[CardData] = []
	for card in get_all_cards():
		if card.character_class == pool_class and not starter_names.has(card.card_name):
			pool.append(card)
	return pool

## Build name-to-CardData lookup dictionary.
static func get_card_lookup() -> Dictionary:
	var lookup := {}
	for card in get_all_cards():
		lookup[card.card_name] = card
	return lookup
