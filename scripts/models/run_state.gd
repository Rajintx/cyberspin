extends Node

signal bankroll_changed(current: int, max_val: int)
signal shield_changed(current: int)
signal ram_changed(current: int, max_val: int)
signal bet_changed(bet_level: int, ante_cost: int, mult: float)
signal speed_changed(speed_mult: float)
signal deck_updated(deck: Array[SymbolData])
signal relics_updated(relics: Array[RelicData])

# Singleton reference
static var instance: Node

# Bankroll = Life / Health (When Bankroll hits 0, the player goes bankrupt / Game Over!)
var credits: int = 100
var max_bankroll_seen: int = 100
var player_shield: int = 0

var max_ram: int = 5
var player_ram: int = 5

var current_floor: int = 1
var current_node_type: String = "COMBAT"

# Betting Stakes
# Level 1: 5 Credits Ante, 1.0x Multiplier
# Level 2: 10 Credits Ante, 2.0x Multiplier
# Level 3: 20 Credits Ante, 3.5x Multiplier
var bet_level: int = 1
const BET_TIERS: Array[Dictionary] = [
	{"cost": 5, "mult": 1.0, "name": "STANDARD"},
	{"cost": 10, "mult": 2.0, "name": "OVERDRIVE 2X"},
	{"cost": 20, "mult": 3.5, "name": "HYPER 3.5X"}
]

# Game Speed Multiplier (1.0x, 1.5x, 2.5x)
var game_speed: float = 1.0

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

# Legacy compatibility properties for HP
var player_hp: int:
	get: return credits
	set(val): credits = val

var player_max_hp: int:
	get: return maxi(100, max_bankroll_seen)
	set(val): max_bankroll_seen = val

func _ready() -> void:
	instance = self
	_build_master_libraries()
	init_new_run()

func _build_master_libraries() -> void:
	all_symbol_library.clear()
	all_relic_library.clear()
	all_enemy_library.clear()

	# 1. Plasma Laser (Attack)
	var laser := SymbolData.new()
	laser.id = "laser"
	laser.display_name = "Plasma Laser"
	laser.symbol_type = SymbolData.SymbolType.ATTACK
	laser.base_chips = 7
	laser.mult_add = 1.0
	laser.icon_glyph = "⚡"
	laser.icon_color = Color(0.0, 0.95, 1.0)
	laser.glow_color = Color(0.0, 0.7, 1.0, 0.4)
	laser.description = "Deals 7 Base Chips (+1 Mult) Cyber Damage to Core."
	all_symbol_library.append(laser)

	# 2. Hyper Railgun (High Attack)
	var railgun := SymbolData.new()
	railgun.id = "railgun"
	railgun.display_name = "Hyper Railgun"
	railgun.symbol_type = SymbolData.SymbolType.ATTACK
	railgun.base_chips = 18
	railgun.mult_add = 2.0
	railgun.rarity = SymbolData.Rarity.UNCOMMON
	railgun.icon_glyph = "💥"
	railgun.icon_color = Color(1.0, 0.3, 0.1)
	railgun.glow_color = Color(1.0, 0.4, 0.0, 0.5)
	railgun.description = "Heavy artillery dealing 18 Base Chips (+2 Mult) Piercing Damage."
	all_symbol_library.append(railgun)

	# 3. Arc Blade (High Mult Attack)
	var blade := SymbolData.new()
	blade.id = "arc_blade"
	blade.display_name = "Arc Monoblade"
	blade.symbol_type = SymbolData.SymbolType.ATTACK
	blade.base_chips = 10
	blade.mult_add = 3.0
	blade.rarity = SymbolData.Rarity.UNCOMMON
	blade.icon_glyph = "🗡️"
	blade.icon_color = Color(0.9, 0.2, 0.9)
	blade.glow_color = Color(0.8, 0.1, 0.8, 0.5)
	blade.description = "High-critical blade delivering 10 Chips (+3 Mult)."
	all_symbol_library.append(blade)

	# 4. Nano Firewall (Shield)
	var shield := SymbolData.new()
	shield.id = "firewall"
	shield.display_name = "Nano Firewall"
	shield.symbol_type = SymbolData.SymbolType.SHIELD
	shield.base_chips = 8
	shield.icon_glyph = "🛡️"
	shield.icon_color = Color(0.1, 0.7, 1.0)
	shield.glow_color = Color(0.1, 0.5, 0.9, 0.4)
	shield.description = "Deploys +8 Firewall Shield to protect Bankroll."
	all_symbol_library.append(shield)

	# 5. Aegis Matrix (Heavy Shield)
	var fortress := SymbolData.new()
	fortress.id = "fortress"
	fortress.display_name = "Aegis Matrix"
	fortress.symbol_type = SymbolData.SymbolType.SHIELD
	fortress.base_chips = 18
	fortress.rarity = SymbolData.Rarity.UNCOMMON
	fortress.icon_glyph = "💠"
	fortress.icon_color = Color(0.3, 0.9, 1.0)
	fortress.glow_color = Color(0.2, 0.8, 1.0, 0.5)
	fortress.description = "Deploys +18 Heavy Firewall Shield."
	all_symbol_library.append(fortress)

	# 6. RAM Capacitor (Resource)
	var ram := SymbolData.new()
	ram.id = "ram_bit"
	ram.display_name = "RAM Capacitor"
	ram.symbol_type = SymbolData.SymbolType.RAM
	ram.base_chips = 2
	ram.icon_glyph = "💾"
	ram.icon_color = Color(0.2, 1.0, 0.4)
	ram.glow_color = Color(0.2, 0.9, 0.3, 0.4)
	ram.description = "Restores +2 RAM used for Locking reels and Hack abilities."
	all_symbol_library.append(ram)

	# 7. Overclock Cell (Adjacency Synergizer)
	var battery := SymbolData.new()
	battery.id = "battery"
	battery.display_name = "Overclock Cell"
	battery.symbol_type = SymbolData.SymbolType.BATTERY
	battery.base_chips = 2
	battery.rarity = SymbolData.Rarity.UNCOMMON
	battery.icon_glyph = "🔋"
	battery.icon_color = Color(1.0, 0.8, 0.0)
	battery.glow_color = Color(1.0, 0.7, 0.0, 0.5)
	battery.description = "SYNERGY: Overcharges adjacent perimeter symbols by +100% Value!"
	all_symbol_library.append(battery)

	# 8. Thermal Igniter (Burn DoT)
	var burn := SymbolData.new()
	burn.id = "igniter"
	burn.display_name = "Thermal Igniter"
	burn.symbol_type = SymbolData.SymbolType.OVERHEAT
	burn.base_chips = 5
	burn.icon_glyph = "🔥"
	burn.icon_color = Color(1.0, 0.45, 0.0)
	burn.glow_color = Color(1.0, 0.3, 0.0, 0.5)
	burn.description = "Applies 5 Overheat (Burn). Deals ticking damage at the start of each Boss turn."
	all_symbol_library.append(burn)

	# 9. Data Worm (Virus Bleed)
	var virus := SymbolData.new()
	virus.id = "virus_worm"
	virus.display_name = "Data Worm"
	virus.symbol_type = SymbolData.SymbolType.VIRUS
	virus.base_chips = 4
	virus.icon_glyph = "☣️"
	virus.icon_color = Color(0.8, 0.1, 1.0)
	virus.glow_color = Color(0.7, 0.0, 0.9, 0.5)
	virus.description = "Infects Boss with 4 Virus. Deals direct Bleed damage on EVERY lever spin!"
	all_symbol_library.append(virus)

	# 10. EMP Disruptor (Stun / Vulnerability Primer)
	var emp := SymbolData.new()
	emp.id = "emp_disruptor"
	emp.display_name = "EMP Disruptor"
	emp.symbol_type = SymbolData.SymbolType.EMP
	emp.base_chips = 4
	emp.rarity = SymbolData.Rarity.UNCOMMON
	emp.icon_glyph = "🌀"
	emp.icon_color = Color(0.1, 0.6, 1.0)
	emp.glow_color = Color(0.0, 0.5, 1.0, 0.5)
	emp.description = "Disrupts Boss subroutines with 4 EMP stacks and boosts Piercing strikes."
	all_symbol_library.append(emp)

	# 11. Glitch Exploit (Vulnerable)
	var glitch := SymbolData.new()
	glitch.id = "glitch_pod"
	glitch.display_name = "Glitch Exploit"
	glitch.symbol_type = SymbolData.SymbolType.GLITCH
	glitch.base_chips = 3
	glitch.rarity = SymbolData.Rarity.UNCOMMON
	glitch.icon_glyph = "👾"
	glitch.icon_color = Color(1.0, 0.0, 0.6)
	glitch.glow_color = Color(1.0, 0.0, 0.5, 0.5)
	glitch.description = "Applies 3 Glitch stacks. Increases all inward damage dealt to Boss by +50%."
	all_symbol_library.append(glitch)

	# 12. Cyber Jackpot 777 (Jackpot)
	var jackpot := SymbolData.new()
	jackpot.id = "jackpot_7"
	jackpot.display_name = "Neon Jackpot 7"
	jackpot.symbol_type = SymbolData.SymbolType.JACKPOT
	jackpot.base_chips = 30
	jackpot.mult_add = 5.0
	jackpot.rarity = SymbolData.Rarity.RARE
	jackpot.icon_glyph = "7️⃣"
	jackpot.icon_color = Color(1.0, 0.85, 0.1)
	jackpot.glow_color = Color(1.0, 0.8, 0.0, 0.7)
	jackpot.description = "JACKPOT CHIP: Grants 30 Chips, +5 Mult, and pays +25 Credits directly!"
	all_symbol_library.append(jackpot)

	# 13. Quantum Mirror (Replication)
	var mirror := SymbolData.new()
	mirror.id = "mirror_chip"
	mirror.display_name = "Quantum Mirror"
	mirror.symbol_type = SymbolData.SymbolType.MIRROR
	mirror.base_chips = 5
	mirror.rarity = SymbolData.Rarity.RARE
	mirror.icon_glyph = "🪞"
	mirror.icon_color = Color(0.7, 0.9, 1.0)
	mirror.glow_color = Color(0.6, 0.8, 1.0, 0.6)
	mirror.description = "Replicates the symbol on the opposite cross-core side for guaranteed cross beam!"
	all_symbol_library.append(mirror)

	# 14. Crypto Miner (Passive Dividend)
	var miner := SymbolData.new()
	miner.id = "crypto_miner"
	miner.display_name = "Crypto Miner"
	miner.symbol_type = SymbolData.SymbolType.MINER
	miner.base_chips = 8
	miner.rarity = SymbolData.Rarity.UNCOMMON
	miner.icon_glyph = "⛏️"
	miner.icon_color = Color(0.2, 0.9, 0.6)
	miner.glow_color = Color(0.1, 0.8, 0.5, 0.5)
	miner.description = "Mines +8 Credits dividend directly to your Bankroll on every spin!"
	all_symbol_library.append(miner)

	# Relic Library
	var r1 := RelicData.new()
	r1.id = "nano_regen"
	r1.display_name = "Nano Regenerator"
	r1.relic_type = RelicData.RelicType.NANO_REGEN
	r1.icon_glyph = "🧬"
	r1.icon_color = Color(0.2, 1.0, 0.6)
	r1.cost = 45
	r1.description = "Installs nano-firewalls to grant +6 Shield automatically on every lever spin."
	all_relic_library.append(r1)

	var r2 := RelicData.new()
	r2.id = "overclock_module"
	r2.display_name = "Overclock Sub-Module"
	r2.relic_type = RelicData.RelicType.OVERCLOCK_MODULE
	r2.icon_glyph = "⚡"
	r2.icon_color = Color(1.0, 0.8, 0.0)
	r2.cost = 60
	r2.description = "Battery cells now provide +150% adjacency multiplier instead of +100%."
	all_relic_library.append(r2)

	var r3 := RelicData.new()
	r3.id = "viral_payload"
	r3.display_name = "Viral Payload Injector"
	r3.relic_type = RelicData.RelicType.VIRAL_PAYLOAD
	r3.icon_glyph = "☣️"
	r3.icon_color = Color(0.8, 0.2, 1.0)
	r3.cost = 55
	r3.description = "Data Virus deals +5 bonus Cyber Damage whenever triggered and infects neighbors."
	all_relic_library.append(r3)

	var r4 := RelicData.new()
	r4.id = "reload_capacitor"
	r4.display_name = "Reserve RAM Bank"
	r4.relic_type = RelicData.RelicType.RELOAD_CAPACITOR
	r4.icon_glyph = "💾"
	r4.icon_color = Color(0.2, 0.8, 1.0)
	r4.cost = 50
	r4.description = "Increases Max RAM by +2 and starts every combat fully loaded."
	all_relic_library.append(r4)

	var r5 := RelicData.new()
	r5.id = "crypto_stake"
	r5.display_name = "High-Roller Stake"
	r5.relic_type = RelicData.RelicType.CRYPTO_STAKE
	r5.icon_glyph = "📈"
	r5.icon_color = Color(0.2, 1.0, 0.5)
	r5.cost = 70
	r5.description = "Every 40 Credits in your Bankroll adds +1 Base Multiplier to all attack lines!"
	all_relic_library.append(r5)

	var r6 := RelicData.new()
	r6.id = "plasma_converter"
	r6.display_name = "Kinetic Reflector"
	r6.relic_type = RelicData.RelicType.PLASMA_CONVERTER
	r6.icon_glyph = "🛡️"
	r6.icon_color = Color(0.0, 0.9, 1.0)
	r6.cost = 65
	r6.description = "Excess Firewall Shield is converted into direct counter-attack laser damage!"
	all_relic_library.append(r6)

	_build_enemies()

func _build_enemies() -> void:
	# Floor 1: Sector Patrol Drone
	var drone := EnemyData.new()
	drone.id = "sec_drone"
	drone.display_name = "V-9 Patrol Drone"
	drone.max_hp = 65
	drone.starting_shield = 12
	drone.avatar_glyph = "🤖"
	drone.theme_color = Color(0.0, 0.85, 1.0)
	drone.credits_reward = 35
	drone.flavor_quote = "SCANNING SECTOR... PIRATE TERMINAL ISOLATED."
	drone.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 1, "name": "Spike Emitter", "desc": "Plants a 📌 Data Spike on 1 orbital slot (10 DMG on landing)."},
		{"type": EnemyData.IntentType.SHIELD_UP, "value": 14, "name": "Deflection Matrix", "desc": "Deploys +14 Shield."},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 1, "name": "Malware Injector", "desc": "Plants a ☣️ Poison trap on 1 slot (drains 6 Credits/turn)."},
		{"type": EnemyData.IntentType.ATTACK, "value": 10, "name": "Pulse Blaster", "desc": "Fires a 10 DMG Cyber Laser."}
	]
	all_enemy_library.append(drone)

	# Floor 2: Corp Enforcer & Cyber-Hound
	var enforcer := EnemyData.new()
	enforcer.id = "corp_enforcer"
	enforcer.display_name = "Sector Enforcer Mech"
	enforcer.max_hp = 110
	enforcer.starting_shield = 24
	enforcer.avatar_glyph = "🦿"
	enforcer.theme_color = Color(0.2, 0.6, 1.0)
	enforcer.credits_reward = 50
	enforcer.flavor_quote = "SURRENDER TERMINAL ASSETS TO CORPORATE POLICE."
	enforcer.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Spike Minefield", "desc": "Plants 📌 Data Spikes on 2 orbital slots!"},
		{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 5, "hits": 3, "name": "Burst Fire", "desc": "Fires 3 rapid lasers (3x 5 = 15 DMG)."},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Toxic Gas Vent", "desc": "Infects 2 orbital slots with ☣️ Poison!"},
		{"type": EnemyData.IntentType.SHIELD_UP, "value": 20, "name": "Heavy Plating", "desc": "Deploys +20 Armor."}
	]
	all_enemy_library.append(enforcer)

	# Floor 3: Elite AI Subroutine Viper
	var viper := EnemyData.new()
	viper.id = "cyber_viper"
	viper.display_name = "Sub-Routine Viper AI"
	viper.max_hp = 175
	viper.starting_shield = 35
	viper.avatar_glyph = "🐍"
	viper.theme_color = Color(0.9, 0.1, 0.4)
	viper.is_elite = true
	viper.credits_reward = 80
	viper.flavor_quote = "HOSTILE INTEL DETECTED. PURGE PROTOCOL ACTIVE."
	viper.intent_sequence = [
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Neuro-Venom", "desc": "Infects 2 slots with ☣️ Poison and inflicts Overheat."},
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Spike Net", "desc": "Plants 📌 Spikes on 2 slots!"},
		{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 12, "name": "Synapse Detonator", "desc": "💥 Detonates all active tile hazards on board for double damage!"},
		{"type": EnemyData.IntentType.SHIELD_UP, "value": 28, "name": "Hardened Shell", "desc": "Deploys +28 Nano-Shield."}
	]
	all_enemy_library.append(viper)

	# Floor 4: Cyber-Leviathan Heavy Drone
	var leviathan := EnemyData.new()
	leviathan.id = "leviathan"
	leviathan.display_name = "Aegis-Class Dreadnought"
	leviathan.max_hp = 260
	leviathan.starting_shield = 50
	leviathan.avatar_glyph = "🛸"
	leviathan.theme_color = Color(1.0, 0.4, 0.0)
	leviathan.is_elite = true
	leviathan.credits_reward = 110
	leviathan.flavor_quote = "COMMENCING TOTAL SECTOR AIRSPACE LOCKDOWN."
	leviathan.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 3, "name": "Orbital Spike Launcher", "desc": "Plants 📌 Spikes across 3 orbital slots!"},
		{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 7, "hits": 4, "name": "Gatling Lasers", "desc": "4 heavy laser blasts (4x 7 = 28 DMG)."},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Bio-Plague Corruptor", "desc": "Infects 2 slots with ☣️ Poison!"},
		{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 18, "name": "Particle Shockwave", "desc": "💥 Deals 18 DMG and triggers all board hazards!"}
	]
	all_enemy_library.append(leviathan)

	# Floor 5: Megacorp Nexus Core (Final Boss)
	var mainframe := EnemyData.new()
	mainframe.id = "corp_mainframe"
	mainframe.display_name = "MEGACORP NEXUS CORE"
	mainframe.max_hp = 380
	mainframe.starting_shield = 65
	mainframe.avatar_glyph = "👁️"
	mainframe.theme_color = Color(1.0, 0.05, 0.3)
	mainframe.is_boss = true
	mainframe.credits_reward = 250
	mainframe.flavor_quote = "I AM THE FOUNDATION OF REALITY. YOU CANNOT BREACH THIS NEXUS."
	mainframe.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 3, "name": "Quantum Spike Matrix", "desc": "Arms 3 slots with 📌 Data Spikes!"},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 3, "name": "Apex Malware Infestation", "desc": "Infects 3 slots with ☣️ Poison!"},
		{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 25, "name": "SYSTEM_DETONATE()", "desc": "💥 Deals 25 DMG and detonates all board hazards!"},
		{"type": EnemyData.IntentType.HEAVY_ATTACK, "value": 45, "name": "EXECUTE_PURGE()", "desc": "Ultimate Overclock Strike dealing 45 DMG!"}
	]
	all_enemy_library.append(mainframe)

func init_new_run() -> void:
	credits = 100
	max_bankroll_seen = 100
	player_shield = 0
	max_ram = 5
	player_ram = max_ram
	current_floor = 1
	bet_level = 1
	game_speed = 1.0
	total_spins = 0
	total_jackpots = 0
	highest_single_spin_dmg = 0
	total_enemies_purged = 0
	relics.clear()
	symbol_deck.clear()

	# Populate starter deck (16 well-balanced cyber symbols)
	_add_starter_symbols("laser", 4)
	_add_starter_symbols("firewall", 4)
	_add_starter_symbols("ram_bit", 3)
	_add_starter_symbols("battery", 2)
	_add_starter_symbols("igniter", 2)
	_add_starter_symbols("crypto_miner", 1)

	bankroll_changed.emit(credits, max_bankroll_seen)
	shield_changed.emit(player_shield)
	ram_changed.emit(player_ram, max_ram)
	bet_changed.emit(bet_level, get_current_ante(), get_current_mult())
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

func get_random_draft_symbols(count: int = 3) -> Array[SymbolData]:
	var result: Array[SymbolData] = []
	var pool := all_symbol_library.duplicate()
	pool.shuffle()
	for i in range(mini(count, pool.size())):
		result.append(pool[i].duplicate())
	return result

func get_random_relics(count: int = 3) -> Array[RelicData]:
	var result: Array[RelicData] = []
	var pool := all_relic_library.duplicate()
	pool.shuffle()
	for i in range(mini(count, pool.size())):
		result.append(pool[i].duplicate())
	return result

func get_enemy_for_node(node_type: String) -> EnemyData:
	match node_type:
		"BOSS":
			return all_enemy_library[4].duplicate() # Megacorp Mainframe (Floor 5)
		"ELITE":
			if current_floor >= 4:
				return all_enemy_library[3].duplicate() # Leviathan
			return all_enemy_library[2].duplicate() # Viper
		_:
			if current_floor >= 2:
				return all_enemy_library[1].duplicate() # Enforcer
			return all_enemy_library[0].duplicate() # Drone

func add_symbol(s: SymbolData) -> void:
	symbol_deck.append(s)
	deck_updated.emit(symbol_deck)

func remove_symbol_at(index: int) -> void:
	if index >= 0 and index < symbol_deck.size():
		symbol_deck.remove_at(index)
		deck_updated.emit(symbol_deck)

func add_relic(r: RelicData) -> void:
	relics.append(r)
	if r.relic_type == RelicData.RelicType.RELOAD_CAPACITOR:
		max_ram += 2
		player_ram = max_ram
		ram_changed.emit(player_ram, max_ram)
	relics_updated.emit(relics)

func has_relic(type: RelicData.RelicType) -> bool:
	for r in relics:
		if r.relic_type == type:
			return true
	return false

func get_current_ante() -> int:
	return BET_TIERS[bet_level - 1]["cost"]

func get_current_mult() -> float:
	return BET_TIERS[bet_level - 1]["mult"]

func cycle_bet_level() -> void:
	bet_level = (bet_level % BET_TIERS.size()) + 1
	bet_changed.emit(bet_level, get_current_ante(), get_current_mult())

func cycle_game_speed() -> void:
	if game_speed == 1.0:
		game_speed = 1.5
	elif game_speed == 1.5:
		game_speed = 2.5
	else:
		game_speed = 1.0
	speed_changed.emit(game_speed)

func spend_spin_bet() -> bool:
	var cost := get_current_ante()
	if credits >= cost:
		credits -= cost
		bankroll_changed.emit(credits, max_bankroll_seen)
		return true
	# Low bankroll: allow emergency all-in spin if credits > 0
	if credits > 0:
		credits = 0
		bankroll_changed.emit(credits, max_bankroll_seen)
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
	# Modifying HP is modifying Bankroll!
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
		if credits <= 0:
			# Bankruptcy
			pass

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
