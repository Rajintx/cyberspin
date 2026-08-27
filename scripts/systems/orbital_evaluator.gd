class_name OrbitalEvaluator
extends RefCounted

# The 8 orbital slot positions in clockwise ring order:
# 0: (0,0) Top-Left
# 1: (1,0) Top-Mid
# 2: (2,0) Top-Right
# 3: (2,1) Right-Mid
# 4: (2,2) Bot-Right
# 5: (1,2) Bot-Mid
# 6: (0,2) Bot-Left
# 7: (0,1) Left-Mid

const RING_ORDER: Array[Vector2i] = [
	Vector2i(0, 0), # 0 Top-Left
	Vector2i(1, 0), # 1 Top-Mid
	Vector2i(2, 0), # 2 Top-Right
	Vector2i(2, 1), # 3 Right-Mid
	Vector2i(2, 2), # 4 Bot-Right
	Vector2i(1, 2), # 5 Bot-Mid
	Vector2i(0, 2), # 6 Bot-Left
	Vector2i(0, 1)  # 7 Left-Mid
]

static func evaluate_spin(
	grid_symbols: Array[SymbolData],
	is_boss_vulnerable: bool,
	active_relics: Array[RelicData],
	bet_mult: float = 1.0,
	bankroll: int = 100,
	is_laser_on_cooldown: bool = false
) -> Dictionary:
	var result := {
		"total_damage": 0,
		"total_shield": 0,
		"total_ram": 0,
		"overheat_stacks": 0,
		"virus_stacks": 0,
		"emp_stacks": 0,
		"glitch_stacks": 0,
		"credits_earned": 0,
		"lines_triggered": [],
		"synergy_notes": [],
		"slot_multipliers": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
		"is_jackpot_fever": false,
		"laser_fired": false,
		"self_bleed_count": 0
	}

	if grid_symbols.size() < 8:
		return result

	var active_symbols: Array[SymbolData] = []
	for s in grid_symbols:
		active_symbols.append(s)

	# 0. Quantum Mirror Resolution: Mirror copies opposite symbol (index + 4) % 8
	for i in range(8):
		var sym: SymbolData = active_symbols[i]
		if sym != null and sym.symbol_type == SymbolData.SymbolType.MIRROR:
			var opposite_idx: int = (i + 4) % 8
			var opp_sym: SymbolData = active_symbols[opposite_idx]
			if opp_sym != null and opp_sym.symbol_type != SymbolData.SymbolType.MIRROR:
				active_symbols[i] = opp_sym.duplicate()
				result.synergy_notes.append("Quantum Mirror replicated %s across the core!" % opp_sym.display_name)

	# Relic modifiers check
	var battery_boost: float = 1.0
	var virus_bonus_dmg: int = 0
	var nano_shield_bonus: int = 0
	var bankroll_extra_mult: float = 0.0

	for relic in active_relics:
		if relic.relic_type == RelicData.RelicType.OVERCLOCK_MODULE:
			battery_boost = 1.5
		elif relic.relic_type == RelicData.RelicType.VIRAL_PAYLOAD:
			virus_bonus_dmg = 5
		elif relic.relic_type == RelicData.RelicType.NANO_REGEN:
			nano_shield_bonus = 6
		elif relic.relic_type == RelicData.RelicType.CRYPTO_STAKE:
			bankroll_extra_mult = floorf(float(bankroll) / 40.0)

	result.total_shield += nano_shield_bonus

	# 1. Evaluate Adjacency / Battery Overclock Synergies around the ring
	for i in range(8):
		var sym: SymbolData = active_symbols[i]
		if sym == null:
			continue
		if sym.symbol_type == SymbolData.SymbolType.BATTERY:
			var prev_idx: int = (i - 1 + 8) % 8
			var next_idx: int = (i + 1) % 8
			var boost_amount: float = (float(sym.base_chips) * battery_boost)
			result.slot_multipliers[prev_idx] += boost_amount
			result.slot_multipliers[next_idx] += boost_amount
			result.synergy_notes.append("Reactor #%d overcharged slots #%d & #%d (+%.1fx)!" % [i, prev_idx, next_idx, boost_amount])

	# 2. Count 777 Jackpots for Fever Mode
	var jackpot_count: int = 0
	for sym_item in active_symbols:
		if sym_item != null and sym_item.symbol_type == SymbolData.SymbolType.JACKPOT:
			jackpot_count += 1

	if jackpot_count >= 2:
		result.is_jackpot_fever = true
		result.synergy_notes.append("🔥 NEON JACKPOT FEVER ACTIVATED! (3x Multiplier) 🔥")

	var fever_multiplier: float = 3.0 if result.is_jackpot_fever else 1.0

	# 3. Base Symbol Contributions (Chips x Mult)
	var raw_attack_chips: int = 0
	var total_attack_mult: float = 1.0 + bankroll_extra_mult

	for i in range(8):
		var sym: SymbolData = active_symbols[i]
		if sym == null:
			continue

		var slot_mult: float = result.slot_multipliers[i]

		match sym.symbol_type:
			SymbolData.SymbolType.ATTACK:
				if sym.id == "laser":
					if is_laser_on_cooldown:
						result.synergy_notes.append("⚡ Plasma Laser on Cooldown (1 Round)! Inactive.")
					else:
						raw_attack_chips += int(round(sym.base_chips * slot_mult))
						total_attack_mult += sym.mult_add
						result["laser_fired"] = true
				elif sym.id == "arc_blade":
					raw_attack_chips += int(round(sym.base_chips * slot_mult))
					total_attack_mult += sym.mult_add
					result.virus_stacks += 2
					result["self_bleed_count"] += 1
					result.synergy_notes.append("🗡️ Arc Monoblade: +2 Bleed to Boss! (4 Self-Bleed in 2 turns)")
				else:
					raw_attack_chips += int(round(sym.base_chips * slot_mult))
					total_attack_mult += sym.mult_add
			SymbolData.SymbolType.SHIELD:
				var eff_shd: int = int(round(sym.base_chips * slot_mult * bet_mult))
				result.total_shield += eff_shd
			SymbolData.SymbolType.RAM:
				result.total_ram += sym.base_chips
			SymbolData.SymbolType.OVERHEAT:
				result.overheat_stacks += sym.base_chips
			SymbolData.SymbolType.VIRUS:
				result.virus_stacks += sym.base_chips
				result.total_damage += virus_bonus_dmg
			SymbolData.SymbolType.EMP:
				result.emp_stacks += sym.base_chips
			SymbolData.SymbolType.GLITCH:
				result.glitch_stacks += sym.base_chips
			SymbolData.SymbolType.MINER:
				var mined: int = int(round(sym.base_chips * slot_mult * bet_mult))
				result.credits_earned += mined
				result.synergy_notes.append("Crypto Miner produced +%d Credits!" % mined)
			SymbolData.SymbolType.JACKPOT:
				raw_attack_chips += int(round(sym.base_chips * slot_mult))
				total_attack_mult += sym.mult_add
				var j_payout: int = int(round(6 * slot_mult * bet_mult))
				result.credits_earned += j_payout
				result.total_shield += int(round(6 * slot_mult))

	# Compute Total Attack Damage = (Chips x Mult) x BetMult x FeverMult
	if raw_attack_chips > 0:
		var computed_dmg: int = int(round(raw_attack_chips * total_attack_mult * bet_mult * fever_multiplier))
		result.total_damage += computed_dmg

	# 4. Evaluate Cross-Core Inward Piercing Lines (Shooting through center Boss Core)
	_check_cross_pair(1, 5, "Vertical Piercer", active_symbols, result, bet_mult)
	_check_cross_pair(7, 3, "Horizontal Piercer", active_symbols, result, bet_mult)
	_check_cross_pair(0, 4, "Diagonal Alpha Piercer", active_symbols, result, bet_mult)
	_check_cross_pair(2, 6, "Diagonal Beta Piercer", active_symbols, result, bet_mult)

	# 5. Perimeter Edge Triad Paylines
	_check_edge_triad([0, 1, 2], "Top Orbital Line", active_symbols, result, bet_mult)
	_check_edge_triad([2, 3, 4], "Right Orbital Line", active_symbols, result, bet_mult)
	_check_edge_triad([4, 5, 6], "Bottom Orbital Line", active_symbols, result, bet_mult)
	_check_edge_triad([6, 7, 0], "Left Orbital Line", active_symbols, result, bet_mult)

	# 6. Apply Vulnerability / Glitch Status Bonus (+50% Crit Damage)
	if is_boss_vulnerable and result.total_damage > 0:
		var bonus_dmg: int = int(round(result.total_damage * 0.5))
		result.total_damage += bonus_dmg
		result.synergy_notes.append("Glitch Exploited! +%d (+50%%) Critical Cyber Damage!" % bonus_dmg)

	return result

static func _check_cross_pair(idx_a: int, idx_b: int, line_name: String, symbols: Array[SymbolData], result: Dictionary, bet_mult: float) -> void:
	var a: SymbolData = symbols[idx_a]
	var b: SymbolData = symbols[idx_b]
	if a == null or b == null:
		return

	if a.symbol_type == b.symbol_type:
		var bonus_dmg: int = 0
		var bonus_shield: int = 0

		if a.symbol_type == SymbolData.SymbolType.ATTACK:
			bonus_dmg = int(round(12 * bet_mult))
		elif a.symbol_type == SymbolData.SymbolType.SHIELD:
			bonus_shield = int(round(12 * bet_mult))
		elif a.symbol_type == SymbolData.SymbolType.JACKPOT:
			bonus_dmg = int(round(25 * bet_mult))
			bonus_shield = int(round(12 * bet_mult))
			result.credits_earned += int(round(8 * bet_mult))
		else:
			bonus_dmg = int(round(8 * bet_mult))

		result.total_damage += bonus_dmg
		result.total_shield += bonus_shield

		result.lines_triggered.append({
			"name": line_name + " (CROSS-CORE PIERCE)",
			"indices": [idx_a, idx_b],
			"type": "CROSS_CORE",
			"bonus_damage": bonus_dmg,
			"bonus_shield": bonus_shield,
			"color": a.icon_color
		})

static func _check_edge_triad(indices: Array[int], line_name: String, symbols: Array[SymbolData], result: Dictionary, bet_mult: float) -> void:
	var a: SymbolData = symbols[indices[0]]
	var b: SymbolData = symbols[indices[1]]
	var c: SymbolData = symbols[indices[2]]
	if a == null or b == null or c == null:
		return

	if a.symbol_type == b.symbol_type and b.symbol_type == c.symbol_type:
		var bonus_dmg: int = int(round(18 * bet_mult))
		var bonus_shield: int = int(round(15 * bet_mult))
		result.total_damage += bonus_dmg
		result.total_shield += bonus_shield
		# Small 2 Credit bonus for a 3-of-a-kind edge line
		result.credits_earned += int(round(2 * bet_mult))

		result.lines_triggered.append({
			"name": line_name + " (TRIPLE MATCH)",
			"indices": indices,
			"type": "EDGE_TRIAD",
			"bonus_damage": bonus_dmg,
			"bonus_shield": bonus_shield,
			"color": a.icon_color
		})
