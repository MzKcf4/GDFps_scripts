@tool # Needed so it runs in editor.
extends EditorScenePostImport

enum TextureType {
	Albedo,
	Normal,
	Unknown
}

var weapon_script = preload("res://scripts/weapon.gd")
var weapon_name
var weapon_folder_path
var weapon_sound_folder_path
var weapon_material_folder_path
var weapon_texture_folder_path

var weapon_qc_path

func _post_import(scene):
	print("---Post import BEGIN---")
	# The source file path should be : res://weapons/%weapon_name%/%weapon_name%.gltf
	# it is ASSUMED weapon folder name = gltf file name
	var gltf_path = get_source_file()
	#           0            1           2
	#  res://weapons/%weapon_name%/%weapon_name%.gltf
	weapon_name = gltf_path.replace("res://" , '').split("/")[1]
	weapon_folder_path = "res://weapons/" + weapon_name
	weapon_material_folder_path = weapon_folder_path + "/materials/"
	weapon_texture_folder_path = weapon_folder_path + "/textures/"
	weapon_sound_folder_path = weapon_folder_path + "/sounds/"
	add_texture_to_material()
	
	rename_sound_files()
		
	var qc_parser : WeaponQcParser = WeaponQcParser.new()
	var weapon_info : WeaponInfo = qc_parser.parse_qc(weapon_name)
	weapon_info.weapon_name = weapon_name
	
	create_tscn(scene , weapon_info)
	print("---Post import END---")
	return scene # Remember to return the imported scene

func add_texture_to_material():
	var material_files = get_files_in_folder(weapon_material_folder_path)
	var texture_files = get_files_in_folder(weapon_texture_folder_path)
	for material_path in material_files:
		var material_file_name = extract_file_name(material_path)
		var material : BaseMaterial3D = load(material_path)
		material.albedo_color = Color(1,1,1,1)
		
		var texture : Texture2D
		for texture_path in texture_files:
			# ../materials/abc.tres   vs  abc.png
			var texture_name = extract_file_name(texture_path)
			# print(texture_name + " vs " + material_path)
			if(material_file_name.to_lower() in texture_name.to_lower()):
				print(texture_name + ' vs ' + material_file_name)
				texture = load(texture_path)
				var texture_type: TextureType = get_texture_type(texture_name)
				if(texture_type == TextureType.Albedo):
					material.albedo_texture = texture
					print("Albedo texture mapped : " + texture_name)
				elif texture_type == TextureType.Normal:
					material.normal_enabled = true
					material.normal_texture = texture
					print("Normal texture mapped : " + texture_name)
				break
				
		if not material.albedo_texture:
			printerr("No Albedo texture found for " + material_path)

		var result = ResourceSaver.save(material , material_path , 0);
		#print("Saved " + material_path + " with result code " + str(result))
	pass

func get_texture_type(texture_name : String) -> TextureType:
	if not "_" in texture_name:
		return TextureType.Albedo
	elif "_d" in texture_name or "_ddn" in texture_name:
		return TextureType.Albedo
	elif "_n" in texture_name:
		return TextureType.Normal
	elif texture_name.ends_with("n"):
		return TextureType.Normal
	return TextureType.Unknown

func rename_sound_files():
	var dir = DirAccess.open(weapon_sound_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				var new_file_name = file_name.replace("_" , '').replace(" " , '')
				dir.rename(file_name , new_file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")


func create_tscn(scene , weapon_info : WeaponInfo):
	ResourceSaver.save(weapon_info, weapon_folder_path + "/" + weapon_name + "_info.tres" , 0)
	# attache weapon script to top node
	scene.set_script(weapon_script)
	scene.weapon_info = weapon_info
	scene.scale = Vector3(0.03 , 0.03 , 0.03)
	
	var new_weapon_scene = PackedScene.new();
	var pack_result = new_weapon_scene.pack(scene)
	var v = ResourceSaver.save(new_weapon_scene, weapon_folder_path + "/" + weapon_name + ".tscn", 0)
	print(v)




##------------------- Utils --------------------##

func get_files_in_folder(folder_path : String) -> Array[String]:
	var files : Array[String]
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if(not "import" in file_name):
					var full_path = folder_path + file_name
					files.append(full_path)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access : " + folder_path)
	return files

func extract_file_name(file_path : String) -> String:
	# res://a/b/c.png  --> 10
	var last_slash_idx = file_path.rfind("/") + 1
	# res://a/b/c.png  --> 12
	var last_dot_idx = file_path.rfind(".")
	var file_name = file_path.substr(last_slash_idx , last_dot_idx - last_slash_idx)
	return file_name
