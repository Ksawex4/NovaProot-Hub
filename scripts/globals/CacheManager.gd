extends Node

const CACHE_DIR = "user://cache"
var file_refresh_age := 3600
enum CacheError {
	SUCESS,
	NO_URL,
	DOWNLOAD_FAIL,
	FILE_DOESNT_EXIST,
	PARSE_ERROR,
	READ_FAIL,
}

var RefreshCacheTimer := Timer.new()
signal UpdateIcon(game_id: String, icon: Texture2D)
signal UpdateGames()
signal UpdateTags(game_id: String, tags: PackedStringArray)
signal UpdateVersion(game_id: String, version: String)

func _ready() -> void:
	add_child(RefreshCacheTimer)
	_cache_refresh_check.call_deferred()
	RefreshCacheTimer.start(300)
	RefreshCacheTimer.timeout.connect(_cache_refresh_check)


func clear_all_cache() -> void:
	if DirAccess.dir_exists_absolute(CACHE_DIR):
		var files := get_all_files(CACHE_DIR)
		var directories := get_all_files(CACHE_DIR, PackedStringArray([]), true)
		for file in files:
			DirAccess.remove_absolute(file)
		for dir in directories:
			DirAccess.remove_absolute(dir)
		
		DirAccess.remove_absolute(CACHE_DIR)


func _cache_refresh_check() -> void:
	RefreshCacheTimer.start(300)
	print("rechaching")
	recache_files()
	print("rechache finished")


func recache_files(force_recache: bool=false) -> void:
	var files_to_refresh := get_all_files(CACHE_DIR)
	for file_path in files_to_refresh:
		var file_age: int = round(Time.get_unix_time_from_system() - FileAccess.get_modified_time(file_path))
		#print(file_path, " date_time: ", Time.get_datetime_dict_from_unix_time(file_age), " unix: ", int(file_age))
		if file_age > file_refresh_age or force_recache:
			var file_name := file_path.get_file()
			var game_id := file_path.replace(CACHE_DIR + "/", "").split("/")[0]
			match file_name:
				"games.json":
					print(file_path, " age: %s" % file_age) # This works
					var new_games := await get_games(true)
					if new_games["error"] != OK:
						print("Failed to recache games")
						continue
					GamesMan.Games = new_games["data"]
					UpdateGames.emit()
				"tags.json":
					print(file_path, " age: %s" % file_age)
					var new_tags := await GithubApiMan.get_repo_tags(GamesMan.Games[game_id]["repo"], game_id, true)
					UpdateTags.emit(game_id, PackedStringArray(new_tags))
				"icon.png":
					print(file_path, " age: %s" % file_age) # this works
					var new_icon := await get_icon(game_id, "icon.png", "", true)
					UpdateIcon.emit(game_id, new_icon)
				_:
					print(file_path, " age: %s" % file_age)
					
					if file_name.begins_with("v"):
						GithubApiMan.get_repo_version(GamesMan.Games[game_id]["repo"], game_id, file_name.get_basename(), true)
						UpdateVersion.emit(game_id, file_name.get_basename(), GamesMan.Games[game_id]["repo"])
					else:
						print("Don't know what to do with this cache file: ", file_path)


func get_all_files(path: String, files: PackedStringArray = PackedStringArray([]), get_dirs: bool=false) -> PackedStringArray:
	var dir := DirAccess.open(path)
	if DirAccess.get_open_error() == OK:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir() and not get_dirs:
				files = get_all_files(dir.get_current_dir() + "/%s" % file_name, files)
			else:
				if get_dirs and dir.current_is_dir() or not get_dirs and not dir.current_is_dir():
					files.append(dir.get_current_dir()+ "/%s" % file_name)
			file_name = dir.get_next()
	else:
		print("Failed to open dir at ", path)
	
	return files


func get_icon(game_id: String, file_name: String="icon.png", url: String="", recache: bool=false) -> Texture2D:
	if url == "":
		url = GamesMan.Games.get(game_id)["icon"]
	var request := await _request_icon(game_id, file_name, url, recache)
	if request["error"] != CacheError.SUCESS:
		push_warning("Failed to get icon %s" % [url])
		return load("res://icon.svg")
	
	var image = Image.load_from_file(request["data"])
	var texture = ImageTexture.create_from_image(image)
	if texture:
		return texture
	else:
		push_warning("Texture file is not valid! Deleting ", request["data"])
		DirAccess.remove_absolute(request["data"])
		await _request_icon(game_id, file_name, url)
	
	return load("res://icon.svg")


func _request_icon(game_id: String, file_name: String, url: String, recache: bool=false) -> Dictionary:
	var folder_path := CACHE_DIR + "/%s" % game_id
	var file_path := folder_path + "/%s" % file_name
	
	if not DirAccess.dir_exists_absolute(folder_path):
		DirAccess.make_dir_recursive_absolute(folder_path)
	
	if FileAccess.file_exists(file_path) and not recache:
		return {"error": CacheError.SUCESS, "data": file_path}
	
	var request := await HttpMan.request_file(url, file_name, false, folder_path)
	
	if request["error"] != HttpMan.NovaError.SUCESS:
		print("Failed to download icon, url: ", url, " error: ", request["error"])
		return request
	
	return { "error": CacheError.SUCESS, "data": file_path }


func get_games(recache: bool=false) -> Dictionary:
	var url := "https://github.com/Ksawex4/NovaProot-Hub/raw/refs/heads/main/data/games.json"
	var request := await _request_games("games.json", url, recache)
	if request["error"] != CacheError.SUCESS:
		print("Failed to get games, %s" % url)
		return request
	var parse = parse_json(request.get("data"))
	return parse


func _request_games(file_name: String, url: String, recache: bool=false) -> Dictionary:
	var file_path := CACHE_DIR + "/%s" % file_name
	
	if not DirAccess.dir_exists_absolute(CACHE_DIR):
		DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	
	if FileAccess.file_exists(file_path) and not recache:
		return {"error": CacheError.SUCESS, "data": file_path}
	
	var request := await HttpMan.request_file(url, file_name, true, CACHE_DIR)
	
	if request["error"] != HttpMan.NovaError.SUCESS:
		print("Failed to download games, url: ", url, " error: ", request["error"])
		return request
	
	return {"error": CacheError.SUCESS, "data": file_path}


func get_tags(game_id: String, url: String, recache: bool=false) -> Dictionary:
	var request := await _request_tags(game_id, url, "tags.json", recache)
	if request["error"] != CacheError.SUCESS:
		return request
	
	var parse = parse_json(request.get("data"))
	
	return parse


func _request_tags(game_id: String, url: String, file_name: String="tags.json", recache: bool=false) -> Dictionary:
	var folder_path := CACHE_DIR + "/%s" % game_id
	var file_path := folder_path + "/%s" % file_name
	
	if not DirAccess.dir_exists_absolute(folder_path):
		DirAccess.make_dir_recursive_absolute(folder_path)
	
	if FileAccess.file_exists(file_path) and not recache:
		return { "error": CacheError.SUCESS, "data": file_path }
	
	
	var request := await HttpMan.request_file(url, file_name, true, folder_path)
	
	if request["error"] != CacheError.SUCESS:
		print("Failed to download tags for %s error: %s url: %s" % [game_id, request["error"], url])
		return request
	
	return { "error": CacheError.SUCESS, "data": request["data"] }


func get_release(game_id: String, version: String, url: String, recache: bool=false) -> Dictionary:
	var request := await _request_release(game_id, version, url, recache)
	if request["error"] != CacheError.SUCESS:
		return {"error": request["error"], "data": {}}
	var parse := parse_json(request["data"])
	
	return {"error": CacheError.SUCESS, "data": parse}


func _request_release(game_id: String, version: String, url: String, recache: bool=false) -> Dictionary:
	var folder_path := CACHE_DIR + "/%s" % game_id
	var file_name := "%s.json" % version
	var file_path := folder_path + "/%s" % file_name
	
	if not DirAccess.dir_exists_absolute(folder_path):
		DirAccess.make_dir_recursive_absolute(folder_path)
	
	if FileAccess.file_exists(file_path) and not recache:
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
	
	var file2 := FileAccess.open(file_path, FileAccess.WRITE)
	file2.store_string(JSON.stringify(request["data"]))
	file2.close()
	
	return { "error": CacheError.SUCESS, "data": file_path }


func parse_json(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_warning(file_path, " doesn't exist!")
		return { "error": CacheError.FILE_DOESNT_EXIST, "data": null }
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_warning("Failed to read file ", file_path, " got open error ", FileAccess.get_open_error())
	
	var parsed_file_data = JSON.parse_string(file.get_as_text())
	
	return {"error": CacheError.SUCESS, "data": parsed_file_data}
