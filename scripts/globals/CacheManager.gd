extends Node

const CACHE_DIR = "user://cache"
enum CacheErrors {
	SUCESS,
	NO_URL,
	DOWNLOAD_FAIL,
	FILE_DOESNT_EXIST,
	PARSE_ERROR,
}

func get_icon(game_id: String, file_name: String="icon.png", url: String="") -> Texture2D:
	if url == "":
		url = GamesMan.Games.get(game_id)["icon"]
	var request := await _get_cache(game_id, file_name, url)
	if request["error"] != CacheErrors.SUCESS:
		push_warning("Failed to get icon %s/%s" % [game_id, file_name])
	
	var image = Image.load_from_file(request["data"])
	var texture = ImageTexture.create_from_image(image)
	if texture:
		return texture
	else:
		push_warning("Texture file is not valid! Deleting ", request["data"])
		DirAccess.remove_absolute(request["data"])
	
	return load("res://icon.svg")


func get_games() -> Dictionary:
	var cache := await _get_cache("", "games.json", "http://localhost:12345/games.json")
	if cache["error"] != CacheErrors.SUCESS:
		print("error")
		return cache
	var parse = parse_json(cache.get("data"))
	print("parsed")
	return parse


func get_tags(game_id: String, url: String) -> Dictionary:
	var cache := await _get_cache(game_id, "tags.json", url)
	if cache["error"] != CacheErrors.SUCESS:
		return cache
	
	var parse = parse_json(cache.get("data"))
	
	return parse


func get_release(game_id: String, version: String) -> void:
	pass


func parse_json(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_warning(file_path, " doesn't exist!")
		return { "error": CacheErrors.FILE_DOESNT_EXIST, "data": null }
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_warning("Failed to read file ", file_path, " got open error ", FileAccess.get_open_error())
	
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	if err != OK:
		print("Failed to parse: ", err)
		return {"error": CacheErrors.PARSE_ERROR, "data": null}
	var response = json.get_data()
	
	return {"error": CacheErrors.SUCESS, "data": response}


func _get_cache(game_id: String, file_name: String, url:String="") -> Dictionary:
	var folder_path := CACHE_DIR
	if game_id != "":
		folder_path += "/%s" % [game_id]
	var file_path := folder_path + "/%s" % file_name
	
	print("Dir")
	if not DirAccess.dir_exists_absolute(folder_path):
		DirAccess.make_dir_recursive_absolute(folder_path)
	print("file")
	if not FileAccess.file_exists(file_path):
		if url == "":
			print("url is empty: ", game_id, " ", file_name)
			return { "error": CacheErrors.NO_URL, "data": null }
		else:
			print("Request")
			var request := await HttpMan.request_file(url, file_name, false, folder_path)
			if request["error"] != HttpMan.NovaError.SUCESS:
				push_warning("Failed to download ", file_path, " from url ", url)
				return { "error": CacheErrors.DOWNLOAD_FAIL, "data": null }
	
	return { "error": CacheErrors.SUCESS, "data": file_path }
