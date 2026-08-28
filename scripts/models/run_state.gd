extends Node

signal bankroll_changed(current: int, max_val: int)
signal shield_changed(current: int)
signal ram_changed(current: int, max_val: int)
signal spin_cost_changed(cost: int, turn_num: int)
signal speed_changed(speed_mult: float)
signal deck_updated(deck: Array[SymbolData])
signal relics_updated(relics: Array[RelicData])
signal crt_toggled(enabled: bool)
signal crt_params_changed(intensity: float, curvature: float)

# Singleton reference
static var instance: Node

enum SpecialistClass {
	SNIPER,   # 🎯 Laser Sniper (High Crit & Attack)
	TANK,     # 🛡️ Firewall Tank (Heavy Armor & Reflect)
	HACKER,   # ☣️ Malware Hacker (DoTs & High RAM)
	GAMBLER   # 🎰 Crypto High-Roller (Extra Bankroll & Jackpots)
}

var selected_class: SpecialistClass = SpecialistClass.SNIPER

# Bankroll = Life / Currency
var credits: int = 50
var max_bankroll_seen: int = 50
var player_shield: int = 0

# Starting RAM capacity: 2 Max RAM
var max_ram: int = 2
var player_ram: int = 2

var current_floor: int = 1
var current_node_type: String = "COMBAT"
var battle_turn_number: int = 1

# Game Speed Multiplier (0.6x, 1.0x, 1.5x, 2.5x)
var game_speed: float = 1.0
var is_crt_enabled: bool = true
var crt_level: float = 1.0 # 0.0 (Off) to 2.0 (Heavy Retro)
var crt_scanline_intensity: float = 0.16
var crt_curvature: float = 0.025

# Lifetime Run Statistics
var total_spins: int = 0
var total_jackpots: int = 0
var highest_single_spin_dmg: int = 0
var total_enemies_purged: int = 0

# Deck & Relics
var symbol_deck: Array[SymbolData] = []
var relics: Array[RelicData] = []
var all_symbol_library: Array[SymbolData] = []
var all_relic_library: Array[RelicData] = []
var all_enemy_library: Array[EnemyData] = []

const MAX_DECK_SIZE: int = 20

func _ready() -> void:
	instance = self
	_build_master_libraries()
	init_new_run(SpecialistClass.SNIPER)

func _build_master_libraries() -> void:
	all_symbol_library = SymbolDatabase.build_symbol_library()
	all_relic_library = RelicDatabase.build_relic_library()
	all_enemy_library = EnemyDatabase.build_enemy_library()

func get_mimic_enemy(floor_num: int = 1) -> EnemyData:
	return EnemyDatabase.get_mimic_enemy(floor_num)

func init_new_run(specialist: SpecialistClass = SpecialistClass.SNIPER) -> void:
	selected_class = specialist
	current_floor = 1
	game_speed = 1.0
	total_spins = 0
	total_jackpots = 0
	highest_single_spin_dmg = 0
	total_enemies_purged = 0
	relics.clear()
	symbol_deck.clear()

	var class_data := ClassDatabase.get_class_data(specialist)
	credits = class_data.get("starting_credits", 50)
	max_bankroll_seen = credits
	max_ram = class_data.get("max_ram", 2)
	player_ram = max_ram

	for sym_info in class_data.get("starter_deck", []):
		_add_starter_symbols(sym_info.get("id", ""), sym_info.get("count", 1))

	for relic_id in class_data.get("starting_relics", []):
		var relic := get_relic_by_id(relic_id)
		if relic:
			add_relic(relic)

	player_shield = 0
	battle_turn_number = 1

	bankroll_changed.emit(credits, max_bankroll_seen)
	shield_changed.emit(player_shield)
	ram_changed.emit(player_ram, max_ram)
	spin_cost_changed.emit(get_current_spin_cost(), battle_turn_number)
	speed_changed.emit(game_speed)
	deck_updated.emit(symbol_deck)
	relics_updated.emit(relics)

func _add_starter_symbols(id: String, count: int) -> void:
	var template := get_symbol_by_id(id)
	if template:
		for i in range(count):
			symbol_deck.append(template.duplicate())

func get_symbol_by_id(id: String) -> SymbolData:
	for s in all_symbol_library:
		if s.id == id:
			return s
	return null

func get_relic_by_id(id: String) -> RelicData:
	for r in all_relic_library:
		if r.id == id:
			return r
	return null

func get_random_draft_symbols(count: int = 3) -> Array[SymbolData]:
	var result: Array[SymbolData] = []
	var pool := all_symbol_library.duplicate()
	pool.shuffle()
	for i in range(mini(count, pool.size())):
		result.append(pool[i].duplicate())
	return result

func get_random_relics(count: int = 2) -> Array[RelicData]:
	var result: Array[RelicData] = []
	var pool := all_relic_library.duplicate()
	pool.shuffle()
	for i in range(mini(count, pool.size())):
		result.append(pool[i].duplicate())
	return result

func get_enemy_for_node(node_type: String, floor_num: int = 1) -> EnemyData:
	if node_type == "MIMIC":
		var mimic := get_mimic_enemy()
		mimic.max_hp = int(round(80.0 * pow(1.3, float(floor_num - 1))))
		return mimic
	var floor_idx: int = clampi(floor_num - 1, 0, all_enemy_library.size() - 1)
	return all_enemy_library[floor_idx].duplicate()

func can_add_symbol() -> bool:
	return symbol_deck.size() < MAX_DECK_SIZE

func replace_symbol_at(index: int, new_symbol: SymbolData) -> void:
	if index >= 0 and index < symbol_deck.size():
		symbol_deck[index] = new_symbol
		deck_updated.emit(symbol_deck)

# Escalating Spin Cost per Battle (Bandwidth Leak / Ante Inflation)
func get_current_spin_cost() -> int:
	var f: int = current_floor
	var floor_base: int = 2 + int(floor(float(f) * 0.8))
	var floor_cap: int = floor_base + 6 + (2 if f >= 5 else 0)
	var cost: int = clampi(floor_base + (battle_turn_number - 1), floor_base, floor_cap)
	return cost

func start_new_battle_turn() -> void:
	battle_turn_number += 1
	spin_cost_changed.emit(get_current_spin_cost(), battle_turn_number)

func reset_battle_turns() -> void:
	battle_turn_number = 1
	spin_cost_changed.emit(get_current_spin_cost(), battle_turn_number)

func spend_spin_bet() -> bool:
	var cost := get_current_spin_cost()
	if credits >= cost:
		credits -= cost
		bankroll_changed.emit(credits, max_bankroll_seen)
		return true
	return false

func get_ram_upgrade_cost() -> int:
	if max_ram == 2:
		return 50
	elif max_ram == 3:
		return 75
	elif max_ram == 4:
		return 100
	return -1

func upgrade_max_ram() -> bool:
	var cost := get_ram_upgrade_cost()
	if cost > 0 and credits >= cost:
		modify_credits(-cost)
		max_ram += 1
		player_ram = max_ram
		ram_changed.emit(player_ram, max_ram)
		return true
	return false

func cycle_bet_level() -> void:
	pass

func get_current_ante() -> int:
	return get_current_spin_cost()

func get_current_mult() -> float:
	return 1.0

func cycle_game_speed() -> void:
	if game_speed <= 0.6:
		game_speed = 1.0
	elif game_speed <= 1.0:
		game_speed = 1.5
	elif game_speed <= 1.5:
		game_speed = 2.5
	else:
		game_speed = 0.6
	speed_changed.emit(game_speed)

func toggle_crt() -> void:
	set_crt_enabled(not is_crt_enabled)

func set_crt_enabled(enabled: bool) -> void:
	is_crt_enabled = enabled
	crt_toggled.emit(is_crt_enabled)

func set_crt_level(lvl: float) -> void:
	crt_level = clampf(lvl, 0.0, 2.0)
	if crt_level <= 0.01:
		is_crt_enabled = false
		crt_toggled.emit(false)
	else:
		if not is_crt_enabled:
			is_crt_enabled = true
			crt_toggled.emit(true)
		crt_scanline_intensity = 0.16 * crt_level
		crt_curvature = 0.025 * crt_level
		crt_params_changed.emit(crt_scanline_intensity, crt_curvature)

func add_symbol(s: SymbolData) -> void:
	symbol_deck.append(s)
	deck_updated.emit(symbol_deck)

func remove_symbol_at(index: int) -> void:
	if index >= 0 and index < symbol_deck.size():
		symbol_deck.remove_at(index)
		deck_updated.emit(symbol_deck)

func add_relic(r: RelicData) -> void:
	if r == null:
		return
	relics.append(r)
	if r.relic_type == RelicData.RelicType.RELOAD_CAPACITOR:
		max_ram += 1
		player_ram = max_ram
		ram_changed.emit(player_ram, max_ram)
	relics_updated.emit(relics)

func has_relic(type: RelicData.RelicType) -> bool:
	for r in relics:
		if r.relic_type == type:
			return true
	return false

func add_credits(amount: int) -> void:
	if amount <= 0:
		return
	credits += amount
	if credits > max_bankroll_seen:
		max_bankroll_seen = credits
	bankroll_changed.emit(credits, max_bankroll_seen)

func modify_hp(amount: int) -> void:
	if amount > 0:
		add_credits(amount)
	elif amount < 0:
		take_damage_direct(abs(amount))

func take_damage_direct(amount: int) -> int:
	var remaining_dmg := amount
	if player_shield > 0:
		if remaining_dmg <= player_shield:
			player_shield -= remaining_dmg
			remaining_dmg = 0
		else:
			remaining_dmg -= player_shield
			player_shield = 0
		shield_changed.emit(player_shield)

	if remaining_dmg > 0:
		credits = maxi(0, credits - remaining_dmg)
		bankroll_changed.emit(credits, max_bankroll_seen)

	return remaining_dmg

func set_shield(val: int) -> void:
	player_shield = maxi(0, val)
	shield_changed.emit(player_shield)

func add_shield(amount: int) -> void:
	player_shield = maxi(0, player_shield + amount)
	shield_changed.emit(player_shield)

func spend_ram(amount: int) -> bool:
	if player_ram >= amount:
		player_ram -= amount
		ram_changed.emit(player_ram, max_ram)
		return true
	return false

func restore_ram(amount: int) -> void:
	player_ram = clampi(player_ram + amount, 0, max_ram)
	ram_changed.emit(player_ram, max_ram)

func modify_credits(amount: int) -> void:
	if amount >= 0:
		add_credits(amount)
	else:
		credits = maxi(0, credits + amount)
		bankroll_changed.emit(credits, max_bankroll_seen)
