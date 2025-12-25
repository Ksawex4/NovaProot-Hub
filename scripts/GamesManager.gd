extends Node
# This scripts gets data for the games from the repo
# getting certain release string: "/releases/tag/%s" % "v" + "0.1.0"

var Http_requester := HTTPRequest.new()
var Games: Dictionary = {}
signal UpdateGames()


func _ready() -> void:
	add_child(Http_requester)
	Http_requester.request_completed.connect(self._request_complete)
	var err := Http_requester.request("http://localhost:12345/games.json")
	if err != OK:
		print("error with http request: ", err)


func _request_complete(result, response_code, _headers, body) -> void:
	if result != OK:
		print("result is ", result)
		return
	if response_code != 200:
		print("response code ", response_code)
		return
	var json = JSON.new()
	var err := json.parse(body.get_string_from_utf8())
	if err != OK:
		print("Failed to parse: ", err)
		return
	var response = json.get_data()
	
	if response is Dictionary:
		Games = response
		UpdateGames.emit()
