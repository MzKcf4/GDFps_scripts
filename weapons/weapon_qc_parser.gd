extends Object

class_name WeaponQcParser
const EditorUtils = preload("res://scripts/editor/editor_utils.gd")

# 1: [Manual Step] extract animations , sounds , place to correct folder 
# 2: [Manual Step] prepare the tscn scene from the gltf file <-------------
# 3: [Auto] Extract required animation AND mapping of frame-to-sound from qc file
# 4: [Auto] Update the AnimationPlayer in the scene and add tracks to it

#const WEAPON_NAME = "negev"
# QC should be inside the weapon folder as well
#const WEAPON_QC_PATH = "D:/Programming/Unity/UnityFps/- UnityBlender/_L4D2/SV98/v/Decompiled/v_snip_awp.qc"

var weapon_name
var weapon_folder
var weapon_qc_path 
var sound_folder
var animation_folder

var weapon_ani_res : WeaponAnimationResource
# Animation has dict<frame , sound> 
var dict_ani_to_sound_dict : Dictionary
var dict_frame_to_sound_ary : Dictionary
var weapon_info : WeaponInfo

const SOUND_EVENT_FRAME_FPS_DIVIDER = 24

# Some animation's LAYER is fucked up , but some not.
const USE_LAYER : bool = false

# append "_layer" at the end for layered version 
const STD_ANI_KEYS : Array = ["deploy" , "fire" , "reload" , "idle"]
const EXCLUDED_KEYS : Array = ["_empty" , "_last" , "anim_"]

const STD_ANI_KEYS_MAPPING : Dictionary = { 
	"deploy" : ["deploy" , "draw"],
	"fire" : ["fire" , "shoot"],
	"reload" : ["reload"],
	"idle" : ["idle" , "a_idle_1"]
  }

func parse_qc(weapon_name: String) -> WeaponInfo:
	weapon_ani_res = WeaponAnimationResource.new()
	weapon_info = WeaponInfo.new()
	
	self.weapon_name = weapon_name
	weapon_folder = "res://weapons/" + weapon_name
	weapon_qc_path = weapon_folder + "/" + weapon_name + ".qc"
	sound_folder = weapon_folder + "/sounds/"
	animation_folder = weapon_folder + "/animations/"
	
	print("[Parse QC] BEGIN --- " + weapon_name + "---")
	parse_qc_file(weapon_qc_path)
	
	weapon_ani_res.print_info()
	# weapon_ani_res.map_sound_to_res(sound_folder)
	map_fire_audio()
	map_sound_to_animation_resource()
	
	print("[Parse QC] END --- " + weapon_name + "---")
	return weapon_info

func map_fire_audio():
	var sound_files = EditorUtils.get_files_in_folder(sound_folder)
	for file_name in sound_files :
		print(file_name)
		if("fire" in file_name or "shoot" in file_name):
			weapon_info.fire_sound = load(file_name)
			weapon_info.fire_sound_filename = file_name;
			print("fire sound found : " + file_name)
			print(weapon_info.fire_sound)
			return

func parse_qc_file(qc_user_path):
	print("Parsing " + qc_user_path)
	var file: FileAccess = FileAccess.open(qc_user_path , FileAccess.READ)
	var text = file.get_as_text()
	var lines: PackedStringArray = text.split("\n")
	
	for i in lines.size():
		if(not "$sequence" in lines[i]):
			i = i + 1
			continue
		#    0         1   2
		# $sequence "idle" {
		var sequence_name = lines[i].split(' ')[1].replace('"' , '').to_lower()
		print("---Found QC sequence : " + sequence_name + "---")
		var should_skip : bool = false
		# skip some seq like reload_empty 
		for excluded_key in EXCLUDED_KEYS:
			print(excluded_key + " vs " + sequence_name)
			if(excluded_key in sequence_name):
				should_skip = true
				break
		if(should_skip):
			continue;
		
		# first map the frame-sound.
		for std_key in STD_ANI_KEYS_MAPPING.keys(): 
			# e.g looping [deploy] = ["deploy" , "draw"]
			for std_ani_name in STD_ANI_KEYS_MAPPING[std_key]:
				if(not std_ani_name in sequence_name):
					continue
				print("Mapping QC " + sequence_name + " to standard ani " + std_ani_name)
				# either 'deploy' / 'draw' found 
				weapon_ani_res.add_standard_animation(std_key)
				i = i + parse_animation_seq(lines, i,std_key)
				# after that , check if using 'LAYER' mode
				# we can't simply skip 'layer' because sounds definitions are usually in 'layer'
				if(not USE_LAYER and "_layer" in sequence_name):
					continue
				# map std_ani to animation name 
				var animation_name = find_corresponding_animation_name(sequence_name)
				weapon_ani_res.set_animation_qc_key(std_key , sequence_name)
				weapon_ani_res.set_animation_name(std_key, animation_name)
				var fps = weapon_ani_res.get_animation_fps_key(std_key)
				weapon_info.set_animation_key(std_key, animation_name , fps)
				# no need to loop further when found
				break;
				
func parse_animation_seq(lines: PackedStringArray , start_line: int,std_ani_key:String) -> int:
	# First , look for 'event' line
	var line_parsed = 0
	for i in range(start_line , lines.size()):
		var line = lines[i]
		# fps should indicates the end of sequence.
		if ("fps" in line):
			# 0    1
			# fps 42.5
			var fps = int(line.split(' ')[1])
			weapon_ani_res.set_animation_fps(std_ani_key , fps)
			line_parsed = line_parsed + 1
			break
		# event 5004 means 'play sound'
		elif ("event 5004" in line):
			# 0   1    2   3       4        5
			# { event 5004 15 "AK47.Clipout }"
			var event_parts = line.split(' ')
			var frame = event_parts[3]
			#    0     1
			# "AK47.Clipout"
			var sound_name = event_parts[4].split('.')[1].replace('"' , '').to_lower()
			weapon_ani_res.add_sound_to_std_ani(std_ani_key,frame,sound_name)
		elif ("}" in line):
			if("{" in line):
				pass
			else:
				# end of whle sequence
				line_parsed = line_parsed + 1
				break
		line_parsed = line_parsed + 1
	return line_parsed

func find_corresponding_animation_name(seq_name: String) -> String:
	var dict = get_animation_resources()
	for file_path in dict.keys():
		var ani_file_name = EditorUtils.extract_file_name(file_path)
		#var name_to_match = seq_name + ".res"
		if(seq_name == ani_file_name):
			var file_paths = file_path.split('/')
			var ani_name = file_paths[file_paths.size() - 1].replace(".res" , '')
			return ani_name
	return "";

func load_corresponding_animation_resouce(animation_name : String) -> Resource:
	var animation_files : Array[String] = EditorUtils.get_files_in_folder(animation_folder)
	for file_path in animation_files:
		var file_name : String = EditorUtils.extract_file_name(file_path);
		if(animation_name in file_name and animation_name.length() == file_name.length()):
			return load(file_path)
	printerr("[WARN] cannot find animation file for " + animation_name)
	return null

func load_corresponding_audio_resouce(sound_name : String) -> Resource:
	var animation_files : Array[String] = EditorUtils.get_files_in_folder(sound_folder)
	for file_path in animation_files:
		var file_name : String = EditorUtils.extract_file_name(file_path);
		if(sound_name in file_name):
			return load(file_path)
	printerr("[WARN] cannot find sound file for " + sound_name)
	return null


func map_sound_to_animation_resource():
	var dict_ani_key_to_res = get_animation_resources();
	var available_animations = dict_ani_key_to_res.keys();
	
	# loop through all the standard animations in weapon animation resource
	for std_ani_key in weapon_ani_res.dict_std_ani_info.keys():
		var dict_frame_to_sound : Dictionary = weapon_ani_res.get_sound_to_frame_dict(std_ani_key)
		var animation : Animation = load_corresponding_animation_resouce(weapon_ani_res.get_animation_name(std_ani_key))
		if(animation == null):
			continue
		var fps = weapon_ani_res.get_animation_fps_key(std_ani_key)
		for sound_frame in dict_frame_to_sound.keys():
			var sound_name : String = dict_frame_to_sound[sound_frame]
			#e.g clipout , clipin ...
			# First create an AudioTrack , 
			var track_idx = animation.add_track(Animation.TYPE_AUDIO)
			# Then point the track to use Node("AudioStreamPlayer")
			animation.track_set_path(track_idx , "AudioStreamPlayer")
			
			var time : float = float(sound_frame) / SOUND_EVENT_FRAME_FPS_DIVIDER
			var sound_res = load_corresponding_audio_resouce(sound_name)
			animation.audio_track_insert_key(track_idx, time , sound_res);
			print("inserted " + sound_name + " to " + sound_frame)
		ResourceSaver.save(animation)
		print('saved ' + animation.resource_name)

func get_animation_resources() -> Dictionary:
	var dict_ani_key_to_res : Dictionary = {}
	var dir = DirAccess.open(animation_folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			# print("checking " + file_name + " against " + sound_name)
			if(not "import" in file_name):
				var file_path = animation_folder + file_name
				var res: Resource = load(file_path)
				dict_ani_key_to_res[file_path] = res
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return dict_ani_key_to_res;

