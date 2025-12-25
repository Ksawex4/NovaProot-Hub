extends Node
# This scripts gets data for the games from the repo

var Http_requester := HTTPRequest.new()
var Games: Dictionary = {}
signal UpdateGames()

"/releases/tag/%s"
func _ready() -> void:
	add_child(Http_requester)
	Http_requester.request_completed.connect(self._request_complete)
	var err := Http_requester.request("http://localhost:12345/games.json")
	print("Fuck")
	if err != OK:
		print("error with http request: ", err)


func _request_complete(_result, _response_code, _headers, body) -> void:
	print("got file")
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	print(response)
	Games = response
	UpdateGames.emit()
