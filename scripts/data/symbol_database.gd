class_name SymbolDatabase
extends RefCounted

## Declarative Dictionary catalog of all Cyber-Symbols / Slot Tiles.

const SYMBOLS: Dictionary = {
	"laser": {
		"id": "laser",
		"name": "Plasma Laser",
		"type": SymbolData.SymbolType.ATTACK,
		"chips": 8,
		"mult": 0.5,
		"rarity": SymbolData.Rarity.COMMON,
		"glyph": "⚡",
		"color": Color(0.0, 0.95, 1.0),
		"glow": Color(0.0, 0.7, 1.0, 0.4),
		"desc": "High-energy cyber laser (8 Chips, +0.5 Mult). Enters 1-Round Cooldown after firing."
	},
	"railgun": {
		"id": "railgun",
		"name": "Hyper Railgun",
		"type": SymbolData.SymbolType.ATTACK,
		"chips": 9,
		"mult": 0.6,
		"rarity": SymbolData.Rarity.UNCOMMON,
		"glyph": "💥",
		"color": Color(1.0, 0.3, 0.1),
		"glow": Color(1.0, 0.4, 0.0, 0.5),
		"desc": "Heavy artillery dealing 9 Base Chips (+0.6 Mult) Piercing Damage."
	},
	"arc_blade": {
		"id": "arc_blade",
		"name": "Arc Monoblade",
		"type": SymbolData.SymbolType.ATTACK,
		"chips": 5,
		"mult": 0.8,
		"rarity": SymbolData.Rarity.UNCOMMON,
		"glyph": "🗡️",
		"color": Color(0.9, 0.2, 0.9),
		"glow": Color(0.8, 0.1, 0.8, 0.5),
		"desc": "Delivers 5 Chips (+0.8 Mult) and applies +2 Bleed to Boss, but triggers 4 Delayed Self-Bleed after 2 rounds."
	},
	"firewall": {
		"id": "firewall",
		"name": "Nano Firewall",
		"type": SymbolData.SymbolType.SHIELD,
		"chips": 6,
		"mult": 0.0,
		"rarity": SymbolData.Rarity.COMMON,
		"glyph": "🛡️",
		"color": Color(0.1, 0.7, 1.0),
		"glow": Color(0.1, 0.5, 0.9, 0.4),
		"desc": "Deploys +6 Firewall Shield to protect Bankroll. Shield decays every 2 rounds."
	},
	"fortress": {
		"id": "fortress",
		"name": "Aegis Matrix",
		"type": SymbolData.SymbolType.SHIELD,
		"chips": 11,
		"mult": 0.0,
		"rarity": SymbolData.Rarity.UNCOMMON,
		"glyph": "💠",
		"color": Color(0.3, 0.9, 1.0),
		"glow": Color(0.2, 0.8, 1.0, 0.5),
		"desc": "Deploys +11 Heavy Firewall Shield."
	},
	"ram_bit": {
		"id": "ram_bit",
		"name": "RAM Capacitor",
		"type": SymbolData.SymbolType.RAM,
		"chips": 1,
		"mult": 0.0,
		"rarity": SymbolData.Rarity.COMMON,
		"glyph": "💾",
		"color": Color(0.2, 1.0, 0.4),
		"glow": Color(0.2, 0.9, 0.3, 0.4),
		"desc": "Restores +1 RAM used for Locking reels and Cleanse/Hack abilities."
	},
	"battery": {
		"id": "battery",
		"name": "Overclock Cell",
		"type": SymbolData.SymbolType.BATTERY,
		"chips": 1,
		"mult": 0.0,
		"rarity": SymbolData.Rarity.UNCOMMON,
		"glyph": "🔋",
		"color": Color(1.0, 0.8, 0.0),
		"glow": Color(1.0, 0.7, 0.0, 0.5),
		"desc": "SYNERGY: Overcharges adjacent perimeter symbols by +50% Value!"
	},
	"igniter": {
		"id": "igniter",
		"name": "Thermal Igniter",
		"type": SymbolData.SymbolType.OVERHEAT,
		"chips": 3,
		"mult": 0.0,
		"rarity": SymbolData.Rarity.COMMON,
		"glyph": "🔥",
		"color": Color(1.0, 0.45, 0.0),
		"glow": Color(1.0, 0.3, 0.0, 0.5),
		"desc": "Applies 3 Overheat (Burn). Deals ticking damage at the start of each Boss turn."
	},
	"virus_worm": {
		"id": "virus_worm",
		"name": "Data Worm",
		"type": SymbolData.SymbolType.VIRUS,
		"chips": 3,
		"mult": 0.0,
		"rarity": SymbolData.Rarity.COMMON,
		"glyph": "☣️",
		"color": Color(0.8, 0.1, 1.0),
		"glow": Color(0.7, 0.0, 0.9, 0.5),
		"desc": "Infects Boss with 3 Virus. Deals direct Bleed damage on EVERY lever spin!"
	},
	"emp_disruptor": {
		"id": "emp_disruptor",
		"name": "EMP Disruptor",
		"type": SymbolData.SymbolType.EMP,
		"chips": 2,
		"mult": 0.0,
		"rarity": SymbolData.Rarity.UNCOMMON,
		"glyph": "🌀",
		"color": Color(0.1, 0.6, 1.0),
		"glow": Color(0.0, 0.5, 1.0, 0.5),
		"desc": "Disrupts Boss subroutines with 2 EMP stacks and boosts Piercing strikes."
	},
	"glitch_pod": {
		"id": "glitch_pod",
		"name": "Glitch Exploit",
		"type": SymbolData.SymbolType.GLITCH,
		"chips": 2,
		"mult": 0.0,
		"rarity": SymbolData.Rarity.UNCOMMON,
		"glyph": "👾",
		"color": Color(1.0, 0.0, 0.6),
		"glow": Color(1.0, 0.0, 0.5, 0.5),
		"desc": "Applies 2 Glitch stacks. Increases all inward damage dealt to Boss by +50%."
	},
	"jackpot_7": {
		"id": "jackpot_7",
		"name": "Neon Jackpot 7",
		"type": SymbolData.SymbolType.JACKPOT,
		"chips": 16,
		"mult": 1.5,
		"rarity": SymbolData.Rarity.RARE,
		"glyph": "7️⃣",
		"color": Color(1.0, 0.85, 0.1),
		"glow": Color(1.0, 0.8, 0.0, 0.7),
		"desc": "JACKPOT CHIP: Grants 16 Chips, +1.5 Mult, and pays +6 Credits directly!"
	},
	"mirror_chip": {
		"id": "mirror_chip",
		"name": "Quantum Mirror",
		"type": SymbolData.SymbolType.MIRROR,
		"chips": 3,
		"mult": 0.0,
		"rarity": SymbolData.Rarity.RARE,
		"glyph": "🪞",
		"color": Color(0.7, 0.9, 1.0),
		"glow": Color(0.6, 0.8, 1.0, 0.6),
		"desc": "Replicates the symbol on the opposite cross-core side for guaranteed cross beam!"
	},
	"crypto_miner": {
		"id": "crypto_miner",
		"name": "Crypto Miner",
		"type": SymbolData.SymbolType.MINER,
		"chips": 4,
		"mult": 0.0,
		"rarity": SymbolData.Rarity.UNCOMMON,
		"glyph": "⛏️",
		"color": Color(0.2, 0.9, 0.6),
		"glow": Color(0.1, 0.8, 0.5, 0.5),
		"desc": "Mines +2 Credits dividend directly to your Bankroll on every spin!"
	}
}

static func create_symbol(id: String) -> SymbolData:
	if not SYMBOLS.has(id):
		return null
	var data: Dictionary = SYMBOLS[id]
	var sym := SymbolData.new()
	sym.id = data.get("id", id)
	sym.display_name = data.get("name", id)
	sym.symbol_type = data.get("type", SymbolData.SymbolType.ATTACK)
	sym.base_chips = data.get("chips", 0)
	sym.mult_add = data.get("mult", 0.0)
	sym.rarity = data.get("rarity", SymbolData.Rarity.COMMON)
	sym.icon_glyph = data.get("glyph", "❓")
	sym.icon_color = data.get("color", Color.WHITE)
	sym.glow_color = data.get("glow", Color.TRANSPARENT)
	sym.description = data.get("desc", "")
	return sym

static func build_symbol_library() -> Array[SymbolData]:
	var library: Array[SymbolData] = []
	for id in SYMBOLS.keys():
		var sym := create_symbol(id)
		if sym:
			library.append(sym)
	return library
