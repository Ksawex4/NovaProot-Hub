extends Node
# This scripts gets data for the games from the repo
# getting certain release string: "/releases/tags/%s" % "v0.1.0"

var Games: Dictionary = {}
signal UpdateGames()


func _ready() -> void:
	print("hi")
	var response = await CacheMan.get_games()
	print("got response")
	var err = response["error"]
	if err != OK:
		print("error with CacheMan request: ", err)
	
	if response["data"] is Dictionary:
		Games = response["data"]
		print("response set as Games")
		UpdateGames.emit()
	else:
		print("failed to get games.json from cache and download")


func get_game_executable_path(game_id: String, version: String, os: String) -> String:
	var path = "user://games/%s/%s-%s" % [game_id, version, os]
	path = ProjectSettings.globalize_path(path) + "/"
	var dir := DirAccess.open(path)
	var files := dir.get_files()
	for file in files:
		var file_lower := file.to_lower()
		if os == "Linux":
			if file_lower.ends_with("x86_64") or file_lower.ends_with(".appimage"):
				path += file
				break
		elif os == "Windows":
			if file_lower.ends_with(".exe"):
				path += file
				break
	print(path)
	return path
