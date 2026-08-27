class_name MainGame
extends Control

@onready var character_select: Control = %CharacterSelect
@onready var map_screen: MapScreen = %MapScreen
@onready var combat_arena: CombatManager = %CombatArena
@onready var reward_screen: RewardScreen = %RewardScreen
@onready var shop_screen: ShopScreen = %ShopScreen
@onready var end_screen: Control = %EndScreen
@onready var end_title: Label = %EndTitle
@onready var end_desc: Label = %EndDesc
@onready var stats_summary: Label = %StatsSummary
@onready var restart_button: Button = %RestartButton
@onready var pip_overlay: PiPOverlay = %PiPOverlay

func _ready() -> void:
	character_select.specialist_chosen.connect(_on_specialist_chosen)
	map_screen.node_selected.connect(_on_map_node_selected)
	combat_arena.combat_won.connect(_on_combat_won)
	combat_arena.combat_lost.connect(_on_combat_lost)
	reward_screen.reward_completed.connect(_on_reward_completed)
	shop_screen.shop_closed.connect(_on_shop_closed)
	restart_button.pressed.connect(_on_restart_pressed)

	WindowManager.window_mode_changed.connect(_on_window_mode_changed)

	_show_screen(character_select)

func _on_window_mode_changed(is_pip: bool) -> void:
	pip_overlay.visible = is_pip

func _show_screen(active_control: Control) -> void:
	character_select.visible = (active_control == character_select)
	map_screen.visible = (active_control == map_screen)
	combat_arena.visible = (active_control == combat_arena)
	reward_screen.visible = (active_control == reward_screen)
	shop_screen.visible = (active_control == shop_screen)
	end_screen.visible = (active_control == end_screen)

func _on_specialist_chosen(specialist: RunState.SpecialistClass) -> void:
	RunState.init_new_run(specialist)
	_show_screen(map_screen)
	map_screen.refresh_map()

func _on_map_node_selected(node_type: String, floor_num: int) -> void:
	RunState.current_node_type = node_type
	if node_type == "SHOP":
		_show_screen(shop_screen)
		shop_screen.open_shop()
	else:
		var enemy: EnemyData = RunState.get_enemy_for_node(node_type, floor_num)
		_show_screen(combat_arena)
		combat_arena.start_combat(enemy)

func _on_combat_won(enemy: EnemyData, credits_earned: int) -> void:
	if enemy.is_boss and RunState.current_floor >= 10:
		# Final Omega Boss Victory!
		_show_game_end(true)
	else:
		_show_screen(reward_screen)
		reward_screen.show_rewards(credits_earned)

func _on_combat_lost() -> void:
	_show_game_end(false)

func _on_reward_completed() -> void:
	_advance_floor()

func _on_shop_closed() -> void:
	_advance_floor()

func _advance_floor() -> void:
	RunState.current_floor += 1
	if RunState.current_floor > 10:
		_show_game_end(true)
	else:
		_show_screen(map_screen)
		map_screen.refresh_map()

func _show_game_end(is_victory: bool) -> void:
	_show_screen(end_screen)
	stats_summary.text = "Spins: %d  |  Jackpots: %d  |  Peak Turn DMG: %d  |  Purged Enemies: %d" % [
		RunState.total_spins,
		RunState.total_jackpots,
		RunState.highest_single_spin_dmg,
		RunState.total_enemies_purged
	]

	if is_victory:
		end_title.text = "🏆 MEGACORP OMEGA NEXUS PURGED! 🏆"
		end_title.modulate = Color(0.0, 1.0, 0.5)
		end_desc.text = "You successfully breached all 10 corporate security layers and brought down the God AI!\nFinal Bankroll: %d Credits" % RunState.credits
		AudioSynth.play_jackpot()
	else:
		end_title.text = "☠️ BANKRUPT / TERMINAL SHUTDOWN ☠️"
		end_title.modulate = Color(1.0, 0.1, 0.3)
		end_desc.text = "Your bankroll was drained on Floor %d. The cyber security matrix seized your terminal." % RunState.current_floor
		AudioSynth.play_tone(200, 50, 0.6, -2.0, "saw")

func _on_restart_pressed() -> void:
	AudioSynth.play_click()
	_show_screen(character_select)
