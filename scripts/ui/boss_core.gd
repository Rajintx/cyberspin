class_name BossCore
extends PanelContainer

signal boss_died(enemy: EnemyData)
signal stage_transitioned(enemy: EnemyData, stage_index: int)

var enemy_data: EnemyData
var current_hp: int = 50
var max_hp: int = 50
var current_shield: int = 0
var is_enraged: bool = false

# Status effect counters
var overheat_stacks: int = 0
var virus_stacks: int = 0
var emp_stacks: int = 0
var glitch_stacks: int = 0

var current_intent_index: int = 0

@onready var avatar_label: Label = %AvatarLabel
@onready var name_label: Label = %NameLabel
@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var shield_bar: ProgressBar = %ShieldBar
@onready var shield_label: Label = %ShieldLabel
@onready var intent_badge: PanelContainer = %IntentBadge
@onready var intent_icon: Label = %IntentIcon
@onready var intent_desc: Label = %IntentDesc
@onready var status_box: HBoxContainer = %StatusBox
@onready var burn_tag: Label = %BurnTag
@onready var virus_tag: Label = %VirusTag
@onready var emp_tag: Label = %EmpTag
@onready var glitch_tag: Label = %GlitchTag
@onready var hit_flash: ColorRect = %HitFlash

var _base_style: StyleBoxFlat

func _ready() -> void:
	_base_style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	add_theme_stylebox_override("panel", _base_style)
	hit_flash.modulate.a = 0.0
	_start_breathing_animation()

func init_enemy(data: EnemyData) -> void:
	enemy_data = data
	enemy_data.current_stage_index = 0
	max_hp = data.max_hp
	current_hp = max_hp
	current_shield = data.starting_shield
	current_intent_index = 0
	is_enraged = false

	overheat_stacks = 0
	virus_stacks = 0
	emp_stacks = 0
	glitch_stacks = 0

	avatar_label.text = data.avatar_glyph
	name_label.text = data.display_name
	name_label.modulate = data.theme_color

	if _base_style:
		_base_style.border_color = data.theme_color
		_base_style.shadow_color = Color(data.theme_color.r, data.theme_color.g, data.theme_color.b, 0.4)

	update_ui()
	update_intent_display()

func update_ui() -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_label.text = "%d / %d HP" % [current_hp, max_hp]

	shield_bar.max_value = maxi(current_shield, 20)
	shield_bar.value = current_shield
	shield_label.text = "%d SHIELD" % current_shield
	shield_bar.visible = current_shield > 0

	# Status tags
	burn_tag.visible = overheat_stacks > 0
	burn_tag.text = "🔥%d" % overheat_stacks

	virus_tag.visible = virus_stacks > 0
	virus_tag.text = "☣️%d" % virus_stacks

	emp_tag.visible = emp_stacks > 0
	emp_tag.text = "⚡%d" % emp_stacks

	glitch_tag.visible = glitch_stacks > 0
	glitch_tag.text = "👾%d" % glitch_stacks

func get_current_intent() -> Dictionary:
	if not enemy_data or enemy_data.intent_sequence.is_empty():
		return {"type": EnemyData.IntentType.ATTACK, "value": 8, "name": "Basic Attack", "desc": "Deals 8 DMG"}
	var intent := enemy_data.intent_sequence[current_intent_index % enemy_data.intent_sequence.size()]
	return intent

func advance_intent() -> void:
	current_intent_index += 1
	update_intent_display()

func update_intent_display() -> void:
	var intent := get_current_intent()
	var type_val: int = intent.get("type", EnemyData.IntentType.ATTACK)
	var val: int = intent.get("value", 0)

	if is_enraged:
		val = int(round(float(val) * 1.4))

	match type_val:
		EnemyData.IntentType.ATTACK:
			intent_icon.text = "⚔️"
			intent_desc.text = "%d DMG" % val
			intent_badge.modulate = Color(1.0, 0.4, 0.4)
		EnemyData.IntentType.MULTI_ATTACK:
			var hits: int = intent.get("hits", 2)
			intent_icon.text = "⚔️"
			intent_desc.text = "%dx%d" % [hits, val]
			intent_badge.modulate = Color(1.0, 0.3, 0.5)
		EnemyData.IntentType.HEAVY_ATTACK:
			intent_icon.text = "💥"
			intent_desc.text = "%d DMG!" % val
			intent_badge.modulate = Color(1.0, 0.1, 0.2)
		EnemyData.IntentType.SHIELD_UP:
			intent_icon.text = "🛡️"
			intent_desc.text = "+%d SHD" % val
			intent_badge.modulate = Color(0.2, 0.8, 1.0)
		EnemyData.IntentType.CORRUPT_REEL:
			intent_icon.text = "⚡"
			intent_desc.text = "EMP LOCK %d" % val
			intent_badge.modulate = Color(1.0, 0.8, 0.1)
		EnemyData.IntentType.PLANT_SPIKES:
			intent_icon.text = "📌"
			intent_desc.text = "SPIKES %d" % val
			intent_badge.modulate = Color(1.0, 0.2, 0.35)
		EnemyData.IntentType.INJECT_POISON:
			intent_icon.text = "☣️"
			intent_desc.text = "POISON %d" % val
			intent_badge.modulate = Color(0.8, 0.2, 1.0)
		EnemyData.IntentType.DETONATE_HAZARDS:
			intent_icon.text = "💥"
			intent_desc.text = "DETONATE %d" % val
			intent_badge.modulate = Color(1.0, 0.5, 0.0)
		_:
			intent_icon.text = "⚠️"
			intent_desc.text = intent.get("name", "Action")
			intent_badge.modulate = Color(0.8, 0.5, 1.0)

	intent_badge.tooltip_text = "%s\n%s" % [intent.get("name", ""), intent.get("desc", "")]

func take_damage(amount: int, is_piercing: bool = false) -> int:
	if amount <= 0:
		return 0

	var dmg_to_deal: int = amount
	var actual_hp_damage: int = 0

	if not is_piercing and current_shield > 0:
		if dmg_to_deal <= current_shield:
			current_shield -= dmg_to_deal
			dmg_to_deal = 0
		else:
			dmg_to_deal -= current_shield
			current_shield = 0

	if dmg_to_deal > 0:
		actual_hp_damage = dmg_to_deal
		current_hp = maxi(0, current_hp - dmg_to_deal)

	# Check Enrage below 50% HP
	if not is_enraged and current_hp <= int(max_hp * 0.5) and current_hp > 0:
		_trigger_enrage()

	_play_hit_reaction()
	update_ui()

	if current_hp <= 0:
		if enemy_data and enemy_data.has_next_stage():
			_transition_to_next_stage()
		else:
			boss_died.emit(enemy_data)

	return actual_hp_damage

func _transition_to_next_stage() -> void:
	var _next_st := enemy_data.advance_to_next_stage()
	max_hp = enemy_data.max_hp
	current_hp = max_hp
	current_shield = enemy_data.starting_shield
	current_intent_index = 0
	is_enraged = false

	# Dramatic phase transition visuals & audio
	AudioSynth.play_emp()
	avatar_label.text = enemy_data.avatar_glyph
	name_label.text = "⚡ " + enemy_data.display_name
	name_label.modulate = Color(1.0, 0.2, 0.5)

	var tween := create_tween().set_parallel(true)
	hit_flash.modulate.a = 0.9
	tween.tween_property(hit_flash, "modulate:a", 0.0, 0.5)
	avatar_label.scale = Vector2(1.5, 1.5)
	tween.tween_property(avatar_label, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	update_ui()
	update_intent_display()
	stage_transitioned.emit(enemy_data, enemy_data.current_stage_index)

func _trigger_enrage() -> void:
	is_enraged = true
	AudioSynth.play_emp()
	name_label.text = "🔥 " + enemy_data.display_name + " [ENRAGED]"
	name_label.modulate = Color(1.0, 0.1, 0.25)
	if _base_style:
		_base_style.border_color = Color(1.0, 0.1, 0.25)
		_base_style.shadow_color = Color(1.0, 0.0, 0.2, 0.6)
	update_intent_display()

func add_shield(amount: int) -> void:
	current_shield += amount
	AudioSynth.play_shield()
	update_ui()

func add_status(type: String, stacks: int) -> void:
	match type:
		"OVERHEAT":
			overheat_stacks += stacks
		"VIRUS":
			virus_stacks += stacks
		"EMP":
			emp_stacks += stacks
		"GLITCH":
			glitch_stacks += stacks
	update_ui()

func tick_turn_start_status() -> int:
	var total_dot: int = 0
	if overheat_stacks > 0:
		var burn_dmg: int = overheat_stacks
		take_damage(burn_dmg, true)
		total_dot += burn_dmg
		overheat_stacks = maxi(0, overheat_stacks - 1)

	if glitch_stacks > 0:
		glitch_stacks = maxi(0, glitch_stacks - 1)

	if emp_stacks > 0:
		emp_stacks = maxi(0, emp_stacks - 1)

	update_ui()
	return total_dot

func tick_spin_virus_status() -> int:
	if virus_stacks > 0:
		var virus_dmg: int = virus_stacks
		take_damage(virus_dmg, true)
		AudioSynth.play_virus()
		return virus_dmg
	return 0

func _play_hit_reaction() -> void:
	AudioSynth.play_boss_hit()
	var tween := create_tween()
	hit_flash.modulate.a = 0.7
	tween.tween_property(hit_flash, "modulate:a", 0.0, 0.25)

	# Dynamic squash & stretch + knockback shake
	var orig_pos := Vector2.ZERO
	var shake_offset := Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0))

	var anim_tween := create_tween()
	anim_tween.tween_property(avatar_label, "scale", Vector2(1.25, 0.8), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	anim_tween.parallel().tween_property(avatar_label, "position", orig_pos + shake_offset, 0.05)

	anim_tween.tween_property(avatar_label, "scale", Vector2(0.9, 1.15), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	anim_tween.parallel().tween_property(avatar_label, "position", orig_pos, 0.08)

	anim_tween.tween_property(avatar_label, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func reset_boss_visuals() -> void:
	is_enraged = false
	overheat_stacks = 0
	virus_stacks = 0
	emp_stacks = 0
	glitch_stacks = 0
	avatar_label.scale = Vector2.ONE
	avatar_label.position = Vector2.ZERO
	hit_flash.modulate.a = 0.0

	if enemy_data:
		name_label.text = enemy_data.display_name
		name_label.modulate = enemy_data.theme_color
		if _base_style:
			_base_style.border_color = enemy_data.theme_color
			_base_style.shadow_color = Color(enemy_data.theme_color.r, enemy_data.theme_color.g, enemy_data.theme_color.b, 0.4)

	update_ui()
	update_intent_display()

func _start_breathing_animation() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(avatar_label, "position:y", -3.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(avatar_label, "position:y", 3.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
