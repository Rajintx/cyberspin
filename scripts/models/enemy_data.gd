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
@export var max_hp: int = 50
@export var starting_shield: int = 10
@export var avatar_glyph: String = "🤖"
@export var theme_color: Color = Color(0.0, 0.85, 1.0)
@export var is_boss: bool = false
@export var is_elite: bool = false
@export var credits_reward: int = 18
@export_multiline var flavor_quote: String = "UNAUTHORIZED TERMINAL ACCESS DETECTED."

@export var intent_sequence: Array[Dictionary] = []
@export var stages: Array[Dictionary] = []
var current_stage_index: int = 0

func has_stages() -> bool:
	return not stages.is_empty()

func has_next_stage() -> bool:
	return has_stages() and (current_stage_index < stages.size() - 1)

func get_current_stage_data() -> Dictionary:
	if has_stages() and current_stage_index < stages.size():
		return stages[current_stage_index]
	return {}

func advance_to_next_stage() -> Dictionary:
	if has_next_stage():
		current_stage_index += 1
		var next_st: Dictionary = stages[current_stage_index]
		display_name = next_st.get("name", display_name)
		avatar_glyph = next_st.get("avatar", avatar_glyph)
		max_hp = next_st.get("hp", max_hp)
		starting_shield = next_st.get("shield", starting_shield)
		var raw_intents = next_st.get("intents", [])
		intent_sequence.clear()
		for item in raw_intents:
			if item is Dictionary:
				intent_sequence.append(item as Dictionary)
		return next_st
	return {}
