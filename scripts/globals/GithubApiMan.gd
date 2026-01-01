extends Node

const TAGS_URL = "https://api.github.com/repos/REPO/tags" # REPO is for example Ksawex4/Block-Jumper
const RELEASE_URL = "https://api.github.com/repos/REPO/releases/tags/TAG"
var Api_key: String = ""

func _ready() -> void:
	var data := SaveMan.get_data_from_file("config.nova")
	GithubApiMan.Api_key = data.get("api_key", "")
	ZipMan.Remove_after_install = data.get("remove_after_install", true)


## repository has to be Author/Repository for example "Ksawex4/Block-Jumper
func get_repo_tags(repository: String, game_id: String, recache: bool=false) -> Array:
	var url := TAGS_URL.replace("REPO", repository)
	var response := await CacheMan.get_tags(game_id, url, recache)
	
	if response["error"] != HttpMan.NovaError.SUCESS:
		print("request_file failed ", response["error"])
		return []
	
	if not response["data"] is Array:
		return []
	
	var tags := []
	for x in response["data"]:
		var tag = x.get("name")
		if tag:
			tags.append(tag)
	return tags


func get_repo_version(repository: String, game_id: String, version: String, recache: bool=false) -> Dictionary:
	var url := RELEASE_URL.replace("REPO", repository).replace("TAG", version)
	#var response := await HttpMan.request(url, true)
	var response := await CacheMan.get_release(game_id, version, url, recache)
	
	if response["error"] != HttpMan.NovaError.SUCESS:
		print("request_file failed ", response["error"])
	
	return response


## return an empty string if failed, else returns the path of the downloaded file for the game
func download_game(url: String, file_name: String, save_file_path: String = "user://downloads/") -> String:
	print("download begin")
	var downloaded_file_path := save_file_path + "/" + file_name
	
	var response = await HttpMan.request_file(url, file_name, true, save_file_path)
	
	if response["error"] != HttpMan.NovaError.SUCESS:
		print("request_file failed ", response["error"])
		return ""
	
	var file_path = response.get("data")
	print(file_path, " ", downloaded_file_path, " ", file_path == downloaded_file_path, " ", response["error"])
	print(FileAccess.file_exists(file_path))
	
	print("download finish")
	return downloaded_file_path
