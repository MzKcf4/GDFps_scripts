extends Resource

class_name WeaponInfo

@export var test : int

@export var dict_std_ani_to_qc_ani = {
	"fire": "",
	"reload": "",
	"deploy": "",
	"idle": ""
}
# MUST match the folder name
@export var weapon_name : String
@export var fire_sound_filename : String
@export var fire_sound : AudioStream

@export var fire_interval = 0.15
@export var is_auto: bool = true
# should default to the time of animation
@export var reload_interval = 3.0
# should default to the time of animation
@export var deploy_interval = 1.0

@export var damage = 30
@export var clip_size = 30

func get_fire_animation() -> String:
	return dict_std_ani_to_qc_ani["fire"]

func get_reload_animation() -> String:
	return dict_std_ani_to_qc_ani["reload"]

func get_deploy_animation() -> String:
	return dict_std_ani_to_qc_ani["deploy"]

func get_idle_animation() -> String:
	return dict_std_ani_to_qc_ani["idle"]

func set_animation_key(std_key: String , qc_key: String):
	dict_std_ani_to_qc_ani[std_key] = qc_key
