extends Node3D

class_name Weapon
# see : 
# https://docs.godotengine.org/en/stable/classes/class_animationplayer.html
# https://docs.godotengine.org/en/stable/classes/class_animation.html#class-animation-method-track-get-key-value
@export var muzzle_flash_scene : PackedScene
@export var skeleton : Skeleton3D
@export var weapon_info : WeaponInfo
# Expected to have %wpn_name%_info.tres in the same path as the weapon scene
@export var weapon_info_res_path : String
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var fire_interval_timer : Timer = $FireIntervalTimer
@onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer
var fire_audio_player : AudioStreamPlayer;

# weapon path MUST be stored under "res://weapons/"
var weapon_folder
var sound_folder
var fire_sound

var clip_size : int = 30
var curr_ammo : int
var damage : int = 30
var fire_interval : float = 0.1
var dispersion : float = 0.1

var muzzle_flash_effect : GPUParticles3D
var can_fire : bool = true

var weapon_stats : WeaponStats

func init_from_config():
	if(!weapon_stats):
		return
	self.damage = weapon_stats.z_damage
	self.curr_ammo = weapon_stats.clip_size
	self.clip_size = weapon_stats.clip_size
	self.dispersion = weapon_stats.dispersion
	self.fire_interval = weapon_stats.fire_interval
	
# Called when the node enters the scene tree for the first time.
func _ready():
	init_from_config()
	if(not fire_interval_timer):
		fire_interval_timer = Timer.new()
		add_child(fire_interval_timer)
	if(not audio_player):
		audio_player = AudioStreamPlayer.new()
		audio_player.name = "AudioStreamPlayer"
		add_child(audio_player)
	if(not skeleton):
		skeleton = find_child("Skeleton3D");
		#print(skeleton)
	fire_audio_player = AudioStreamPlayer.new()
	fire_audio_player.name = "fireAudioPlayer"
	add_child(fire_audio_player)
		
	weapon_folder = "res://weapons/" + weapon_info.weapon_name + "/";
	sound_folder = weapon_folder + "/sounds/"
	fire_sound = load(weapon_info.fire_sound_filename)
	fire_interval_timer.timeout.connect(_on_fire_interval_timer_timeout)
	fire_interval_timer.one_shot = true
#	var muzzle_flash_obj = muzzle_flash_scene.instantiate()
#	var muzzle_attach_node = muzzle_attachment.find_child("Muzzle")
#	muzzle_attach_node.add_child(muzzle_flash_obj)
#	muzzle_flash_effect = muzzle_flash_obj.find_child("GPUParticles3D")
#	muzzle_flash_effect.local_coords = true
	pass

func _process(delta):
	pass

func deploy():
	can_fire = false
	var ani_info = weapon_info.get_deploy_animation()
	animation_player.speed_scale = ani_info.fps / 30.0
	animation_player.play(ani_info.seq_name)
	await animation_player.animation_finished
	can_fire = true

func reload():
	can_fire = false
	var ani_info = weapon_info.get_reload_animation()
	animation_player.speed_scale = ani_info.fps / 30.0
	animation_player.play(ani_info.seq_name)
	await animation_player.animation_finished
	can_fire = true
	curr_ammo = clip_size

func get_reload_time() -> float:
	return animation_player.get_animation(weapon_info.get_reload_animation().seq_name).length

func fire() -> bool:
	if(not can_fire):
		return false
	can_fire = false
	animation_player.stop()
	
	var ani_info = weapon_info.get_fire_animation()
	animation_player.speed_scale = ani_info.fps / 30.0
	animation_player.play(ani_info.seq_name)
	fire_audio_player.set_stream(weapon_info.fire_sound)
	fire_audio_player.play()
	
	curr_ammo -= 1
	if(curr_ammo > 0):
		fire_interval_timer.start(fire_interval)
	
	# muzzle_flash_effect.emitting = true
	return true

func get_weapon_fire_sound() -> AudioStream:
	return weapon_info.fire_sound
	
func play_fire_effect():
#	muzzle_flash_effect.emitting = true
	pass
	# Animation.TYPE_AUDIO


func _on_fire_interval_timer_timeout():
	can_fire = true
	pass # Replace with function body.
