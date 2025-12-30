extends Node
# This scripts gets data for the games from the repo
# getting certain release string: "/releases/tags/%s" % "v0.1.0"

var Games: Dictionary = {}
signal UpdateGames()


func _ready() -> void:
	var response = await HttpMan.request("http://localhost:12345/games.json", true, false)
	var err = response["error"]
	if err != OK:
		print("error with http request: ", err)
	
	if response["data"] is Dictionary:
		Games = response["data"]
		SaveMan.save_file("games.json", Games)
		UpdateGames.emit()
	else:
		load_from_cache()


func load_from_cache() -> void:
	Games = SaveMan.get_data_from_file("games.json")
	UpdateGames.emit()
