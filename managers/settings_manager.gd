extends Node

const SAVE_PATH = "user://config.cfg"

var config = ConfigFile.new();
var player_setting: PlayerSettings

var effective_mouse_sensitivity : float

# Further improvement : 
# https://www.youtube.com/watch?v=IrUhyf-g5hU
func _ready():
	load_settings()

func get_or_load_player_settings() -> PlayerSettings:
	if(player_setting == null):
		load_settings()
	return player_setting

func save_settings(new_setting: PlayerSettings):
	self.player_setting = new_setting
	config.load(SAVE_PATH)

	config.set_value("main" , "audio_volumne" , player_setting.audio_volumne)
	config.set_value("main" , "mouse_sensitivity" , player_setting.mouse_sensitivity)
	
	config.save(SAVE_PATH)
	update_cached_values()

func load_settings():
	config.load(SAVE_PATH)
#	var error = config_file.load(SAVE_PATH)
#	if(error != OK):
#		printerr("Error loading settings : %s" % error)
#		return
	player_setting = PlayerSettings.new()
	var audio_volumne = config.get_value("main" , "audio_volumne" , 100)
	if(audio_volumne != null):
		player_setting.audio_volumne = audio_volumne
	
	var mouse_sensitivity = config.get_value("main" , "mouse_sensitivity" , 100)
	if(mouse_sensitivity != null):
		player_setting.mouse_sensitivity = float(mouse_sensitivity)
	update_cached_values()

func update_cached_values():
	effective_mouse_sensitivity = float(player_setting.mouse_sensitivity) / 1000.0

#---- Getters ----#
func get_effective_mouse_sensitivity() -> float:
	return effective_mouse_sensitivity
