class_name CharacterSelect
extends Control

signal specialist_chosen(specialist_type: RunState.SpecialistClass)

@onready var sniper_card: PanelContainer = %SniperCard
@onready var tank_card: PanelContainer = %TankCard
@onready var hacker_card: PanelContainer = %HackerCard
@onready var gambler_card: PanelContainer = %GamblerCard

@onready var sniper_btn: Button = %SniperBtn
@onready var tank_btn: Button = %TankBtn
@onready var hacker_btn: Button = %HackerBtn
@onready var gambler_btn: Button = %GamblerBtn

func _ready() -> void:
	sniper_btn.pressed.connect(func(): _choose_class(RunState.SpecialistClass.SNIPER))
	tank_btn.pressed.connect(func(): _choose_class(RunState.SpecialistClass.TANK))
	hacker_btn.pressed.connect(func(): _choose_class(RunState.SpecialistClass.HACKER))
	gambler_btn.pressed.connect(func(): _choose_class(RunState.SpecialistClass.GAMBLER))

func _choose_class(cls: RunState.SpecialistClass) -> void:
	AudioSynth.play_jackpot()
	specialist_chosen.emit(cls)

func reset_view() -> void:
	visible = true
