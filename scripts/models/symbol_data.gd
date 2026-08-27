class_name SymbolData
extends Resource

enum SymbolType {
	ATTACK,      # Deals direct damage to Boss Core (Chips x Mult)
	SHIELD,      # Adds Firewall shield to absorb incoming attacks
	RAM,         # Restores RAM used for locking/rerolling/overdrive
	MULTIPLIER,  # Direct line / cluster multiplier
	VIRUS,       # Data Virus (bleed every spin + infectious spreading)
	OVERHEAT,    # Overheat (burn ticks every enemy turn)
	EMP,         # EMP (disrupts boss intents + amplifies pierce)
	GLITCH,      # Glitch (inflicts vulnerability +50% incoming damage)
	JACKPOT,     # 777 Cyber Chip (massive payout & fever triggers)
	BATTERY,     # Overcharges adjacent perimeter symbols
	MIRROR,      # Quantum Mirror (duplicates the opposite slot's symbol)
	MINER,       # Crypto Miner (generates bonus Credits dividend every spin)
	MIMIC        # 😈 Trojan Mimic (Disguised chip that reveals on landing to bite or reward!)
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	LEGENDARY
}

@export var id: String = "laser_1"
@export var display_name: String = "Plasma Laser"
@export var symbol_type: SymbolType = SymbolType.ATTACK
@export var rarity: Rarity = Rarity.COMMON
@export var base_chips: int = 4       # Base value / chips
@export var mult_add: float = 0.3     # +Mult addition
@export var mult_factor: float = 1.0  # xMult multiplier
@export var icon_glyph: String = "⚡"
@export var icon_color: Color = Color(0.0, 0.95, 1.0)
@export var glow_color: Color = Color(0.0, 0.7, 1.0, 0.4)
@export_multiline var description: String = "Fires a concentrated beam dealing Cyber Damage."
@export var synergy_tag: String = "energy"

# Legacy compatibility property
var base_value: int:
	get:
		return base_chips
	set(val):
		base_chips = val

func get_type_name() -> String:
	match symbol_type:
		SymbolType.ATTACK: return "ATTACK CHIP"
		SymbolType.SHIELD: return "FIREWALL CHIP"
		SymbolType.RAM: return "RAM CAPACITOR"
		SymbolType.MULTIPLIER: return "MULT AMPLIFIER"
		SymbolType.VIRUS: return "VIRUS INJECTOR"
		SymbolType.OVERHEAT: return "THERMAL IGNITER"
		SymbolType.EMP: return "EMP DISRUPTOR"
		SymbolType.GLITCH: return "GLITCH EXPLOIT"
		SymbolType.JACKPOT: return "JACKPOT 777"
		SymbolType.BATTERY: return "REACTOR CELL"
		SymbolType.MIRROR: return "QUANTUM MIRROR"
		SymbolType.MINER: return "CRYPTO MINER"
		SymbolType.MIMIC: return "TROJAN MIMIC"
	return "UNKNOWN"
