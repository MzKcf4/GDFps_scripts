extends Object

class_name EditorUtils

static func get_files_in_folder(folder_path : String) -> Array[String]:
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

static func extract_file_name(file_path : String) -> String:
	# res://a/b/c.png  --> 10
	var last_slash_idx = file_path.rfind("/") + 1
	# res://a/b/c.png  --> 12
	var last_dot_idx = file_path.rfind(".")
	var file_name = file_path.substr(last_slash_idx , last_dot_idx - last_slash_idx)
	return file_name
