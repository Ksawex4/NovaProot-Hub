extends Node

func save_file(file_name: String, data: Dictionary, path: String ="user://") -> void:
	var data_string: String = JSON.stringify(data)
	var file_path := path + file_name
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if FileAccess.get_open_error() == OK:
		file.store_string(data_string)
		file.close()
	else:
		push_error("Failed to create file at ", file_path, " got error: ", FileAccess.get_open_error())


## an empty Dictionary means File doesn't exist, some error appeared or the file had an empty dictionary
func get_data_from_file(file_name: String, path: String="user://") -> Dictionary:
	var file_path := path + file_name
	if FileAccess.file_exists(file_path):
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if FileAccess.get_open_error() == OK:
			var data_string: String = file.get_as_text()
			var data: Dictionary = JSON.parse_string(data_string)
			return data
		else:
			push_error("Failed to read file at ", file_path, " got error: ", FileAccess.get_open_error())
			return {}
	else:
		return {}
