class_name MapDatabase
extends RefCounted

## Master catalog of Floor Progression, Encounter Nodes, and Branching Routes.

const MAP_STRUCTURE: Array[Array] = [
	# Floor 1
	[{"type": "COMBAT", "name": "Patrol Drone", "icon": "🤖", "color": Color(0.0, 0.85, 1.0)}],
	# Floor 2
	[
		{"type": "COMBAT", "name": "Sec-Bot Mech", "icon": "🦿", "color": Color(0.2, 0.6, 1.0)},
		{"type": "SHOP", "name": "Data Alley Shop", "icon": "🛒", "color": Color(1.0, 0.85, 0.2)}
	],
	# Floor 3
	[
		{"type": "ELITE", "name": "Cyber-Viper AI", "icon": "🐍", "color": Color(0.9, 0.1, 0.4)},
		{"type": "MIMIC", "name": "Glitch Cache", "icon": "📦", "color": Color(0.8, 0.2, 1.0)},
		{"type": "SHOP", "name": "Black-Market", "icon": "🛒", "color": Color(1.0, 0.85, 0.2)}
	],
	# Floor 4
	[
		{"type": "COMBAT", "name": "Assault Bot", "icon": "🛡️", "color": Color(1.0, 0.45, 0.0)},
		{"type": "SHOP", "name": "Cyber Clinic", "icon": "🛒", "color": Color(1.0, 0.85, 0.2)}
	],
	# Floor 5: ACT 1 APEX MID-BOSS
	[{"type": "BOSS", "name": "OVERLORD PRIME", "icon": "👁️", "color": Color(1.0, 0.05, 0.3)}],
	# Floor 6
	[
		{"type": "COMBAT", "name": "Quantum Sentinel", "icon": "💠", "color": Color(0.3, 0.9, 1.0)},
		{"type": "SHOP", "name": "Tech Dealer", "icon": "🛒", "color": Color(1.0, 0.85, 0.2)}
	],
	# Floor 7
	[
		{"type": "ELITE", "name": "Nano-Swarm AI", "icon": "🐝", "color": Color(0.8, 0.2, 1.0)},
		{"type": "MIMIC", "name": "Cyber Vault", "icon": "📦", "color": Color(0.9, 0.2, 0.8)},
		{"type": "COMBAT", "name": "Matrix Mech", "icon": "🦾", "color": Color(0.1, 0.7, 1.0)}
	],
	# Floor 8
	[
		{"type": "ELITE", "name": "Aegis Leviathan", "icon": "🛸", "color": Color(1.0, 0.4, 0.0)},
		{"type": "SHOP", "name": "Megacorp Armory", "icon": "🛒", "color": Color(1.0, 0.85, 0.2)}
	],
	# Floor 9
	[
		{"type": "ELITE", "name": "Citadel Core", "icon": "🏰", "color": Color(1.0, 0.15, 0.4)},
		{"type": "SHOP", "name": "Final Supply Depot", "icon": "🛒", "color": Color(1.0, 0.85, 0.2)}
	],
	# Floor 10: FINAL OMEGA BOSS
	[{"type": "BOSS", "name": "FINAL OMEGA NEXUS", "icon": "👁️", "color": Color(1.0, 0.05, 0.3)}]
]

static func get_map_structure() -> Array[Array]:
	return MAP_STRUCTURE.duplicate(true)

static func get_floor_nodes(floor_number: int) -> Array:
	if floor_number >= 1 and floor_number <= MAP_STRUCTURE.size():
		return MAP_STRUCTURE[floor_number - 1]
	return []
