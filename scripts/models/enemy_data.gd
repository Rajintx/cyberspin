class_name EnemyData
extends Resource

enum IntentType {
	ATTACK,            # Direct cyber hit
	MULTI_ATTACK,      # Rapid burst hits
	HEAVY_ATTACK,      # Massive telegraphed strike
	SHIELD_UP,         # Deploys Firewall defense
	CORRUPT_REEL,      # Glitch locks perimeter reels
	PLANT_SPIKES,      # 📌 Plants Data Spikes on perimeter tiles (damages bankroll when landed)
	INJECT_POISON,     # ☣️ Injects Poison Malware onto perimeter tiles (drains bankroll per turn)
	DETONATE_HAZARDS   # 💥 Triggers and overclocks all active tile hazards on the board
}

@export var id: String = "sec_drone"
@export var display_name: String = "V-9 Patrol Drone"
@export var max_hp: int = 70
@export var starting_shield: int = 15
@export var avatar_glyph: String = "🤖"
@export var theme_color: Color = Color(0.0, 0.85, 1.0)
@export var is_boss: bool = false
@export var is_elite: bool = false
@export var credits_reward: int = 35
@export_multiline var flavor_quote: String = "UNAUTHORIZED TERMINAL ACCESS DETECTED."

@export var intent_sequence: Array[Dictionary] = [
	{
		"type": IntentType.PLANT_SPIKES,
		"value": 1,
		"hits": 1,
		"name": "Spike Emitter",
		"desc": "Arms 1 orbital slot with a 📌 Data Spike (10 DMG on landing)."
	},
	{
		"type": IntentType.SHIELD_UP,
		"value": 14,
		"hits": 1,
		"name": "Deflection Matrix",
		"desc": "Deploys +14 Firewall Shield."
	},
	{
		"type": IntentType.INJECT_POISON,
		"value": 1,
		"hits": 1,
		"name": "Malware Worm",
		"desc": "Infects 1 orbital slot with ☣️ Poison (drains 6 Credits/turn)."
	},
	{
		"type": IntentType.ATTACK,
		"value": 12,
		"hits": 1,
		"name": "Charged Blaster",
		"desc": "Fires a 12 DMG Cyber Laser."
	}
]
