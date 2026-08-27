class_name RelicData
extends Resource

enum RelicType {
	NANO_REGEN,        # Gain +6 Firewall shield on every spin
	LUCKY_TRANSISTOR,  # Boosts Jackpot symbol spawn rate and triples payout
	OVERCLOCK_MODULE,  # Batteries buff adjacent symbols by +150% extra
	VIRAL_PAYLOAD,     # Data Virus deals +5 bonus damage and spreads
	EMP_SUPERCHARGER,  # EMP adds +50% Vulnerability bonus
	RELOAD_CAPACITOR,  # Start combat with +2 extra RAM
	CRYPTO_STAKE,      # Every 40 Credits bankroll adds +1 Base Mult to all lines
	PLASMA_CONVERTER,  # Excess shield converts into direct laser damage against Boss
	GOLDEN_CIRCUIT     # Win +50% more Credits after victory & spins
}

@export var id: String = "nano_regen"
@export var display_name: String = "Nano Regenerator"
@export var relic_type: RelicType = RelicType.NANO_REGEN
@export var icon_glyph: String = "🧬"
@export var icon_color: Color = Color(0.2, 1.0, 0.6)
@export var cost: int = 50
@export_multiline var description: String = "Installs nano-firewalls to grant +6 Shield automatically on every lever spin."
