class_name RelicDatabase
extends RefCounted

## Declarative Dictionary catalog of all Hardware Augments / Relics.

const RELICS: Dictionary = {
	"nano_regen": {
		"id": "nano_regen",
		"name": "Nano Regenerator",
		"type": RelicData.RelicType.NANO_REGEN,
		"glyph": "🧬",
		"color": Color(0.2, 1.0, 0.6),
		"cost": 30,
		"desc": "Installs nano-firewalls to grant +4 Shield automatically on every lever spin."
	},
	"overclock_module": {
		"id": "overclock_module",
		"name": "Overclock Sub-Module",
		"type": RelicData.RelicType.OVERCLOCK_MODULE,
		"glyph": "⚡",
		"color": Color(1.0, 0.8, 0.0),
		"cost": 35,
		"desc": "Battery cells now provide +75% adjacency multiplier instead of +50%."
	},
	"viral_payload": {
		"id": "viral_payload",
		"name": "Viral Payload Injector",
		"type": RelicData.RelicType.VIRAL_PAYLOAD,
		"glyph": "☣️",
		"color": Color(0.8, 0.2, 1.0),
		"cost": 35,
		"desc": "Data Virus deals +2 bonus Cyber Damage whenever triggered and infects neighbors."
	},
	"reload_capacitor": {
		"id": "reload_capacitor",
		"name": "Reserve RAM Bank",
		"type": RelicData.RelicType.RELOAD_CAPACITOR,
		"glyph": "💾",
		"color": Color(0.2, 0.8, 1.0),
		"cost": 40,
		"desc": "Increases Max RAM by +1 and starts every combat fully loaded."
	},
	"crypto_stake": {
		"id": "crypto_stake",
		"name": "High-Roller Stake",
		"type": RelicData.RelicType.CRYPTO_STAKE,
		"glyph": "📈",
		"color": Color(0.2, 1.0, 0.5),
		"cost": 40,
		"desc": "Every 25 Credits in your Bankroll adds +0.3 Base Multiplier to all attack lines!"
	},
	"plasma_converter": {
		"id": "plasma_converter",
		"name": "Kinetic Reflector",
		"type": RelicData.RelicType.PLASMA_CONVERTER,
		"glyph": "🛡️",
		"color": Color(0.0, 0.9, 1.0),
		"cost": 35,
		"desc": "30% of absorbed Firewall Shield is converted into direct counter-attack laser damage!"
	}
}

static func create_relic(id: String) -> RelicData:
	if not RELICS.has(id):
		return null
	var data: Dictionary = RELICS[id]
	var r := RelicData.new()
	r.id = data.get("id", id)
	r.display_name = data.get("name", id)
	r.relic_type = data.get("type", RelicData.RelicType.NANO_REGEN)
	r.icon_glyph = data.get("glyph", "❓")
	r.icon_color = data.get("color", Color.WHITE)
	r.cost = data.get("cost", 30)
	r.description = data.get("desc", "")
	return r

static func build_relic_library() -> Array[RelicData]:
	var library: Array[RelicData] = []
	for id in RELICS.keys():
		var r := create_relic(id)
		if r:
			library.append(r)
	return library
