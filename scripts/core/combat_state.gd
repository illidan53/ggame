class_name CombatState
extends RefCounted

var player: Combatant
var enemies: Array[Combatant] = []
var draw_pile: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []
var exhaust_pile: Array[CardInstance] = []
var turn_number: int = 0
var is_combat_over: bool = false
var combat_result: String = ""  # "victory", "defeat", ""
