extends Resource

class_name WeaponAnimationResource

# Weapon has following standard abstract animations
# fire , reload , deploy , idle

# These animations has 'sound' to play on corresponding frames
# So the structure should be
# { "reload" : { "qc_key" : "reload_layer",
#				 "ani_name" : "v_snip_awp_qc_skeleton_reload_layer"
#                "dict_frame_to_sound" : 
#                	{ "1" : "clipout",
#					  "23" : "clipin" }
#                 "fps" : 23
#               }
var dict_std_ani_info : Dictionary

var dict_sound_to_res : Dictionary

func add_standard_animation(std_ani: String):
	if(dict_std_ani_info.has(std_ani)):
		return
		
	dict_std_ani_info[std_ani] = {
		"qc_key" : "",
		"ani_name" : "",
		"dict_frame_to_sound" : { },
		# multiplier formula = fps / 24.0f
		"fps" : -1
	}

func set_animation_qc_key(std_ani: String , qc_key : String):
	dict_std_ani_info[std_ani]["qc_key"] = qc_key
	
func get_animation_qc_key(std_ani: String) -> String:
	return dict_std_ani_info[std_ani]["qc_key"]
	
func set_animation_fps(std_ani: String , fps : int):
	dict_std_ani_info[std_ani]["fps"] = fps
	
func get_animation_fps_key(std_ani: String) -> int:
	return dict_std_ani_info[std_ani]["fps"]
	
func set_animation_name(std_ani: String , ani_name:String):
	dict_std_ani_info[std_ani]["ani_name"] = ani_name
	
func get_animation_name(std_ani: String) -> String:
	return dict_std_ani_info[std_ani]["ani_name"]
	
func add_sound_to_std_ani(std_ani: String , frame: String , sound: String):
	var dict_frame_to_sound = dict_std_ani_info[std_ani]["dict_frame_to_sound"]
	dict_frame_to_sound[frame] = sound
	# create empty entry for a sound_name
	dict_sound_to_res[sound] = {}
	pass

func get_sound_to_frame_dict(std_ani: String) -> Dictionary:
	return dict_std_ani_info[std_ani]["dict_frame_to_sound"]


func print_info():
	print("-------Info : --------")
	for key in dict_std_ani_info.keys():
		print(key + " : qc_key = " + dict_std_ani_info[key]["qc_key"] + " ; fps = " + str(dict_std_ani_info[key]["fps"]) + " ; animation_name = " + dict_std_ani_info[key]["ani_name"])
		var dict_frame_to_sound:Dictionary = dict_std_ani_info[key]["dict_frame_to_sound"]
		for frame in dict_frame_to_sound.keys():
			print("  " + frame + " : " + dict_frame_to_sound[frame])


func get_standard_animation_keys() -> Array :
	return dict_std_ani_info.keys()

func get_sound_resource(sound_key : String) :
	return dict_sound_to_res[sound_key]


func map_sound_to_res(sound_folder: String):
	print("----- Map sound to res -----")
	for sound_name in dict_sound_to_res.keys():
		print("sound key : " + sound_name)
		var dir = DirAccess.open(sound_folder)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()

			while file_name != "":
				# print("checking " + file_name + " against " + sound_name)
				if(not "import" in file_name and sound_name in file_name):
					var file_path = sound_folder + file_name
					var file_exist = ResourceLoader.exists(file_path)
					# print(file_path + " exist : " + str(file_exist))
					var res: Resource = load(file_path)
					dict_sound_to_res[sound_name] = res
					print(res)
				file_name = dir.get_next()
		else:
			print("An error occurred when trying to access the path.")
