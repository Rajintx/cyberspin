class_name ClassDatabase
extends RefCounted

## Master catalog of playable Specialist Classes, starting builds, and perks.

const CLASSES: Dictionary = {
	RunState.SpecialistClass.SNIPER: {
		"id": "sniper",
		"name": "🎯 LASER SNIPER",
		"subtitle": "Burst Cyber-Artillery & Bleeds",
		"starting_credits": 50,
		"max_ram": 2,
		"starting_relics": [],
		"starter_deck": [
			{"id": "laser", "count": 4},
			{"id": "arc_blade", "count": 3},
			{"id": "firewall", "count": 3},
			{"id": "ram_bit", "count": 1},
			{"id": "battery", "count": 2}
		]
	},
	RunState.SpecialistClass.TANK: {
		"id": "tank",
		"name": "🛡️ FIREWALL TANK",
		"subtitle": "Heavy Armor & Reflect Damage",
		"starting_credits": 50,
		"max_ram": 2,
		"starting_relics": ["plasma_converter"],
		"starter_deck": [
			{"id": "firewall", "count": 4},
			{"id": "fortress", "count": 3},
			{"id": "laser", "count": 3},
			{"id": "ram_bit", "count": 2},
			{"id": "battery", "count": 2}
		]
	},
	RunState.SpecialistClass.HACKER: {
		"id": "hacker",
		"name": "☣️ MALWARE HACKER",
		"subtitle": "Viral DoTs, EMP Stuns & High RAM",
		"starting_credits": 45,
		"max_ram": 3,
		"starting_relics": ["viral_payload"],
		"starter_deck": [
			{"id": "virus_worm", "count": 4},
			{"id": "igniter", "count": 3},
			{"id": "emp_disruptor", "count": 3},
			{"id": "firewall", "count": 2},
			{"id": "ram_bit", "count": 2}
		]
	},
	RunState.SpecialistClass.GAMBLER: {
		"id": "gambler",
		"name": "🎰 HIGH-ROLLER",
		"subtitle": "Massive Bankroll & 777 Jackpots",
		"starting_credits": 75,
		"max_ram": 2,
		"starting_relics": [],
		"starter_deck": [
			{"id": "crypto_miner", "count": 3},
			{"id": "jackpot_7", "count": 3},
			{"id": "laser", "count": 3},
			{"id": "firewall", "count": 3},
			{"id": "ram_bit", "count": 2}
		]
	}
}

static func get_class_data(specialist: RunState.SpecialistClass) -> Dictionary:
	return CLASSES.get(specialist, {})
