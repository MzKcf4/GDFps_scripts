extends Node

var footsteps: Array[AudioStream]
var weapon_registry: Dictionary

func _ready():
	_reload_weapon_info()

func pre_load_resources():
	if(footsteps.is_empty()):
		footsteps.append(load("res://sounds/footstep-concrete-1.wav"))
		footsteps.append(load("res://sounds/footstep-concrete-2.wav"))
		footsteps.append(load("res://sounds/footstep-concrete-3.wav"))

func get_weapon(weapon_id : String) -> Weapon:
	var weapon_tscn = _load_weapon_tscn(weapon_id)
	var weapon: Weapon = weapon_tscn.instantiate()
	weapon.weapon_stats = weapon_registry[weapon_id]
	return weapon

func get_footstep() -> Resource:
	return footsteps.pick_random()

func _get_weapon_info_from_file():
	if FileAccess.file_exists(OS.get_user_data_dir() + "/weapon_info.json"):
		var file: FileAccess = FileAccess.open("user://weapon_info.json" , FileAccess.READ)
		return file.get_as_text()

func _reload_weapon_info():
	var text = _get_weapon_info_from_file()
	_load_from_json_text(text)

func sync_weapon_info():
	if(NetworkManager.is_host):
		var text = _get_weapon_info_from_file()
		rpc("rpc_load_registry_from_text" , text)

@rpc("call_remote")
func rpc_load_registry_from_text(text: String):
	_load_from_json_text(text)
		
func _load_from_json_text(text : String):
	var obj = JSON.parse_string(text)
	if(!obj):
		printerr("Error parsing weapon settings")
		return
	for info in obj:
		var weapon_stats = WeaponStats.new()
		weapon_stats.fromJson(info)
		weapon_registry[weapon_stats.weapon_id] = weapon_stats

func _load_weapon_tscn(weapon_id : String) -> Resource :
	var path = "res://weapons/{0}/{1}.tscn".format([weapon_id , weapon_id])
	print(path)
	return load(path)

func _get_weapon_info_file_path(wpn_name) -> String:
	return "res://weapons/{0}/{1}_info.tres".format([wpn_name ,wpn_name])
