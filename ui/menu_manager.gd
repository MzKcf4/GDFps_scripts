extends Control

class_name PlayerMenu

@onready var settings_container: Control = $Panel/SettingsPanel
@onready var mouse_sensitivity_slider : Slider = $Panel/SettingsPanel/MarginContainer/SettingsContainer/VBoxContainer/MouseSensitivityContainer/MouseSensitivitySlider
@onready var mouse_sensitivity_text : LineEdit = $Panel/SettingsPanel/MarginContainer/SettingsContainer/VBoxContainer/MouseSensitivityContainer/MouseSensitivityText
@onready var audio_volumne_slider : Slider = $Panel/SettingsPanel/MarginContainer/SettingsContainer/VBoxContainer/AudioVolumneContainer/AudioVolumneSlider
@onready var audio_volumne_text : LineEdit = $Panel/SettingsPanel/MarginContainer/SettingsContainer/VBoxContainer/AudioVolumneContainer/AudioVolumneText

@onready var host_game_btn : Button = $Panel/ButtonContainer/BtnHostGame
@onready var connect_container : Container = $Panel/ButtonContainer/ConnectContainer
@onready var disconnect_btn : Button = $Panel/ButtonContainer/BtnDisconnect
@onready var ip_text : LineEdit = $Panel/ButtonContainer/ConnectContainer/TextIp

var loaded_player_setting: PlayerSettings

func _ready():
	load_from_player_setting()
	update_buttons()

func load_from_player_setting():
	self.loaded_player_setting = SettingsManager.get_or_load_player_settings()
	mouse_sensitivity_slider.value = loaded_player_setting.mouse_sensitivity
	audio_volumne_slider.value = loaded_player_setting.audio_volumne

func save_player_setting():
	loaded_player_setting.mouse_sensitivity = float(mouse_sensitivity_slider.value)
	loaded_player_setting.audio_volumne = float(audio_volumne_slider.value)
	SettingsManager.save_settings(loaded_player_setting)

func toggle_settings_container(isVisible: bool):
	settings_container.visible = isVisible
	
func toggle():
	self.visible = !self.visible
	if(self.visible):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_buttons()
	
func update_buttons():
	host_game_btn.visible = GameManager.is_in_main_menu
	connect_container.visible = GameManager.is_in_main_menu
	disconnect_btn.visible = !GameManager.is_in_main_menu


func _on_btn_host_game_pressed():
	GameManager.start_server()
	
func _on_btn_disconnect_pressed():
	GameManager.stop_game()
	
func _on_btn_connect_pressed():
	var ip = ip_text.text
	GameManager.start_client(ip)

func _on_btn_option_pressed():
	toggle_settings_container(true)

func _on_btn_settings_ok_pressed():
	toggle_settings_container(false)
	save_player_setting()

func _on_btn_settings_cancel_pressed():
	toggle_settings_container(false)

func _on_mouse_sensitivity_slider_value_changed(new_value: float):
	mouse_sensitivity_text.text = str(new_value)
	
func _on_audio_volumne_slider_value_changed(new_value: float):
	audio_volumne_text.text = str(new_value)

func _on_btn_exit_pressed():
	get_tree().quit()


