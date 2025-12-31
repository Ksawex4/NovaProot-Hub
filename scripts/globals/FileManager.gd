extends Node


func game_version_exists(game_id: String, version: String, os: String) -> bool:
	return DirAccess.dir_exists_absolute("user://games/%s/%s-%s" % [game_id, version, os])


func download_game(game_id: String, version: String, game_release: Dictionary, os: String) -> bool:
	print(game_release)
	print("game-id: %s\nversion: %s\ngame_release: %s\nos: %s" % [game_id, version, game_release, os])
	var assets: Dictionary = game_release.get("assets", {})
	var game_url: String = assets.get(os, "")
	if game_url == "":
		return false
	var install_path := "user://games/%s/%s-%s" % [game_id, version, os]
	var extension = ".zip"
	if os == "Android":
		extension = ".apk"
	var download_path := await GithubApiMan.download_game(game_url, "%s-%s%s" % [game_id, version, extension] ,"user://downloads")
	
	if not FileAccess.file_exists(download_path):
		print("File doesn't exist!!")
		return false
	
	if game_version_exists(game_id, version, os):
		DirAccess.remove_absolute("user://games/%s/%s-%s" % [game_id, version, os])
	
	if os != "Android":
		ZipMan.unzip_to_directory(download_path, install_path)
	
	if OS.get_name() == "Linux":
		var dir := DirAccess.open(install_path)
		var files := dir.get_files()
		for file in files:
			var lower_file = file.to_lower()
			if lower_file.ends_with(".x86_64") or lower_file.ends_with(".appimage"):
				var full_path := ProjectSettings.globalize_path(dir.get_current_dir())
				OS.create_process("chmod", ["+x", full_path + "/" + file])
	
	return true
