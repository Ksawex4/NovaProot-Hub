extends Node


func game_version_exists(game_id: String, version: String) -> bool:
	return DirAccess.dir_exists_absolute("user://games/%s/%s" % [game_id, version])


func download_game(game_id: String, version: String, game_release: Dictionary, os: String) -> bool:
	print(game_release)
	print("game-id: %s\nversion: %s\ngame_release: %s\nos: %s" % [game_id, version, game_release, os])
	var assets: Dictionary = game_release.get("assets", {})
	var game_url: String = assets.get(os, "")
	if game_url == "":
		return false
	var install_path := "user://games/%s/%s" % [game_id, version]
	var download_path := await GithubApiMan.download_game(game_url, "%s-%s.zip" % [game_id, version] ,"user://downloads")
	
	if not FileAccess.file_exists(download_path):
		print("File doesn't exist!!")
		return false
	
	if game_version_exists(game_id, version):
		DirAccess.remove_absolute("user://games/%s/%s" % [game_id, version])
	
	ZipMan.unzip_to_directory(download_path, install_path)
	return true
