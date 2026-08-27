extends Node

signal bankroll_changed(current: int, max_val: int)
signal shield_changed(current: int)
signal ram_changed(current: int, max_val: int)
signal spin_cost_changed(cost: int, turn_num: int)
signal speed_changed(speed_mult: float)
signal deck_updated(deck: Array[SymbolData])
signal relics_updated(relics: Array[RelicData])
signal crt_toggled(enabled: bool)

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
	all_symbol_library.clear()
	all_relic_library.clear()
	all_enemy_library.clear()

	# 1. Plasma Laser (Attack)
	var laser := SymbolData.new()
	laser.id = "laser"
	laser.display_name = "Plasma Laser"
	laser.symbol_type = SymbolData.SymbolType.ATTACK
	laser.base_chips = 4
	laser.mult_add = 0.3
	laser.icon_glyph = "⚡"
	laser.icon_color = Color(0.0, 0.95, 1.0)
	laser.glow_color = Color(0.0, 0.7, 1.0, 0.4)
	laser.description = "Deals 4 Base Chips (+0.3 Mult) Cyber Damage."
	all_symbol_library.append(laser)

	# 2. Hyper Railgun (High Attack)
	var railgun := SymbolData.new()
	railgun.id = "railgun"
	railgun.display_name = "Hyper Railgun"
	railgun.symbol_type = SymbolData.SymbolType.ATTACK
	railgun.base_chips = 9
	railgun.mult_add = 0.6
	railgun.rarity = SymbolData.Rarity.UNCOMMON
	railgun.icon_glyph = "💥"
	railgun.icon_color = Color(1.0, 0.3, 0.1)
	railgun.glow_color = Color(1.0, 0.4, 0.0, 0.5)
	railgun.description = "Heavy artillery dealing 9 Base Chips (+0.6 Mult) Piercing Damage."
	all_symbol_library.append(railgun)

	# 3. Arc Monoblade (High Mult Attack)
	var blade := SymbolData.new()
	blade.id = "arc_blade"
	blade.display_name = "Arc Monoblade"
	blade.symbol_type = SymbolData.SymbolType.ATTACK
	blade.base_chips = 6
	blade.mult_add = 1.0
	blade.rarity = SymbolData.Rarity.UNCOMMON
	blade.icon_glyph = "🗡️"
	blade.icon_color = Color(0.9, 0.2, 0.9)
	blade.glow_color = Color(0.8, 0.1, 0.8, 0.5)
	blade.description = "High-critical blade delivering 6 Chips (+1.0 Mult)."
	all_symbol_library.append(blade)

	# 4. Nano Firewall (Shield)
	var shield := SymbolData.new()
	shield.id = "firewall"
	shield.display_name = "Nano Firewall"
	shield.symbol_type = SymbolData.SymbolType.SHIELD
	shield.base_chips = 5
	shield.icon_glyph = "🛡️"
	shield.icon_color = Color(0.1, 0.7, 1.0)
	shield.glow_color = Color(0.1, 0.5, 0.9, 0.4)
	shield.description = "Deploys +5 Firewall Shield to protect Bankroll."
	all_symbol_library.append(shield)

	# 5. Aegis Matrix (Heavy Shield)
	var fortress := SymbolData.new()
	fortress.id = "fortress"
	fortress.display_name = "Aegis Matrix"
	fortress.symbol_type = SymbolData.SymbolType.SHIELD
	fortress.base_chips = 11
	fortress.rarity = SymbolData.Rarity.UNCOMMON
	fortress.icon_glyph = "💠"
	fortress.icon_color = Color(0.3, 0.9, 1.0)
	fortress.glow_color = Color(0.2, 0.8, 1.0, 0.5)
	fortress.description = "Deploys +11 Heavy Firewall Shield."
	all_symbol_library.append(fortress)

	# 6. RAM Capacitor (Resource)
	var ram := SymbolData.new()
	ram.id = "ram_bit"
	ram.display_name = "RAM Capacitor"
	ram.symbol_type = SymbolData.SymbolType.RAM
	ram.base_chips = 1
	ram.icon_glyph = "💾"
	ram.icon_color = Color(0.2, 1.0, 0.4)
	ram.glow_color = Color(0.2, 0.9, 0.3, 0.4)
	ram.description = "Restores +1 RAM used for Locking reels and Cleanse/Hack abilities."
	all_symbol_library.append(ram)

	# 7. Overclock Cell (Adjacency Synergizer)
	var battery := SymbolData.new()
	battery.id = "battery"
	battery.display_name = "Overclock Cell"
	battery.symbol_type = SymbolData.SymbolType.BATTERY
	battery.base_chips = 1
	battery.rarity = SymbolData.Rarity.UNCOMMON
	battery.icon_glyph = "🔋"
	battery.icon_color = Color(1.0, 0.8, 0.0)
	battery.glow_color = Color(1.0, 0.7, 0.0, 0.5)
	battery.description = "SYNERGY: Overcharges adjacent perimeter symbols by +50% Value!"
	all_symbol_library.append(battery)

	# 8. Thermal Igniter (Burn DoT)
	var burn := SymbolData.new()
	burn.id = "igniter"
	burn.display_name = "Thermal Igniter"
	burn.symbol_type = SymbolData.SymbolType.OVERHEAT
	burn.base_chips = 3
	burn.icon_glyph = "🔥"
	burn.icon_color = Color(1.0, 0.45, 0.0)
	burn.glow_color = Color(1.0, 0.3, 0.0, 0.5)
	burn.description = "Applies 3 Overheat (Burn). Deals ticking damage at the start of each Boss turn."
	all_symbol_library.append(burn)

	# 9. Data Worm (Virus Bleed)
	var virus := SymbolData.new()
	virus.id = "virus_worm"
	virus.display_name = "Data Worm"
	virus.symbol_type = SymbolData.SymbolType.VIRUS
	virus.base_chips = 3
	virus.icon_glyph = "☣️"
	virus.icon_color = Color(0.8, 0.1, 1.0)
	virus.glow_color = Color(0.7, 0.0, 0.9, 0.5)
	virus.description = "Infects Boss with 3 Virus. Deals direct Bleed damage on EVERY lever spin!"
	all_symbol_library.append(virus)

	# 10. EMP Disruptor (Stun / Vulnerability Primer)
	var emp := SymbolData.new()
	emp.id = "emp_disruptor"
	emp.display_name = "EMP Disruptor"
	emp.symbol_type = SymbolData.SymbolType.EMP
	emp.base_chips = 2
	emp.rarity = SymbolData.Rarity.UNCOMMON
	emp.icon_glyph = "🌀"
	emp.icon_color = Color(0.1, 0.6, 1.0)
	emp.glow_color = Color(0.0, 0.5, 1.0, 0.5)
	emp.description = "Disrupts Boss subroutines with 2 EMP stacks and boosts Piercing strikes."
	all_symbol_library.append(emp)

	# 11. Glitch Exploit (Vulnerable)
	var glitch := SymbolData.new()
	glitch.id = "glitch_pod"
	glitch.display_name = "Glitch Exploit"
	glitch.symbol_type = SymbolData.SymbolType.GLITCH
	glitch.base_chips = 2
	glitch.rarity = SymbolData.Rarity.UNCOMMON
	glitch.icon_glyph = "👾"
	glitch.icon_color = Color(1.0, 0.0, 0.6)
	glitch.glow_color = Color(1.0, 0.0, 0.5, 0.5)
	glitch.description = "Applies 2 Glitch stacks. Increases all inward damage dealt to Boss by +50%."
	all_symbol_library.append(glitch)

	# 12. Cyber Jackpot 777 (Jackpot)
	var jackpot := SymbolData.new()
	jackpot.id = "jackpot_7"
	jackpot.display_name = "Neon Jackpot 7"
	jackpot.symbol_type = SymbolData.SymbolType.JACKPOT
	jackpot.base_chips = 16
	jackpot.mult_add = 1.5
	jackpot.rarity = SymbolData.Rarity.RARE
	jackpot.icon_glyph = "7️⃣"
	jackpot.icon_color = Color(1.0, 0.85, 0.1)
	jackpot.glow_color = Color(1.0, 0.8, 0.0, 0.7)
	jackpot.description = "JACKPOT CHIP: Grants 16 Chips, +1.5 Mult, and pays +6 Credits directly!"
	all_symbol_library.append(jackpot)

	# 13. Quantum Mirror (Replication)
	var mirror := SymbolData.new()
	mirror.id = "mirror_chip"
	mirror.display_name = "Quantum Mirror"
	mirror.symbol_type = SymbolData.SymbolType.MIRROR
	mirror.base_chips = 3
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
	miner.base_chips = 4
	miner.rarity = SymbolData.Rarity.UNCOMMON
	miner.icon_glyph = "⛏️"
	miner.icon_color = Color(0.2, 0.9, 0.6)
	miner.glow_color = Color(0.1, 0.8, 0.5, 0.5)
	miner.description = "Mines +2 Credits dividend directly to your Bankroll on every spin!"
	all_symbol_library.append(miner)

	# Relics
	var r1 := RelicData.new()
	r1.id = "nano_regen"
	r1.display_name = "Nano Regenerator"
	r1.relic_type = RelicData.RelicType.NANO_REGEN
	r1.icon_glyph = "🧬"
	r1.icon_color = Color(0.2, 1.0, 0.6)
	r1.cost = 30
	r1.description = "Installs nano-firewalls to grant +4 Shield automatically on every lever spin."
	all_relic_library.append(r1)

	var r2 := RelicData.new()
	r2.id = "overclock_module"
	r2.display_name = "Overclock Sub-Module"
	r2.relic_type = RelicData.RelicType.OVERCLOCK_MODULE
	r2.icon_glyph = "⚡"
	r2.icon_color = Color(1.0, 0.8, 0.0)
	r2.cost = 35
	r2.description = "Battery cells now provide +75% adjacency multiplier instead of +50%."
	all_relic_library.append(r2)

	var r3 := RelicData.new()
	r3.id = "viral_payload"
	r3.display_name = "Viral Payload Injector"
	r3.relic_type = RelicData.RelicType.VIRAL_PAYLOAD
	r3.icon_glyph = "☣️"
	r3.icon_color = Color(0.8, 0.2, 1.0)
	r3.cost = 35
	r3.description = "Data Virus deals +2 bonus Cyber Damage whenever triggered and infects neighbors."
	all_relic_library.append(r3)

	var r4 := RelicData.new()
	r4.id = "reload_capacitor"
	r4.display_name = "Reserve RAM Bank"
	r4.relic_type = RelicData.RelicType.RELOAD_CAPACITOR
	r4.icon_glyph = "💾"
	r4.icon_color = Color(0.2, 0.8, 1.0)
	r4.cost = 40
	r4.description = "Increases Max RAM by +1 and starts every combat fully loaded."
	all_relic_library.append(r4)

	var r5 := RelicData.new()
	r5.id = "crypto_stake"
	r5.display_name = "High-Roller Stake"
	r5.relic_type = RelicData.RelicType.CRYPTO_STAKE
	r5.icon_glyph = "📈"
	r5.icon_color = Color(0.2, 1.0, 0.5)
	r5.cost = 40
	r5.description = "Every 25 Credits in your Bankroll adds +0.3 Base Multiplier to all attack lines!"
	all_relic_library.append(r5)

	var r6 := RelicData.new()
	r6.id = "plasma_converter"
	r6.display_name = "Kinetic Reflector"
	r6.relic_type = RelicData.RelicType.PLASMA_CONVERTER
	r6.icon_glyph = "🛡️"
	r6.icon_color = Color(0.0, 0.9, 1.0)
	r6.cost = 35
	r6.description = "30% of absorbed Firewall Shield is converted into direct counter-attack laser damage!"
	all_relic_library.append(r6)

	_build_10_floor_enemies()

func _build_10_floor_enemies() -> void:
	all_enemy_library.clear()

	# Floor 1: Sector Patrol Drone (500 HP, 15 Shield, 18 💳 Bounty)
	var f1 := EnemyData.new()
	f1.id = "sec_drone"
	f1.display_name = "V-9 Patrol Drone"
	f1.max_hp = 500
	f1.starting_shield = 15
	f1.avatar_glyph = "🤖"
	f1.theme_color = Color(0.0, 0.85, 1.0)
	f1.credits_reward = 18
	f1.flavor_quote = "SCANNING SECTOR... PIRATE TERMINAL ISOLATED."
	f1.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 1, "name": "Spike Emitter", "desc": "Plants 1 📌 Data Spike (11 DMG on landing)."},
		{"type": EnemyData.IntentType.SHIELD_UP, "value": 15, "name": "Deflection Matrix", "desc": "Deploys +15 Shield."},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 1, "name": "Malware Worm", "desc": "Plants 1 ☣️ Poison trap (drains 5 Credits/turn)."},
		{"type": EnemyData.IntentType.ATTACK, "value": 9, "name": "Pulse Blaster", "desc": "Fires a 9 DMG Cyber Laser."}
	]
	all_enemy_library.append(f1)

	# Floor 2: Security Enforcer Mech (750 HP, 20 Shield, 28 💳 Bounty)
	var f2 := EnemyData.new()
	f2.id = "corp_enforcer"
	f2.display_name = "Sector Enforcer Mech"
	f2.max_hp = 750
	f2.starting_shield = 20
	f2.avatar_glyph = "🦿"
	f2.theme_color = Color(0.2, 0.6, 1.0)
	f2.credits_reward = 28
	f2.flavor_quote = "SURRENDER TERMINAL ASSETS TO CORPORATE POLICE."
	f2.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 1, "name": "Spike Minefield", "desc": "Plants 1 📌 Data Spike (12 DMG)."},
		{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 4, "hits": 3, "name": "Burst Fire", "desc": "Fires 3 rapid lasers (3x 4 = 12 DMG)."},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 1, "name": "Toxic Gas Vent", "desc": "Infects 1 slot with ☣️ Poison (6 CR/turn)."},
		{"type": EnemyData.IntentType.SHIELD_UP, "value": 20, "name": "Heavy Plating", "desc": "Deploys +20 Armor."}
	]
	all_enemy_library.append(f2)

	# Floor 3: [ELITE] Cyber-Viper AI (5,750 HP [50x], 125 Shield, 5x DMG, 42 💳 Bounty)
	var f3 := EnemyData.new()
	f3.id = "cyber_viper"
	f3.display_name = "Sub-Routine Cyber-Viper [ELITE]"
	f3.max_hp = 5750
	f3.starting_shield = 125
	f3.avatar_glyph = "🐍"
	f3.theme_color = Color(0.9, 0.1, 0.4)
	f3.is_elite = true
	f3.credits_reward = 42
	f3.flavor_quote = "HOSTILE INTEL DETECTED. PURGE PROTOCOL ACTIVE."
	f3.intent_sequence = [
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Neuro-Venom [5x]", "desc": "Infects 2 slots with ☣️ Toxic Plague (30 CR/turn)."},
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Spike Net [5x]", "desc": "Plants 2 📌 Mega Spikes (65 DMG)!"},
		{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 25, "hits": 3, "name": "Venom Flurry [5x]", "desc": "3 lethal strikes (3x 25 = 75 DMG)!"},
		{"type": EnemyData.IntentType.SHIELD_UP, "value": 100, "name": "Hardened Shell", "desc": "Deploys +100 Nano-Shield."}
	]
	all_enemy_library.append(f3)

	# Floor 4: Assault Sentinel Bot (1,600 HP, 40 Shield, 45 💳 Bounty)
	var f4 := EnemyData.new()
	f4.id = "assault_bot"
	f4.display_name = "Assault Tank Sentinel"
	f4.max_hp = 1600
	f4.starting_shield = 40
	f4.avatar_glyph = "🛡️"
	f4.theme_color = Color(1.0, 0.45, 0.0)
	f4.credits_reward = 45
	f4.flavor_quote = "DEFENSIVE PERIMETER COMPROMISED. REINFORCING ARMOR."
	f4.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Spike Mine", "desc": "Plants 2 📌 Spikes (14 DMG)!"},
		{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 10, "name": "Shockwave", "desc": "💥 Deals 10 DMG and triggers board hazards!"},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Malware Mist", "desc": "Infects 2 slots with ☣️ Poison (7 CR/turn)."},
		{"type": EnemyData.IntentType.SHIELD_UP, "value": 35, "name": "Fortress Shield", "desc": "Deploys +35 Shield."}
	]
	all_enemy_library.append(f4)

	# Floor 5: [BOSS] OVERLORD PRIME (2 Stages, 13,500 HP Total [50x], 5x DMG, 90 💳 Bounty)
	var f5 := EnemyData.new()
	f5.id = "overlord_prime"
	f5.display_name = "OVERLORD PRIME // STAGE 1 [BOSS]"
	f5.max_hp = 6000
	f5.starting_shield = 150
	f5.avatar_glyph = "👁️"
	f5.theme_color = Color(1.0, 0.05, 0.3)
	f5.is_boss = true
	f5.credits_reward = 90
	f5.flavor_quote = "YOU HAVE BREACHED THE CORE ARCHITECTURE. COMMENCING ERADICATION."
	f5.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Apex Spike Matrix [5x]", "desc": "Plants 2 📌 Mega Spikes (75 DMG)!"},
		{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 25, "hits": 3, "name": "Triad Lasers [5x]", "desc": "Fires 3 heavy beams (3x 25 = 75 DMG)!"},
		{"type": EnemyData.IntentType.SHIELD_UP, "value": 125, "name": "Fortress Wall", "desc": "Deploys +125 Shield."},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Core Malware [5x]", "desc": "Infects 2 slots with ☣️ Toxic Poison."}
	]
	f5.stages = [
		{
			"name": "OVERLORD PRIME // STAGE 1 [BOSS]",
			"avatar": "👁️",
			"hp": 6000,
			"shield": 150,
			"intents": f5.intent_sequence
		},
		{
			"name": "OVERLORD PRIME [STAGE 2: MELTDOWN CORE]",
			"avatar": "💀",
			"hp": 7500,
			"shield": 200,
			"intents": [
				{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 3, "name": "Meltdown Spikes [5x]", "desc": "Plants 3 📌 Spikes (75 DMG)!"},
				{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 80, "name": "SYSTEM_DETONATE() [5x]", "desc": "💥 Deals 80 DMG and detonates all hazards!"},
				{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Toxic Overload [5x]", "desc": "Infects 2 slots with ☣️ Poison (35 CR/turn)."},
				{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 30, "hits": 3, "name": "Omega Meltdown Blast [5x]", "desc": "3 heavy blasts (3x 30 = 90 DMG)!"}
			]
		}
	]
	all_enemy_library.append(f5)

	# Floor 6: Quantum Sentinel (3,250 HP, 70 Shield, 75 💳 Bounty)
	var f6 := EnemyData.new()
	f6.id = "quantum_sentinel"
	f6.display_name = "Quantum Phase Sentinel"
	f6.max_hp = 3250
	f6.starting_shield = 70
	f6.avatar_glyph = "💠"
	f6.theme_color = Color(0.3, 0.9, 1.0)
	f6.credits_reward = 75
	f6.flavor_quote = "TEMPORAL FREQUENCY SHIFTED. COMMENCING RETALIATION."
	f6.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Phase Spikes", "desc": "Plants 2 📌 Spikes (16 DMG)."},
		{"type": EnemyData.IntentType.SHIELD_UP, "value": 50, "name": "Quantum Barrier", "desc": "Deploys +50 Barrier Shield."},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Phase Poison", "desc": "Infects 2 slots with ☣️ Poison (8 CR/turn)."},
		{"type": EnemyData.IntentType.ATTACK, "value": 18, "name": "Disruptor Lance", "desc": "Deals 18 Cyber Damage."}
	]
	all_enemy_library.append(f6)

	# Floor 7: [ELITE] Nano-Swarm Hivemind (23,750 HP [50x], 475 Shield, 5x DMG, 100 💳 Bounty)
	var f7 := EnemyData.new()
	f7.id = "nano_swarm"
	f7.display_name = "Nano-Swarm Hivemind AI [ELITE]"
	f7.max_hp = 23750
	f7.starting_shield = 475
	f7.avatar_glyph = "🐝"
	f7.theme_color = Color(0.8, 0.2, 1.0)
	f7.is_elite = true
	f7.credits_reward = 100
	f7.flavor_quote = "WE ARE MILLIONS. YOUR TERMINAL WILL BE CONSUMED."
	f7.intent_sequence = [
		{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 25, "hits": 4, "name": "Swarm Barrage [5x]", "desc": "4 rapid hits (4x 25 = 100 DMG)!"},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 3, "name": "Nanite Infection [5x]", "desc": "Infects 3 slots with ☣️ Poison (40 CR/turn)."},
		{"type": EnemyData.IntentType.CORRUPT_REEL, "value": 2, "name": "Swarm Glitch", "desc": "Glitch locks 2 orbital reels!"},
		{"type": EnemyData.IntentType.SHIELD_UP, "value": 225, "name": "Nanite Armor", "desc": "Deploys +225 Shield."}
	]
	all_enemy_library.append(f7)

	# Floor 8: [ELITE] Aegis Leviathan Carrier (34,000 HP [50x], 700 Shield, 5x DMG, 130 💳 Bounty)
	var f8 := EnemyData.new()
	f8.id = "aegis_leviathan"
	f8.display_name = "Aegis Leviathan Dreadnought [ELITE]"
	f8.max_hp = 34000
	f8.starting_shield = 700
	f8.avatar_glyph = "🛸"
	f8.theme_color = Color(1.0, 0.4, 0.0)
	f8.is_elite = true
	f8.credits_reward = 130
	f8.flavor_quote = "ALL AIRSPACE RESTRICTED. LETHAL FORCE AUTHORIZED."
	f8.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 3, "name": "Orbital Spikes [5x]", "desc": "Plants 3 📌 Mega Spikes (90 DMG)!"},
		{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 30, "hits": 4, "name": "Gatling Lasers [5x]", "desc": "4 heavy laser blasts (4x 30 = 120 DMG)!"},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 3, "name": "Bio-Plague [5x]", "desc": "Infects 3 slots with ☣️ Poison (45 CR/turn)."},
		{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 100, "name": "Particle Shockwave [5x]", "desc": "💥 Deals 100 DMG and triggers all hazards!"}
	]
	all_enemy_library.append(f8)

	# Floor 9: [ELITE] Corporate Citadel Core (49,000 HP [50x], 950 Shield, 5x DMG, 165 💳 Bounty)
	var f9 := EnemyData.new()
	f9.id = "citadel_core"
	f9.display_name = "Citadel Command AI [ELITE]"
	f9.max_hp = 49000
	f9.starting_shield = 950
	f9.avatar_glyph = "🏰"
	f9.theme_color = Color(1.0, 0.15, 0.4)
	f9.is_elite = true
	f9.credits_reward = 165
	f9.flavor_quote = "YOU HAVE BREACHED 9 LAYERS OF SECURITY. THIS IS YOUR FINAL WARNING."
	f9.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 3, "name": "Citadel Spikes [5x]", "desc": "Arms 3 slots with 📌 Spikes (95 DMG)!"},
		{"type": EnemyData.IntentType.SHIELD_UP, "value": 325, "name": "Command Barrier", "desc": "Deploys +325 Heavy Shield."},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 3, "name": "Apex Malware [5x]", "desc": "Infects 3 slots with ☣️ Poison (45 CR/turn)!"},
		{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 120, "name": "CITADEL_OVERLOAD() [5x]", "desc": "💥 Deals 120 DMG and detonates all hazards!"}
	]
	all_enemy_library.append(f9)

	# Floor 10: [FINAL BOSS] OMEGA NEXUS CORE (3 Stages, 82,500 HP Total [50x], 5x DMG, 300 💳 Bounty)
	var f10 := EnemyData.new()
	f10.id = "omega_nexus"
	f10.display_name = "OMEGA NEXUS // STAGE 1: CITADEL [BOSS]"
	f10.max_hp = 22500
	f10.starting_shield = 500
	f10.avatar_glyph = "👁️"
	f10.theme_color = Color(1.0, 0.05, 0.3)
	f10.is_boss = true
	f10.credits_reward = 300
	f10.flavor_quote = "I AM THE GOD-MACHINE. YOUR EXTINCTION HAS BEEN CALCULATED."
	f10.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 3, "name": "Omni-Spike Grid [5x]", "desc": "Arms 3 slots with 📌 Data Spikes (100 DMG)!"},
		{"type": EnemyData.IntentType.SHIELD_UP, "value": 300, "name": "God-Shield", "desc": "Deploys +300 Barrier."},
		{"type": EnemyData.IntentType.CORRUPT_REEL, "value": 3, "name": "Matrix Lock", "desc": "EMP Locks 3 reels!"},
		{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 35, "hits": 4, "name": "Citadel Beam [5x]", "desc": "4 heavy beams (4x 35 = 140 DMG)!"}
	]
	f10.stages = [
		{
			"name": "OMEGA NEXUS // STAGE 1: CITADEL [BOSS]",
			"avatar": "👁️",
			"hp": 22500,
			"shield": 500,
			"intents": f10.intent_sequence
		},
		{
			"name": "OMEGA NEXUS [STAGE 2: NEURAL SINGULARITY]",
			"avatar": "🌌",
			"hp": 27500,
			"shield": 600,
			"intents": [
				{"type": EnemyData.IntentType.INJECT_POISON, "value": 3, "name": "God-Malware Overwrite [5x]", "desc": "Infects 3 slots with ☣️ Poison (50 CR/turn)!"},
				{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 3, "name": "Neural Spikes [5x]", "desc": "Plants 3 📌 Spikes (100 DMG)!"},
				{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 40, "hits": 4, "name": "Gatling Singularity [5x]", "desc": "4 lasers (4x 40 = 160 DMG)!"},
				{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 125, "name": "NEURAL_DETONATE() [5x]", "desc": "💥 Deals 125 DMG + triggers board hazards!"}
			]
		},
		{
			"name": "OMEGA NEXUS [STAGE 3: THE ARCHITECT]",
			"avatar": "👑",
			"hp": 32500,
			"shield": 750,
			"intents": [
				{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 4, "name": "Apocalypse Grid [5x]", "desc": "Plants 4 📌 Spikes (100 DMG)!"},
				{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 150, "name": "APOCALYPSE_DETONATE() [5x]", "desc": "💥 Deals 150 DMG and detonates all hazards!"},
				{"type": EnemyData.IntentType.HEAVY_ATTACK, "value": 200, "name": "EXECUTE_PURGE() [5x]", "desc": "Ultimate Overclock Strike dealing 200 DMG!"},
				{"type": EnemyData.IntentType.INJECT_POISON, "value": 4, "name": "Reality Dissolution [5x]", "desc": "Infects 4 slots with ☣️ Poison!"}
			]
		}
	]
	all_enemy_library.append(f10)

func get_mimic_enemy() -> EnemyData:
	var mimic := EnemyData.new()
	mimic.id = "trojan_mimic"
	mimic.display_name = "TROJAN MIMIC MECH [ELITE]"
	mimic.max_hp = 5500
	mimic.starting_shield = 125
	mimic.avatar_glyph = "📦"
	mimic.theme_color = Color(0.9, 0.2, 1.0)
	mimic.is_elite = true
	mimic.credits_reward = 65
	mimic.flavor_quote = "SURPRISE AMBUSH: CACHE PROTOCOL DECRYPTED AS LETHAL TROJAN."
	mimic.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Bite Thorns [5x]", "desc": "Plants 2 📌 Spikes on the grid (65 DMG)!"},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Trojan Malware [5x]", "desc": "Infects 2 slots with ☣️ Poison (30 CR/turn)!"},
		{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 70, "name": "Cache Detonation [5x]", "desc": "💥 Deals 70 DMG and detonates all hazards!"},
		{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 25, "hits": 3, "name": "Chomp Flurry [5x]", "desc": "3 rapid bites (3x 25 = 75 DMG)!"}
	]
	return mimic

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

	match specialist:
		SpecialistClass.SNIPER:
			credits = 50
			max_bankroll_seen = 50
			max_ram = 2
			player_ram = max_ram
			_add_starter_symbols("laser", 4)
			_add_starter_symbols("arc_blade", 3)
			_add_starter_symbols("firewall", 3)
			_add_starter_symbols("ram_bit", 2)
			_add_starter_symbols("battery", 2)
		SpecialistClass.TANK:
			credits = 50
			max_bankroll_seen = 50
			max_ram = 2
			player_ram = max_ram
			_add_starter_symbols("firewall", 4)
			_add_starter_symbols("fortress", 3)
			_add_starter_symbols("laser", 3)
			_add_starter_symbols("ram_bit", 2)
			_add_starter_symbols("battery", 2)
			add_relic(get_relic_by_id("plasma_converter"))
		SpecialistClass.HACKER:
			credits = 45
			max_bankroll_seen = 45
			max_ram = 3
			player_ram = max_ram
			_add_starter_symbols("virus_worm", 4)
			_add_starter_symbols("igniter", 3)
			_add_starter_symbols("emp_disruptor", 3)
			_add_starter_symbols("firewall", 2)
			_add_starter_symbols("ram_bit", 2)
			add_relic(get_relic_by_id("viral_payload"))
		SpecialistClass.GAMBLER:
			credits = 75
			max_bankroll_seen = 75
			max_ram = 2
			player_ram = max_ram
			_add_starter_symbols("crypto_miner", 3)
			_add_starter_symbols("jackpot_7", 3)
			_add_starter_symbols("laser", 3)
			_add_starter_symbols("firewall", 3)
			_add_starter_symbols("ram_bit", 2)

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
	if credits > 0:
		credits = 0
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
	is_crt_enabled = not is_crt_enabled
	crt_toggled.emit(is_crt_enabled)

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
