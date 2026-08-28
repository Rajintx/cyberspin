class_name EnemyDatabase
extends RefCounted

## Declarative Dictionary catalog of all Sector Encounters, Elites, and Bosses.

const ENEMIES_BY_FLOOR: Dictionary = {
	1: {
		"id": "sec_drone",
		"name": "V-9 Patrol Drone",
		"hp": 500,
		"shield": 15,
		"avatar": "🤖",
		"color": Color(0.0, 0.85, 1.0),
		"bounty": 18,
		"is_elite": false,
		"is_boss": false,
		"quote": "SCANNING SECTOR... PIRATE TERMINAL ISOLATED.",
		"intents": [
			{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 1, "name": "Spike Emitter", "desc": "Plants 1 📌 Data Spike (11 DMG on landing)."},
			{"type": EnemyData.IntentType.SHIELD_UP, "value": 15, "name": "Deflection Matrix", "desc": "Deploys +15 Shield."},
			{"type": EnemyData.IntentType.INJECT_POISON, "value": 1, "name": "Malware Worm", "desc": "Plants 1 ☣️ Poison trap (drains 5 Credits/turn)."},
			{"type": EnemyData.IntentType.ATTACK, "value": 9, "name": "Pulse Blaster", "desc": "Fires a 9 DMG Cyber Laser."}
		]
	},
	2: {
		"id": "corp_enforcer",
		"name": "Sector Enforcer Mech",
		"hp": 750,
		"shield": 20,
		"avatar": "🦿",
		"color": Color(0.2, 0.6, 1.0),
		"bounty": 28,
		"is_elite": false,
		"is_boss": false,
		"quote": "SURRENDER TERMINAL ASSETS TO CORPORATE POLICE.",
		"intents": [
			{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 1, "name": "Spike Minefield", "desc": "Plants 1 📌 Data Spike (12 DMG)."},
			{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 4, "hits": 3, "name": "Burst Fire", "desc": "Fires 3 rapid lasers (3x 4 = 12 DMG)."},
			{"type": EnemyData.IntentType.INJECT_POISON, "value": 1, "name": "Toxic Gas Vent", "desc": "Infects 1 slot with ☣️ Poison (6 CR/turn)."},
			{"type": EnemyData.IntentType.SHIELD_UP, "value": 20, "name": "Heavy Plating", "desc": "Deploys +20 Armor."}
		]
	},
	3: {
		"id": "cyber_viper",
		"name": "Sub-Routine Cyber-Viper [ELITE]",
		"hp": 1250,
		"shield": 60,
		"avatar": "🐍",
		"color": Color(0.9, 0.1, 0.4),
		"bounty": 42,
		"is_elite": true,
		"is_boss": false,
		"quote": "HOSTILE INTEL DETECTED. PURGE PROTOCOL ACTIVE.",
		"intents": [
			{"type": EnemyData.IntentType.INJECT_POISON, "value": 1, "name": "Neuro-Venom", "desc": "Infects 1 slot with ☣️ Toxic Plague (15 CR/turn)."},
			{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Spike Net", "desc": "Plants 2 📌 Mega Spikes (25 DMG)!"},
			{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 6, "hits": 3, "name": "Venom Flurry", "desc": "3 strikes (3x 6 = 18 DMG)!"},
			{"type": EnemyData.IntentType.SHIELD_UP, "value": 40, "name": "Hardened Shell", "desc": "Deploys +40 Nano-Shield."}
		]
	},
	4: {
		"id": "assault_bot",
		"name": "Assault Tank Sentinel",
		"hp": 1600,
		"shield": 40,
		"avatar": "🛡️",
		"color": Color(1.0, 0.45, 0.0),
		"bounty": 45,
		"is_elite": false,
		"is_boss": false,
		"quote": "DEFENSIVE PERIMETER COMPROMISED. REINFORCING ARMOR.",
		"intents": [
			{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Spike Mine", "desc": "Plants 2 📌 Spikes (14 DMG)!"},
			{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 10, "name": "Shockwave", "desc": "💥 Deals 10 DMG and triggers board hazards!"},
			{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Malware Mist", "desc": "Infects 2 slots with ☣️ Poison (7 CR/turn)."},
			{"type": EnemyData.IntentType.SHIELD_UP, "value": 35, "name": "Fortress Shield", "desc": "Deploys +35 Shield."}
		]
	},
	5: {
		"id": "overlord_prime",
		"name": "OVERLORD PRIME // STAGE 1 [BOSS]",
		"hp": 1000,
		"shield": 80,
		"avatar": "👁️",
		"color": Color(1.0, 0.05, 0.3),
		"bounty": 90,
		"is_elite": false,
		"is_boss": true,
		"quote": "YOU HAVE BREACHED THE CORE ARCHITECTURE. COMMENCING ERADICATION.",
		"intents": [
			{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Apex Spike Matrix", "desc": "Plants 2 📌 Data Spikes (20 DMG)!"},
			{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 7, "hits": 3, "name": "Triad Lasers", "desc": "Fires 3 heavy beams (3x 7 = 21 DMG)!"},
			{"type": EnemyData.IntentType.SHIELD_UP, "value": 60, "name": "Fortress Wall", "desc": "Deploys +60 Shield."},
			{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Core Malware", "desc": "Infects 2 slots with ☣️ Toxic Poison."}
		],
		"stages": [
			{
				"name": "OVERLORD PRIME // STAGE 1 [BOSS]",
				"avatar": "👁️",
				"hp": 1000,
				"shield": 80,
				"intents": [
					{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Apex Spike Matrix", "desc": "Plants 2 📌 Data Spikes (20 DMG)!"},
					{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 7, "hits": 3, "name": "Triad Lasers", "desc": "Fires 3 heavy beams (3x 7 = 21 DMG)!"},
					{"type": EnemyData.IntentType.SHIELD_UP, "value": 60, "name": "Fortress Wall", "desc": "Deploys +60 Shield."},
					{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Core Malware", "desc": "Infects 2 slots with ☣️ Toxic Poison."}
				]
			},
			{
				"name": "OVERLORD PRIME [STAGE 2: MELTDOWN CORE]",
				"avatar": "💀",
				"hp": 1200,
				"shield": 100,
				"intents": [
					{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Meltdown Spikes", "desc": "Plants 2 📌 Spikes (20 DMG)!"},
					{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 24, "name": "SYSTEM_DETONATE()", "desc": "💥 Deals 24 DMG and detonates all hazards!"},
					{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Toxic Overload", "desc": "Infects 2 slots with ☣️ Poison (10 CR/turn)."},
					{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 8, "hits": 3, "name": "Omega Meltdown Blast", "desc": "3 heavy blasts (3x 8 = 24 DMG)!"}
				]
			}
		]
	},
	6: {
		"id": "quantum_sentinel",
		"name": "Quantum Phase Sentinel",
		"hp": 3250,
		"shield": 70,
		"avatar": "💠",
		"color": Color(0.3, 0.9, 1.0),
		"bounty": 75,
		"is_elite": false,
		"is_boss": false,
		"quote": "TEMPORAL FREQUENCY SHIFTED. COMMENCING RETALIATION.",
		"intents": [
			{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Phase Spikes", "desc": "Plants 2 📌 Spikes (16 DMG)."},
			{"type": EnemyData.IntentType.SHIELD_UP, "value": 50, "name": "Quantum Barrier", "desc": "Deploys +50 Barrier Shield."},
			{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Phase Poison", "desc": "Infects 2 slots with ☣️ Poison (8 CR/turn)."},
			{"type": EnemyData.IntentType.ATTACK, "value": 18, "name": "Disruptor Lance", "desc": "Deals 18 Cyber Damage."}
		]
	},
	7: {
		"id": "nano_swarm",
		"name": "Nano-Swarm Hivemind AI [ELITE]",
		"hp": 850,
		"shield": 80,
		"avatar": "🐝",
		"color": Color(0.8, 0.2, 1.0),
		"bounty": 100,
		"is_elite": true,
		"is_boss": false,
		"quote": "WE ARE MILLIONS. YOUR TERMINAL WILL BE CONSUMED.",
		"intents": [
			{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 5, "hits": 4, "name": "Swarm Barrage", "desc": "4 rapid hits (4x 5 = 20 DMG)!"},
			{"type": EnemyData.IntentType.INJECT_POISON, "value": 2, "name": "Nanite Infection", "desc": "Infects 2 slots with ☣️ Poison (8 CR/turn)."},
			{"type": EnemyData.IntentType.CORRUPT_REEL, "value": 2, "name": "Swarm Glitch", "desc": "Glitch locks 2 orbital reels!"},
			{"type": EnemyData.IntentType.SHIELD_UP, "value": 50, "name": "Nanite Armor", "desc": "Deploys +50 Shield."}
		]
	},
	8: {
		"id": "aegis_leviathan",
		"name": "Aegis Leviathan Dreadnought [ELITE]",
		"hp": 1150,
		"shield": 100,
		"avatar": "🛸",
		"color": Color(1.0, 0.4, 0.0),
		"bounty": 130,
		"is_elite": true,
		"is_boss": false,
		"quote": "ALL AIRSPACE RESTRICTED. LETHAL FORCE AUTHORIZED.",
		"intents": [
			{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 2, "name": "Orbital Spikes", "desc": "Plants 2 📌 Mega Spikes (18 DMG)!"},
			{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 6, "hits": 4, "name": "Gatling Lasers", "desc": "4 laser blasts (4x 6 = 24 DMG)!"},
			{"type": EnemyData.IntentType.INJECT_POISON, "value": 3, "name": "Bio-Plague", "desc": "Infects 3 slots with ☣️ Poison (9 CR/turn)."},
			{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 22, "name": "Particle Shockwave", "desc": "💥 Deals 22 DMG and triggers all hazards!"}
		]
	},
	9: {
		"id": "citadel_core",
		"name": "Citadel Command AI [ELITE]",
		"hp": 1500,
		"shield": 140,
		"avatar": "🏰",
		"color": Color(1.0, 0.15, 0.4),
		"bounty": 165,
		"is_elite": true,
		"is_boss": false,
		"quote": "YOU HAVE BREACHED 9 LAYERS OF SECURITY. THIS IS YOUR FINAL WARNING.",
		"intents": [
			{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 3, "name": "Citadel Spikes", "desc": "Arms 3 slots with 📌 Spikes (19 DMG)!"},
			{"type": EnemyData.IntentType.SHIELD_UP, "value": 75, "name": "Command Barrier", "desc": "Deploys +75 Heavy Shield."},
			{"type": EnemyData.IntentType.INJECT_POISON, "value": 3, "name": "Apex Malware", "desc": "Infects 3 slots with ☣️ Poison (9 CR/turn)!"},
			{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 25, "name": "CITADEL_OVERLOAD()", "desc": "💥 Deals 25 DMG and detonates all hazards!"}
		]
	},
	10: {
		"id": "omega_nexus",
		"name": "OMEGA NEXUS // STAGE 1: CITADEL [BOSS]",
		"hp": 550,
		"shield": 120,
		"avatar": "👁️",
		"color": Color(1.0, 0.05, 0.3),
		"bounty": 300,
		"is_elite": false,
		"is_boss": true,
		"quote": "I AM THE GOD-MACHINE. YOUR EXTINCTION HAS BEEN CALCULATED.",
		"intents": [
			{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 3, "name": "Omni-Spike Grid", "desc": "Arms 3 slots with 📌 Data Spikes (20 DMG)!"},
			{"type": EnemyData.IntentType.SHIELD_UP, "value": 80, "name": "God-Shield", "desc": "Deploys +80 Barrier."},
			{"type": EnemyData.IntentType.CORRUPT_REEL, "value": 2, "name": "Matrix Lock", "desc": "EMP Locks 2 reels!"},
			{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 7, "hits": 4, "name": "Citadel Beam", "desc": "4 heavy beams (4x 7 = 28 DMG)!"}
		],
		"stages": [
			{
				"name": "OMEGA NEXUS // STAGE 1: CITADEL [BOSS]",
				"avatar": "👁️",
				"hp": 550,
				"shield": 120,
				"intents": [
					{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 3, "name": "Omni-Spike Grid", "desc": "Arms 3 slots with 📌 Data Spikes (20 DMG)!"},
					{"type": EnemyData.IntentType.SHIELD_UP, "value": 80, "name": "God-Shield", "desc": "Deploys +80 Barrier."},
					{"type": EnemyData.IntentType.CORRUPT_REEL, "value": 2, "name": "Matrix Lock", "desc": "EMP Locks 2 reels!"},
					{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 7, "hits": 4, "name": "Citadel Beam", "desc": "4 heavy beams (4x 7 = 28 DMG)!"}
				]
			},
			{
				"name": "OMEGA NEXUS [STAGE 2: NEURAL SINGULARITY]",
				"avatar": "🌌",
				"hp": 950,
				"shield": 180,
				"intents": [
					{"type": EnemyData.IntentType.INJECT_POISON, "value": 3, "name": "God-Malware Overwrite", "desc": "Infects 3 slots with ☣️ Poison (10 CR/turn)!"},
					{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 3, "name": "Neural Spikes", "desc": "Plants 3 📌 Spikes (20 DMG)!"},
					{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 8, "hits": 4, "name": "Gatling Singularity", "desc": "4 lasers (4x 8 = 32 DMG)!"},
					{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 28, "name": "NEURAL_DETONATE()", "desc": "💥 Deals 28 DMG + triggers board hazards!"}
				]
			},
			{
				"name": "OMEGA NEXUS [STAGE 3: THE ARCHITECT]",
				"avatar": "👑",
				"hp": 1350,
				"shield": 250,
				"intents": [
					{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 3, "name": "Apocalypse Grid", "desc": "Plants 3 📌 Spikes (20 DMG)!"},
					{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 35, "name": "APOCALYPSE_DETONATE()", "desc": "💥 Deals 35 DMG and detonates all hazards!"},
					{"type": EnemyData.IntentType.HEAVY_ATTACK, "value": 45, "name": "EXECUTE_PURGE()", "desc": "Ultimate Overclock Strike dealing 45 DMG!"},
					{"type": EnemyData.IntentType.INJECT_POISON, "value": 3, "name": "Reality Dissolution", "desc": "Infects 3 slots with ☣️ Poison!"}
				]
			}
		]
	}
}

static func create_enemy_from_dict(data: Dictionary) -> EnemyData:
	var enemy := EnemyData.new()
	enemy.id = data.get("id", "enemy")
	enemy.display_name = data.get("name", "Enemy")
	enemy.max_hp = data.get("hp", 100)
	enemy.starting_shield = data.get("shield", 0)
	enemy.avatar_glyph = data.get("avatar", "👾")
	enemy.theme_color = data.get("color", Color.WHITE)
	enemy.credits_reward = data.get("bounty", 10)
	enemy.is_elite = data.get("is_elite", false)
	enemy.is_boss = data.get("is_boss", false)
	enemy.flavor_quote = data.get("quote", "")
	
	var intents: Array[Dictionary] = []
	for it in data.get("intents", []):
		intents.append(it as Dictionary)
	enemy.intent_sequence = intents

	var stages: Array[Dictionary] = []
	for st in data.get("stages", []):
		stages.append(st as Dictionary)
	enemy.stages = stages

	return enemy

static func build_enemy_library() -> Array[EnemyData]:
	var library: Array[EnemyData] = []
	for floor_num in range(1, 11):
		if ENEMIES_BY_FLOOR.has(floor_num):
			var e := create_enemy_from_dict(ENEMIES_BY_FLOOR[floor_num])
			library.append(e)
	return library

static func get_enemy_for_floor(floor_num: int) -> EnemyData:
	var clamped_floor := clampi(floor_num, 1, 10)
	if ENEMIES_BY_FLOOR.has(clamped_floor):
		return create_enemy_from_dict(ENEMIES_BY_FLOOR[clamped_floor])
	return null

static func get_mimic_enemy(floor_num: int = 1) -> EnemyData:
	var mimic := EnemyData.new()
	mimic.id = "trojan_mimic"
	mimic.display_name = "TROJAN MIMIC MECH [ELITE]"
	mimic.max_hp = int(round(80.0 * pow(1.3, float(floor_num - 1))))
	mimic.starting_shield = 35
	mimic.avatar_glyph = "📦"
	mimic.theme_color = Color(0.9, 0.2, 1.0)
	mimic.is_elite = true
	mimic.credits_reward = 65
	mimic.flavor_quote = "SURPRISE AMBUSH: CACHE PROTOCOL DECRYPTED AS LETHAL TROJAN."
	mimic.intent_sequence = [
		{"type": EnemyData.IntentType.PLANT_SPIKES, "value": 1, "name": "Bite Thorns", "desc": "Plants 1 📌 Spike on the grid (13 DMG)!"},
		{"type": EnemyData.IntentType.INJECT_POISON, "value": 1, "name": "Trojan Malware", "desc": "Infects 1 slot with ☣️ Poison (6 CR/turn)!"},
		{"type": EnemyData.IntentType.DETONATE_HAZARDS, "value": 14, "name": "Cache Detonation", "desc": "💥 Deals 14 DMG and detonates all hazards!"},
		{"type": EnemyData.IntentType.MULTI_ATTACK, "value": 5, "hits": 3, "name": "Chomp Flurry", "desc": "3 rapid bites (3x 5 = 15 DMG)!"}
	]
	return mimic
