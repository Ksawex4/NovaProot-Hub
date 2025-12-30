extends Node
# This scripts gets data for the games from the repo
# getting certain release string: "/releases/tags/%s" % "v0.1.0"

var Http_requester := HTTPRequest.new()
var Games: Dictionary = {}
signal UpdateGames()


func _ready() -> void:
	add_child(Http_requester)
	Http_requester.request_completed.connect(self._request_complete)
	var headers := [
		"Authorization: %s" % GithubApiMan.Api_key, 
		"User-Agent: NovaProot-Hub",
	]
	var err := Http_requester.request("http://localhost:12345/games.json", headers)
	if err != OK:
		print("error with http request: ", err)


func _request_complete(result, response_code, _headers, body) -> void:
	if result != OK:
		print("result is ", result)
		load_from_cache()
		return
	if response_code != 200:
		print("response code ", response_code)
		load_from_cache()
		return
	
	var json = JSON.new()
	var err := json.parse(body.get_string_from_utf8())
	if err != OK:
		print("Failed to parse: ", err)
		load_from_cache()
		return
	var response = json.get_data()
	
	if response is Dictionary:
		Games = response
		SaveMan.save_file("games.json", Games)
		UpdateGames.emit()
	else:
		load_from_cache()


func load_from_cache() -> void:
	Games = SaveMan.get_data_from_file("games.json")
	UpdateGames.emit()
