extends Node

const TAGS_URL = "https://api.github.com/repos/REPO/tags" # REPO is for example Ksawex4/Block-Jumper
const RELEASE_URL = "https://api.github.com/repos/REPO/releases/tags/TAG"
var Http_requester := HTTPRequest.new()

func _ready() -> void:
	add_child(Http_requester)

# repository has to be Author/Repository for example "Ksawex4/Block-Jumper
func get_repo_tags(repository: String) -> Array:
	Http_requester.request(TAGS_URL.replace("REPO", repository))
	var result: Array = await Http_requester.request_completed
	var body = result[3]
	if result[0] != OK:
		print("result is ", result)
		return []
	if result[1] != 200:
		print("response code ", result[1])
		return []
	var json = JSON.new()
	var err := json.parse(body.get_string_from_utf8())
	if err != OK:
		print("Failed to parse: ", err)
		return []
	var response = json.get_data()
	
	var tags: Array[String] = []
	for x in response:
		var tag = x.get("name")
		if tag:
			tags.append(tag)
	return tags


func get_repo_version(repository: String, version: String) -> Dictionary:
	Http_requester.request(RELEASE_URL.replace("REPO", repository).replace("TAG", version))
	
	var result: Array = await Http_requester.request_completed
	var body = result[3]
	if result[0] != OK:
		print("result is ", result)
		return {}
	if result[1] != 200:
		print("response code ", result[1])
		return {}
	var json = JSON.new()
	var err := json.parse(body.get_string_from_utf8())
	if err != OK:
		print("Failed to parse: ", err)
		return {}
	var response = json.get_data()
	
	var data := {}
	data.set("name", response.get("name", "Failed to get name"))
	data.set("body", response.get("body", "Failed to get body"))
	var game_downloads: Dictionary[String, String] = {}
	for asset in response.get("assets"):
		var asset_name: String = asset.get("name")
		asset_name = asset_name.to_lower()
		var asset_url: String = asset.get("url")
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
	
	return {}


## return an empty string if failed, else returns the path of the downloaded file for the game
func download_game(url: String, save_file_path: String = "user://downloads/") -> String:
	var downloaded_file_path := save_file_path + url.get_file()
	Http_requester.download_file = downloaded_file_path
	Http_requester.request(url)
	var result: Array = await Http_requester.request_completed
	if result[0] != OK:
		print("result is ", result)
		return ""
	if result[1] != 200:
		print("response code ", result[1])
		return ""
	
	if not FileAccess.file_exists(downloaded_file_path):
		push_error("File doesn't exist??")
		return ""
	
	return downloaded_file_path
