extends Node

const TAGS_URL = "https://api.github.com/repos/REPO/tags" # REPO is for example Ksawex4/Block-Jumper
const RELEASE_URL = "https://api.github.com/repos/REPO/releases/tags/TAG"
var Api_key: String = ""

## repository has to be Author/Repository for example "Ksawex4/Block-Jumper
func get_repo_tags(repository: String) -> Array:
	var url := TAGS_URL.replace("REPO", repository)
	var response := await HttpMan.request(url, true, false)
	
	print(response)
	if not response["data"] is Array:
		return []
	
	var tags := []
	for x in response["data"]:
		var tag = x.get("name")
		if tag:
			tags.append(tag)
	return tags


func get_repo_version(repository: String, version: String) -> Dictionary:
	var url := RELEASE_URL.replace("REPO", repository).replace("TAG", version)
	var responsee := await HttpMan.request(url, true, false)
	var response = responsee["data"] 
	
	if response is Dictionary:
		var data: Dictionary[String, Variant] = {}
		data.set("name", response.get("name"))
		data.set("body", response.get("body"))
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
		
		return data
	return {}


## return an empty string if failed, else returns the path of the downloaded file for the game
func download_game(url: String, save_file_path: String = "user://downloads/") -> String:
	print("download begin")
	var downloaded_file_path := save_file_path + url.get_file()
	
	var file_path = await HttpMan.request(url, true, true, downloaded_file_path)
	print(file_path, " ", downloaded_file_path, " ", file_path == downloaded_file_path)
	
	if not FileAccess.file_exists(downloaded_file_path):
		push_error("Downloaded file, missing after write: ", downloaded_file_path)
		return ""
	
	print("download finish")
	return downloaded_file_path
