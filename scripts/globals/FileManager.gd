extends Node


func game_version_exists(game_id: String, version: String) -> bool:
	return DirAccess.dir_exists_absolute("user://games/%s/%s" % [game_id, version])


func download_game(game_id: String, version: String, game_release: Dictionary, os: String) -> void:
	#var game = GamesMan.Games.get(game_id)
	print(game_release)
	var assets: Dictionary = game_release.get("assets", {})
	var game_url: String = assets.get(os, "")
	if game_url == "":
		return
	var _install_path := "user://games/%s/%s" % [game_id, version]
	var _download_path := await GithubApiMan.download_game(game_url)
	
	
