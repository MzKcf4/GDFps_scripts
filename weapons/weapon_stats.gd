extends Object

class_name WeaponStats

var weapon_id: String = "weapon"
var weapon_name: String = "weapon"
var fire_interval: float = 0.15
var damage: int = 30
var clip_size: int = 30
var dispersion: float = 0

var can_scope: bool = false
var is_auto: bool = true

var z_damage: int = 30
var z_tier: int = 1

func fromJson(jsonObj):
	weapon_id = jsonObj.weaponFolderName
	weapon_name = jsonObj.displayName
	damage = int(jsonObj.damage)
	fire_interval = float(jsonObj.fireInterval)
	clip_size = int(jsonObj.clipSize)
	dispersion = float(jsonObj.dispersion)
	is_auto = bool(jsonObj.fullAuto)
	
	z_damage = int(jsonObj.zdamage)
	z_tier = int(jsonObj.ztier)
