extends Node

enum NovaError {
	SUCESS,
	WRONG_RESPONSE,
	PARSE_ERROR,
	DOWNLOAD_FAIL,
	STATUS_NOT_DISCONNECTED,
}
@onready var Http_requester := HTTPRequest.new()

func _ready() -> void:
	add_child(Http_requester)

## [0] is NovaError, [1] is return
func old_request(url: String, include_github_api: bool = true, download_to_file: bool=false, download_path: String="user://") -> Dictionary:
	# Headers
	var headers := []
	if include_github_api:
		headers = [
			"Authorization: %s" % GithubApiMan.Api_key, 
			"User-Agent: NovaProot-Hub",
		]
	
	# Checking if download path exists + file_path variable
	if not DirAccess.dir_exists_absolute(download_path):
		DirAccess.make_dir_recursive_absolute(download_path)
	var download_file_path := download_path + url.get_file()
	
	# reseting download_file path
	Http_requester.download_file = ""
	if download_file_path:
		Http_requester.download_file = download_file_path
	
	Http_requester.request(url, headers)
	
	var result = await Http_requester.request_completed
	if result[0] != OK or result[1] != 200:
		print("Failed, result: %s,result_code: %s" % [result[0], result[1]])
		return {"error": NovaError.WRONG_RESPONSE, "data": null}
	
	
	if download_to_file:
		return {"error": NovaError.SUCESS, "data": download_file_path}
	
	# parsing
	var json = JSON.new()
	var err = json.parse(result[3].get_string_from_utf8())
	if err != OK:
		print("Failed to parse: ", err)
		return {"error": NovaError.PARSE_ERROR, "data": null}
	var response = json.get_data()
	
	return {"error": NovaError.SUCESS, "data": response}


func request(url: String, include_github_api: bool = false) -> Dictionary:
	if Http_requester.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return {"error": NovaError.STATUS_NOT_DISCONNECTED, "data": null}
	var headers := PackedStringArray([])
	if include_github_api:
		headers = PackedStringArray([
		"Accept: application/vnd.github.v3+json",
		"Authorization: token " + GithubApiMan.Api_key
	])
	
	print("request url: ",url)
	Http_requester.download_file = ""
	Http_requester.request(url, headers)
	var result = await Http_requester.request_completed
	
	if result[0] != OK or result[1] != 200:
		print("Failed, result: %s,result_code: %s" % [result[0], result[1]])
		return {"error": NovaError.WRONG_RESPONSE, "data": null}
	
	var json = JSON.new()
	var err = json.parse(result[3].get_string_from_utf8())
	if err != OK:
		print("Failed to parse: ", err)
		return {"error": NovaError.PARSE_ERROR, "data": null}
	var response = json.get_data()
	
	return {"error": NovaError.SUCESS, "data": response}


func request_file(url: String, file_name: String, include_github_api: bool = false, download_file_path: String="user://downloads") -> Dictionary:
	var headers := PackedStringArray([])
	if include_github_api:
		headers = PackedStringArray([
		"Accept: application/vnd.github.v3+json",
		"Authorization: token " + GithubApiMan.Api_key
	])
	
	if not DirAccess.dir_exists_absolute(download_file_path):
		DirAccess.make_dir_recursive_absolute(download_file_path)
	var file_save_path = download_file_path + "/" +file_name
	
	print("request_file url: ",url)
	Http_requester.download_file = download_file_path + "/" + file_name
	Http_requester.request(url, headers)
	var result = await Http_requester.request_completed
	
	
	
	if result[0] != OK or result[1] != 200:
		print("Failed, result: %s,result_code: %s" % [result[0], result[1]])
		return {"error": NovaError.WRONG_RESPONSE, "data": null}
	
	if not FileAccess.file_exists(file_save_path):
		print("Downloaded file, missing after write: ", file_save_path)
	
	return {"error": NovaError.SUCESS, "data": file_save_path}
