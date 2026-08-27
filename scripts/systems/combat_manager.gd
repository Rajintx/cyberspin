class_name CombatManager
extends Control

signal combat_won(enemy: EnemyData, credits: int)
signal combat_lost()

@onready var orbital_slot_machine: OrbitalSlotMachine = %OrbitalSlotMachine
var boss_core: BossCore

# Player HUD elements
@onready var player_hp_bar: ProgressBar = %PlayerHpBar
@onready var player_hp_label: Label = %PlayerHpLabel
@onready var player_shield_bar: ProgressBar = %PlayerShieldBar
@onready var player_shield_label: Label = %PlayerShieldLabel
@onready var ram_label: Label = %RamLabel
@onready var credits_label: Label = %CreditsLabel
@onready var floor_label: Label = %FloorLabel
@onready var relic_container: HBoxContainer = %RelicContainer
@onready var log_label: RichTextLabel = %CombatLog
@onready var pip_button: Button = %PipButton

var current_enemy: EnemyData
var is_resolving_turn: bool = false

func _ready() -> void:
	boss_core = orbital_slot_machine.boss_core
	orbital_slot_machine.spin_requested.connect(_on_spin_requested)
	orbital_slot_machine.spin_completed.connect(_on_spin_completed)
	boss_core.boss_died.connect(_on_boss_died)

	pip_button.pressed.connect(func():
		AudioSynth.play_click()
		WindowManager.toggle_pip_mode()
	)

	RunState.bankroll_changed.connect(_on_bankroll_changed)
	RunState.shield_changed.connect(_on_shield_changed)
	RunState.ram_changed.connect(_on_ram_changed)
	RunState.relics_updated.connect(_on_relics_updated)

	_update_all_hud()

func start_combat(enemy: EnemyData) -> void:
	current_enemy = enemy
	is_resolving_turn = false

	# Reset player shield for new combat
	RunState.set_shield(0)

	# Restore RAM if reload capacitor relic present
	if RunState.has_relic(RelicData.RelicType.RELOAD_CAPACITOR):
		RunState.restore_ram(RunState.max_ram)

	boss_core.init_enemy(enemy)
	orbital_slot_machine.clear_all_corruptions()
	orbital_slot_machine.populate_initial_grid(RunState.symbol_deck)
	orbital_slot_machine.set_controls_enabled(true)

	floor_label.text = "FLOOR %d // %s" % [RunState.current_floor, enemy.display_name.to_upper()]
	_log("[color=#00f0ff]=== ENGAGING ENEMY: %s ===[/color]" % enemy.display_name)
	_log("[color=#8888aa]\"%s\"[/color]" % enemy.flavor_quote)
	_update_all_hud()

func _update_all_hud() -> void:
	_on_bankroll_changed(RunState.credits, RunState.max_bankroll_seen)
	_on_shield_changed(RunState.player_shield)
	_on_ram_changed(RunState.player_ram, RunState.max_ram)
	_on_relics_updated(RunState.relics)

func _on_bankroll_changed(current: int, max_val: int) -> void:
	player_hp_bar.max_value = maxi(current, max_val)
	player_hp_bar.value = current
	player_hp_label.text = "💳 %d BANKROLL" % current
	credits_label.text = "💳 %d CREDITS" % current

func _on_shield_changed(current: int) -> void:
	player_shield_bar.max_value = maxi(current, 30)
	player_shield_bar.value = current
	player_shield_label.text = "🛡️ %d FIREWALL" % current
	player_shield_bar.visible = current > 0

func _on_ram_changed(current: int, max_val: int) -> void:
	ram_label.text = "💾 RAM: %d / %d" % [current, max_val]

func _on_relics_updated(relic_list: Array[RelicData]) -> void:
	for child in relic_container.get_children():
		child.queue_free()

	for r in relic_list:
		var lbl := Label.new()
		lbl.text = r.icon_glyph
		lbl.tooltip_text = "%s\n%s" % [r.display_name, r.description]
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		lbl.add_theme_font_size_override("font_size", 18)
		relic_container.add_child(lbl)

func _on_spin_requested() -> void:
	# Tick Virus damage on spin
	var virus_dmg := boss_core.tick_spin_virus_status()
	if virus_dmg > 0:
		_log("[color=#cc33ff]☣️ Data Virus triggered! Dealt %d Bleed DMG to Core.[/color]" % virus_dmg)

func _on_spin_completed(eval_result: Dictionary) -> void:
	if boss_core.current_hp <= 0 or RunState.credits <= 0:
		return

	is_resolving_turn = true

	# 1. Apply Player's Slot Machine Payload
	var dmg: int = eval_result.get("total_damage", 0)
	var shd: int = eval_result.get("total_shield", 0)
	var ram_gain: int = eval_result.get("total_ram", 0)
	var overheat: int = eval_result.get("overheat_stacks", 0)
	var virus: int = eval_result.get("virus_stacks", 0)
	var emp: int = eval_result.get("emp_stacks", 0)
	var glitch: int = eval_result.get("glitch_stacks", 0)
	var creds: int = eval_result.get("credits_earned", 0)

	for note in eval_result.get("synergy_notes", []):
		_log("[color=#ffff66]✨ %s[/color]" % note)

	if dmg > 0:
		boss_core.take_damage(dmg)
		if dmg > RunState.highest_single_spin_dmg:
			RunState.highest_single_spin_dmg = dmg
		_log("[color=#00ffcc]⚡ Terminal Fired! Dealt %d Cyber Damage to Core.[/color]" % dmg)

	if shd > 0:
		RunState.add_shield(shd)
		_log("[color=#3399ff]🛡️ Firewall Deployed: +%d Shield gained.[/color]" % shd)

	if ram_gain > 0:
		RunState.restore_ram(ram_gain)
		_log("[color=#33ff66]💾 RAM Restored: +%d RAM.[/color]" % ram_gain)

	if overheat > 0:
		boss_core.add_status("OVERHEAT", overheat)
		_log("[color=#ff6600]🔥 Applied %d Overheat (Burn) to Boss.[/color]" % overheat)

	if virus > 0:
		boss_core.add_status("VIRUS", virus)
		_log("[color=#cc33ff]☣️ Injected %d Data Virus stacks into Boss.[/color]" % virus)

	if emp > 0:
		boss_core.add_status("EMP", emp)
		_log("[color=#00ccff]🌀 EMP Pulse: Applied %d Stun stacks.[/color]" % emp)

	if glitch > 0:
		boss_core.add_status("GLITCH", glitch)
		_log("[color=#ff0088]👾 Glitch Injected! Boss is Vulnerable (+50%% DMG).[/color]" % glitch)

	if creds > 0:
		RunState.add_credits(creds)
		_log("[color=#ffcc00]💰 Payout Received: +%d Credits to Bankroll![/color]" % creds)

	# Check for boss defeat
	if boss_core.current_hp <= 0:
		is_resolving_turn = false
		return

	# 2. Boss Turn Execution after delay scaled by game speed
	var spd := RunState.game_speed
	var enemy_timer := get_tree().create_timer(0.7 / spd)
	enemy_timer.timeout.connect(_execute_boss_turn)

func _execute_boss_turn() -> void:
	if boss_core.current_hp <= 0:
		is_resolving_turn = false
		return

	# A. Boss Burn Tick
	var dot_dmg := boss_core.tick_turn_start_status()
	if dot_dmg > 0:
		_log("[color=#ff6600]🔥 Overheat Burn ticked! Dealt %d DMG to Core.[/color]" % dot_dmg)

	if boss_core.current_hp <= 0:
		is_resolving_turn = false
		return

	# B. Boss Action Intent
	var intent := boss_core.get_current_intent()
	var type_val: int = intent.get("type", EnemyData.IntentType.ATTACK)
	var val: int = intent.get("value", 8)
	var hits: int = intent.get("hits", 1)
	var intent_name: String = intent.get("name", "Action")

	match type_val:
		EnemyData.IntentType.ATTACK, EnemyData.IntentType.HEAVY_ATTACK:
			_log("[color=#ff3366]⚔️ Boss uses %s! Deals %d Cyber Damage.[/color]" % [intent_name, val])
			_apply_damage_to_player(val)
		EnemyData.IntentType.MULTI_ATTACK:
			var total_hit_dmg := val * hits
			_log("[color=#ff3366]⚔️ Boss fires %s (%d hits x %d = %d DMG)![/color]" % [intent_name, hits, val, total_hit_dmg])
			_apply_damage_to_player(total_hit_dmg)
		EnemyData.IntentType.SHIELD_UP:
			boss_core.add_shield(val)
			_log("[color=#0099ff]🛡️ Boss fortifies Firewall (+%d Shield).[/color]" % val)
		EnemyData.IntentType.CORRUPT_REEL:
			_log("[color=#ff9900]⚡ Boss fires EMP Shock! Corrupted %d orbital reels.[/color]" % val)
			_corrupt_random_reels(val)

	boss_core.advance_intent()
	is_resolving_turn = false

	# Re-enable player controls for next spin if player still alive
	if RunState.credits > 0 and boss_core.current_hp > 0:
		orbital_slot_machine.set_controls_enabled(true)

func _apply_damage_to_player(amount: int) -> void:
	var remaining_dmg := RunState.take_damage_direct(amount)
	if remaining_dmg > 0:
		AudioSynth.play_tone(150, 40, 0.3, -2.0, "noise")
		_log("[color=#ff0044]💥 Direct Hit! Lost %d Credits from Bankroll![/color]" % remaining_dmg)
	else:
		_log("[color=#00ccff]🛡️ Firewall absorbed all incoming damage![/color]")
		# Plasma converter check
		if RunState.has_relic(RelicData.RelicType.PLASMA_CONVERTER) and RunState.player_shield > 0:
			var reflected := int(round(RunState.player_shield * 0.4))
			if reflected > 0:
				boss_core.take_damage(reflected)
				_log("[color=#00ff88]⚡ Kinetic Reflector! Absorbed shield dealt %d laser counter-damage to Boss![/color]" % reflected)

	if RunState.credits <= 0:
		_log("[color=#ff0000]☠️ BANKRUPTCY: TERMINAL BANKROLL DEPLETED.[/color]")
		orbital_slot_machine.set_controls_enabled(false)
		combat_lost.emit()

func _corrupt_random_reels(count: int) -> void:
	var indices: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
	indices.shuffle()
	for i in range(mini(count, 8)):
		orbital_slot_machine.set_slot_corrupted(indices[i], true)

func _on_boss_died(enemy: EnemyData) -> void:
	_log("[color=#00ff88]🏆 ENEMY CORE DESTROYED! VICTORY ACHIEVED.[/color]")
	RunState.total_enemies_purged += 1
	var earned_credits := enemy.credits_reward
	if RunState.has_relic(RelicData.RelicType.GOLDEN_CIRCUIT):
		earned_credits = int(round(earned_credits * 1.5))

	RunState.add_credits(earned_credits)
	AudioSynth.play_jackpot()
	orbital_slot_machine.set_controls_enabled(false)

	var spd := RunState.game_speed
	var win_timer := get_tree().create_timer(1.2 / spd)
	win_timer.timeout.connect(func():
		combat_won.emit(enemy, earned_credits)
	)

func _log(bbcode: String) -> void:
	log_label.append_text(bbcode + "\n")
