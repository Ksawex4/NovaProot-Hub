extends Node

const CACHE_DIR = "user://cache"
enum CacheError {
	SUCESS,
	NO_URL,
	DOWNLOAD_FAIL,
	FILE_DOESNT_EXIST,
	PARSE_ERROR,
	READ_FAIL,
}

func get_icon(game_id: String, file_name: String="icon.png", url: String="") -> Texture2D:
	if url == "":
		url = GamesMan.Games.get(game_id)["icon"]
	var request := await _request_icon(game_id, file_name, url)
	if request["error"] != CacheError.SUCESS:
		push_warning("Failed to get icon %s" % [url])
	
	var image = Image.load_from_file(request["data"])
	var texture = ImageTexture.create_from_image(image)
	if texture:
		return texture
	else:
		push_warning("Texture file is not valid! Deleting ", request["data"])
		DirAccess.remove_absolute(request["data"])
		await _request_icon(game_id, file_name, url)
	
	return load("res://icon.svg")


func _request_icon(game_id: String, file_name: String, url: String) -> Dictionary:
	var folder_path := CACHE_DIR + "/%s" % game_id
	var file_path := folder_path + "/%s" % file_name
	
	if not DirAccess.dir_exists_absolute(folder_path):
		DirAccess.make_dir_recursive_absolute(folder_path)
	
	if FileAccess.file_exists(file_path):
		return {"error": CacheError.SUCESS, "data": file_path}
	
	var request := await HttpMan.request_file(url, file_name, false, folder_path)
	
	if request["error"] != HttpMan.NovaError.SUCESS:
		print("Failed to download icon, url: ", url, " error: ", request["error"])
		return request
	
	return { "error": CacheError.SUCESS, "data": file_path }


func get_games() -> Dictionary:
	var url := "http://localhost:12345/games.json"
	var request := await _request_games("games.json", url) # url will be https://github.com/Ksawex4/NovaProot-Hub/raw/refs/heads/main/data/games.json later
	if request["error"] != CacheError.SUCESS:
		print("Failed to get games, %s" % url)
		return request
	var parse = parse_json(request.get("data"))
	return parse


func _request_games(file_name: String, url: String) -> Dictionary:
	var file_path := CACHE_DIR + "/%s" % file_name
	
	if not DirAccess.dir_exists_absolute(CACHE_DIR):
		DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	
	if FileAccess.file_exists(file_path):
		return {"error": CacheError.SUCESS, "data": file_path}
	
	var request := await HttpMan.request_file(url, file_name, true, CACHE_DIR)
	
	if request["error"] != HttpMan.NovaError.SUCESS:
		print("Failed to download games, url: ", url, " error: ", request["error"])
		return request
	
	return {"error": CacheError.SUCESS, "data": file_path}


func get_tags(game_id: String, url: String) -> Dictionary:
	var request := await _request_tags(game_id, url)
	if request["error"] != CacheError.SUCESS:
		return request
	
	var parse = parse_json(request.get("data"))
	
	return parse


func _request_tags(game_id: String, url: String, file_name: String="tags.json") -> Dictionary:
	var folder_path := CACHE_DIR + "/%s" % game_id
	var file_path := folder_path + "/%s" % file_name
	
	if not DirAccess.dir_exists_absolute(folder_path):
		DirAccess.make_dir_recursive_absolute(folder_path)
	
	if FileAccess.file_exists(file_path):
		return { "error": CacheError.SUCESS, "data": file_path }
	
	
	var request := await HttpMan.request_file(url, file_name, true, folder_path)
	
	if request["error"] != CacheError.SUCESS:
		print("Failed to download tags for %s error: %s url: %s" % [game_id, request["error"], url])
		return request
	
	return { "error": CacheError.SUCESS, "data": request["data"] }


func get_release(game_id: String, version: String, url: String) -> Dictionary:
	var request := await _request_release(game_id, version, url)
	if request["error"] != CacheError.SUCESS:
		return {"error": request["error"], "data": {}}
	var parse := parse_json(request["data"])
	
	return {"error": CacheError.SUCESS, "data": parse}

func _request_release(game_id: String, version: String, url: String) -> Dictionary:
	var folder_path := CACHE_DIR + "/%s" % game_id
	var file_name := "%s.json" % version
	var file_path := folder_path + "/%s" % file_name
	
	if not DirAccess.dir_exists_absolute(folder_path):
		DirAccess.make_dir_recursive_absolute(folder_path)
	
	if FileAccess.file_exists(file_path):
		return { "error": CacheError.SUCESS, "data": file_path }
	
	
	var request := await HttpMan.request_file(url, file_name, true, folder_path)
	
	if request["error"] != CacheError.SUCESS:
		print("Failed to download tags for %s error: %s url: %s" % [game_id, request["error"], url])
		return request
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	var dataf: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	
	request["data"] = dataf
	var data: Dictionary[String, Variant] = {}
	data.set("name", request.get("data").get("name"))
	data.set("body", request.get("data").get("body"))
	var game_downloads: Dictionary[String, String] = {}
	for asset in request.get("data").get("assets"):
		var asset_name: String = asset.get("name")
		asset_name = asset_name.to_lower()
		var asset_url: String = asset.get("browser_download_url")
		if asset_name.ends_with(".apk"):
			game_downloads.set("Android", asset_url)
			continue
		if asset_name.contains("linux"):
			game_downloads.set("Linux", asset_url)
			continue
		if asset_name.contains("windows"):
			game_downloads.set("Windows", asset_url)
			continue
	data.set("assets", game_downloads)
	request["data"] = data
	print("data: ", data)
	
	var file2 := FileAccess.open(file_path, FileAccess.WRITE)
	file2.store_string(JSON.stringify(request["data"]))
	file2.close()
	
	return { "error": CacheError.SUCESS, "data": file_path }


func parse_json(file_path: String) -> Dictionary:
	#if not FileAccess.file_exists(file_path):
		#print("File doesn't exist ", file_path)
		#return {"error": CacheError.FILE_DOESNT_EXIST, "data": null}
	#
	#var file := FileAccess.open(file_path, FileAccess.READ)
	#if FileAccess.get_open_error() != OK:
		#print("Failed to read file %s got open error %s" % [file_path, FileAccess.get_open_error()])
		#return {"error": CacheError.READ_FAIL, "data": null}
	#
	#var json := JSON.new()
	#var err := json.parse_
	#
	#return {"error": CacheError.SUCESS, "data": {}}
	if not FileAccess.file_exists(file_path):
		push_warning(file_path, " doesn't exist!")
		return { "error": CacheError.FILE_DOESNT_EXIST, "data": null }
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_warning("Failed to read file ", file_path, " got open error ", FileAccess.get_open_error())
	
	var parsed_file_data = JSON.parse_string(file.get_as_text())
	#print(parsed_file_data, " <- file")
	
	return {"error": CacheError.SUCESS, "data": parsed_file_data}


#func _get_cache(game_id: String, file_name: String, url:String="") -> Dictionary:
	#var folder_path := CACHE_DIR
	#if game_id != "":
		#folder_path += "/%s" % [game_id]
	#var file_path := folder_path + "/%s" % file_name
	#
	#print("Dir")
	#if not DirAccess.dir_exists_absolute(folder_path):
		#DirAccess.make_dir_recursive_absolute(folder_path)
	#print("file")
	#if not FileAccess.file_exists(file_path):
		#if url == "":
			#print("url is empty: ", game_id, " ", file_name)
			#return { "error": CacheError.NO_URL, "data": null }
		#else:
			#print("Request")
			#var request := await HttpMan.request_file(url, file_name, false, folder_path)
			#if request["error"] != HttpMan.NovaError.SUCESS:
				#push_warning("Failed to download ", file_path, " from url ", url)
				#return { "error": CacheError.DOWNLOAD_FAIL, "data": null }
	#
	#return { "error": CacheError.SUCESS, "data": file_path }
