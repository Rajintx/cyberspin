class_name EnemyData
extends Resource

enum IntentType {
	ATTACK,       # Hits player Shield / Bankroll
	MULTI_ATTACK, # Multiple rapid hits (e.g. 3x 8 DMG)
	HEAVY_ATTACK, # Massive telegraphed strike (e.g. 35+ DMG)
	SHIELD_UP,    # Gains firewall armor
	CORRUPT_REEL, # Locks / disables specific perimeter reels next spin
	OVERHEAT_DOT, # Inflicts burn on player
	BUFF_ATTACK   # Increases attack power for future turns
}

@export var id: String = "sec_drone"
@export var display_name: String = "V-9 Security Drone"
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
		"type": IntentType.ATTACK,
		"value": 10,
		"hits": 1,
		"name": "Pulse Cannon",
		"desc": "Fires a concentrated laser dealing 10 Cyber Damage."
	},
	{
		"type": IntentType.SHIELD_UP,
		"value": 15,
		"hits": 1,
		"name": "Deflection Matrix",
		"desc": "Deploys +15 Firewall Shield."
	},
	{
		"type": IntentType.ATTACK,
		"value": 16,
		"hits": 1,
		"name": "Charged Burst",
		"desc": "Deals 16 Heavy Cyber Damage."
	},
	{
		"type": IntentType.CORRUPT_REEL,
		"value": 2,
		"hits": 1,
		"name": "EMP Shockwave",
		"desc": "Glitch locks 2 random orbital slots next spin!"
	}
]
