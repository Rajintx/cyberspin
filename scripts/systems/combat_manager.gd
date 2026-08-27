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
	orbital_slot_machine.spin_failed_bankrupt.connect(func():
		_check_player_bankrupt()
	)
	boss_core.boss_died.connect(_on_boss_died)
	boss_core.stage_transitioned.connect(_on_stage_transitioned)

	pip_button.pressed.connect(func():
		AudioSynth.play_click()
		WindowManager.toggle_pip_mode()
	)

	RunState.bankroll_changed.connect(_on_bankroll_changed)
	RunState.shield_changed.connect(_on_shield_changed)
	RunState.ram_changed.connect(_on_ram_changed)
	RunState.spin_cost_changed.connect(_on_spin_cost_changed)
	RunState.relics_updated.connect(_on_relics_updated)

	_update_all_hud()

func start_combat(enemy: EnemyData) -> void:
	current_enemy = enemy
	is_resolving_turn = false

	# Reset player shield and battle turns for new combat
	RunState.set_shield(0)
	RunState.reset_battle_turns()

	# Restore RAM if reload capacitor relic present
	if RunState.has_relic(RelicData.RelicType.RELOAD_CAPACITOR):
		RunState.restore_ram(RunState.max_ram)

	reset_combat_visuals()
	boss_core.init_enemy(enemy)
	orbital_slot_machine.clear_all_hazards()
	orbital_slot_machine.clear_all_corruptions()
	orbital_slot_machine.populate_initial_grid(RunState.symbol_deck)

	floor_label.text = "FLOOR %d/10 // %s" % [RunState.current_floor, enemy.display_name.to_upper()]
	_log("[color=#00f0ff]=== ENGAGING ENEMY: %s ===[/color]" % enemy.display_name)
	_log("[color=#8888aa]\"%s\"[/color]" % enemy.flavor_quote)
	_update_all_hud()

	if _check_player_bankrupt():
		return
	orbital_slot_machine.set_controls_enabled(true)

func _update_all_hud() -> void:
	_on_bankroll_changed(RunState.credits, RunState.max_bankroll_seen)
	_on_shield_changed(RunState.player_shield)
	_on_ram_changed(RunState.player_ram, RunState.max_ram)
	_on_spin_cost_changed(RunState.get_current_spin_cost(), RunState.battle_turn_number)
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

func _on_spin_cost_changed(cost: int, turn_num: int) -> void:
	orbital_slot_machine.spin_button.text = "⚡ PULL LEVER (Cost: %d💳 | Turn %d) [SPACE] ⚡" % [cost, turn_num]

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

func _on_stage_transitioned(enemy: EnemyData, stage_idx: int) -> void:
	_log("[color=#ff0055]⚡ PHASE TRANSITION: %s ENTERED STAGE %d! [/color]" % [enemy.display_name, stage_idx + 1])
	orbital_slot_machine.show_banner("⚡ PHASE %d: %s" % [stage_idx + 1, enemy.display_name])
	floor_label.text = "FLOOR %d/10 // %s" % [RunState.current_floor, enemy.display_name.to_upper()]
	trigger_screen_shake(6.0)

func _on_spin_requested() -> void:
	# Tick Virus damage on spin
	var virus_dmg := boss_core.tick_spin_virus_status()
	if virus_dmg > 0:
		spawn_floating_text("☣️ -%d" % virus_dmg, Color(0.8, 0.2, 1.0), boss_core.global_position + Vector2(40, 20))
		_log("[color=#cc33ff]☣️ Data Virus triggered! Dealt %d Bleed DMG to Core.[/color]" % virus_dmg)

func _on_spin_completed(eval_result: Dictionary) -> void:
	if not is_instance_valid(boss_core) or boss_core.current_hp <= 0 or RunState.credits <= 0:
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
		spawn_floating_text("-%d DMG" % dmg, Color(0.0, 1.0, 0.8), boss_core.global_position + Vector2(40, 20))
		trigger_screen_shake(4.0)
		if dmg > RunState.highest_single_spin_dmg:
			RunState.highest_single_spin_dmg = dmg
		_log("[color=#00ffcc]⚡ Terminal Fired! Dealt %d Cyber Damage to Core.[/color]" % dmg)

	if shd > 0:
		RunState.add_shield(shd)
		spawn_floating_text("+%d 🛡️" % shd, Color(0.2, 0.8, 1.0), player_hp_bar.global_position + Vector2(20, -10))
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
		_log("[color=#ff0088]👾 Glitch Injected (%d Stacks)! Boss is Vulnerable (+50%% DMG).[/color]" % glitch)

	if creds > 0:
		RunState.add_credits(creds)
		spawn_floating_text("+%d 💳" % creds, Color(1.0, 0.85, 0.2), credits_label.global_position + Vector2(20, 20))
		_log("[color=#ffcc00]💰 Payout Received: +%d Credits to Bankroll![/color]" % creds)

	# 2. Check and Trigger Active Tile Hazards (Spikes & Poison)
	_resolve_tile_hazards()

	# Check for player defeat or boss defeat
	if _check_player_bankrupt():
		is_resolving_turn = false
		return
	if not is_instance_valid(boss_core) or boss_core.current_hp <= 0:
		is_resolving_turn = false
		return

	# 3. Boss Turn Execution after delay scaled by game speed
	var spd := RunState.game_speed
	var enemy_timer := get_tree().create_timer(0.7 / spd)
	enemy_timer.timeout.connect(_execute_boss_turn)

func _resolve_tile_hazards() -> void:
	var total_spike_dmg: int = 0
	var total_poison_drain: int = 0

	for i in range(8):
		if i >= orbital_slot_machine.slot_tiles.size():
			continue
		var tile: SlotTile = orbital_slot_machine.slot_tiles[i]
		if not is_instance_valid(tile):
			continue
		if tile.hazard_type == SlotTile.HazardType.SPIKE:
			total_spike_dmg += 10 + RunState.current_floor
			tile.play_hazard_trigger_fx()
			tile.clear_hazard() # Spike pops after trigger
		elif tile.hazard_type == SlotTile.HazardType.POISON:
			total_poison_drain += 5 + int(floor(float(RunState.current_floor) / 2.0))
			tile.play_hazard_trigger_fx()

	if total_spike_dmg > 0:
		_log("[color=#ff0044]📌 Data Spike triggered! Inflicted %d damage to Bankroll![/color]" % total_spike_dmg)
		_apply_damage_to_player(total_spike_dmg)

	if total_poison_drain > 0:
		_log("[color=#aa00ff]☣️ Malware Leech drained %d Credits from Bankroll![/color]" % total_poison_drain)
		_apply_damage_to_player(total_poison_drain)

func _execute_boss_turn() -> void:
	if not is_instance_valid(boss_core) or boss_core.current_hp <= 0:
		is_resolving_turn = false
		return

	# A. Boss Burn Tick
	var dot_dmg := boss_core.tick_turn_start_status()
	if dot_dmg > 0:
		spawn_floating_text("🔥 -%d" % dot_dmg, Color(1.0, 0.4, 0.0), boss_core.global_position + Vector2(40, 20))
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

	if boss_core.is_enraged:
		val = int(round(float(val) * 1.4))

	match type_val:
		EnemyData.IntentType.PLANT_SPIKES:
			_log("[color=#ff2255]📌 Boss deploys %s! Armed %d orbital slots with Data Spikes.[/color]" % [intent_name, val])
			_plant_hazard_on_random_tiles(SlotTile.HazardType.SPIKE, val)
		EnemyData.IntentType.INJECT_POISON:
			_log("[color=#aa22ff]☣️ Boss injects %s! Infected %d orbital slots with Malware Poison.[/color]" % [intent_name, val])
			_plant_hazard_on_random_tiles(SlotTile.HazardType.POISON, val)
		EnemyData.IntentType.DETONATE_HAZARDS:
			_log("[color=#ff6600]💥 Boss executes %s! Detonates board hazards + %d DMG.[/color]" % [intent_name, val])
			_apply_damage_to_player(val)
			_resolve_tile_hazards()
		EnemyData.IntentType.ATTACK, EnemyData.IntentType.HEAVY_ATTACK:
			_log("[color=#ff3366]⚔️ Boss uses %s! Deals %d Cyber Damage.[/color]" % [intent_name, val])
			_apply_damage_to_player(val)
		EnemyData.IntentType.MULTI_ATTACK:
			var total_hit_dmg := val * hits
			_log("[color=#ff3366]⚔️ Boss fires %s (%d hits x %d = %d DMG)![/color]" % [intent_name, hits, val, total_hit_dmg])
			_apply_damage_to_player(total_hit_dmg)
		EnemyData.IntentType.SHIELD_UP:
			boss_core.add_shield(val)
			spawn_floating_text("+%d 🛡️" % val, Color(0.0, 0.8, 1.0), boss_core.global_position + Vector2(40, -10))
			_log("[color=#0099ff]🛡️ Boss fortifies Firewall (+%d Shield).[/color]" % val)
		EnemyData.IntentType.CORRUPT_REEL:
			_log("[color=#ff9900]⚡ Boss fires EMP Shock! Corrupted %d orbital reels.[/color]" % val)
			_corrupt_random_reels(val)

	boss_core.advance_intent()

	# C. 50% Active Shield Decay at Turn End
	if RunState.player_shield > 0:
		var decayed_shield := int(floor(float(RunState.player_shield) * 0.5))
		var lost := RunState.player_shield - decayed_shield
		RunState.set_shield(decayed_shield)
		if lost > 0:
			_log("[color=#4477aa]🛡️ Firewall Dissipated: -%d Shield (50%% Turn Decay).[/color]" % lost)

	# D. Advance Battle Turn
	RunState.start_new_battle_turn()
	is_resolving_turn = false

	# Re-enable player controls if player is alive and can afford next spin
	if _check_player_bankrupt():
		return

	if is_instance_valid(boss_core) and boss_core.current_hp > 0:
		orbital_slot_machine.set_controls_enabled(true)

func _check_player_bankrupt() -> bool:
	var ante_cost := RunState.get_current_spin_cost()
	if RunState.credits <= 0 or RunState.credits < ante_cost:
		_log("[color=#ff0000]☠️ BANKRUPTCY: TERMINAL BANKROLL (%d 💳) INSUFFICIENT FOR SPIN ANTE (%d 💳).[/color]" % [RunState.credits, ante_cost])
		orbital_slot_machine.set_controls_enabled(false)
		combat_lost.emit()
		return true
	return false

func _plant_hazard_on_random_tiles(hazard: SlotTile.HazardType, count: int) -> void:
	var available_indices: Array[int] = []
	for i in range(8):
		if orbital_slot_machine.slot_tiles[i].hazard_type == SlotTile.HazardType.NONE:
			available_indices.append(i)

	available_indices.shuffle()
	for i in range(mini(count, available_indices.size())):
		var idx: int = available_indices[i]
		orbital_slot_machine.set_slot_hazard(idx, hazard)

	AudioSynth.play_emp()

func _apply_damage_to_player(amount: int) -> void:
	var remaining_dmg := RunState.take_damage_direct(amount)
	trigger_screen_shake(3.0)
	if remaining_dmg > 0:
		AudioSynth.play_tone(150, 40, 0.3, -2.0, "noise")
		spawn_floating_text("-%d 💳" % remaining_dmg, Color(1.0, 0.1, 0.2), player_hp_bar.global_position + Vector2(20, -10))
		_log("[color=#ff0044]💥 Direct Hit! Lost %d Credits from Bankroll![/color]" % remaining_dmg)
	else:
		spawn_floating_text("🛡️ BLOCKED", Color(0.3, 0.9, 1.0), player_hp_bar.global_position + Vector2(20, -10))
		_log("[color=#00ccff]🛡️ Firewall absorbed all incoming damage![/color]")
		if RunState.has_relic(RelicData.RelicType.PLASMA_CONVERTER) and RunState.player_shield > 0:
			var reflected := int(round(RunState.player_shield * 0.3))
			if reflected > 0:
				boss_core.take_damage(reflected)
				spawn_floating_text("⚡ -%d REFLECT" % reflected, Color(0.0, 1.0, 0.5), boss_core.global_position + Vector2(40, 20))
				_log("[color=#00ff88]⚡ Kinetic Reflector! Absorbed shield dealt %d laser counter-damage to Boss![/color]" % reflected)

	_check_player_bankrupt()

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

func spawn_floating_text(text: String, color: Color, spawn_pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.modulate = color
	lbl.global_position = spawn_pos
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_to_group("floating_text")
	add_child(lbl)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 30.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tween.chain().tween_callback(lbl.queue_free)

func trigger_screen_shake(intensity: float = 4.0) -> void:
	var original_pos: Vector2 = orbital_slot_machine.position
	var tween := create_tween()
	for i in range(4):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(orbital_slot_machine, "position", original_pos + offset, 0.03)
	tween.tween_property(orbital_slot_machine, "position", original_pos, 0.03)

func reset_combat_visuals() -> void:
	log_label.text = ""
	for node in get_tree().get_nodes_in_group("floating_text"):
		node.queue_free()
	player_shield_bar.visible = false
	boss_core.reset_boss_visuals()

func _log(bbcode: String) -> void:
	log_label.append_text(bbcode + "\n")
