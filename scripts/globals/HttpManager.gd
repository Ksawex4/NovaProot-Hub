extends Node

enum NovaError {
	SUCESS,
	WRONG_RESPONSE,
	PARSE_ERROR,
	DOWNLOAD_FAIL,
	EMPTY_URL,
}
func _ready() -> void:
	print(Time.get_time_zone_from_system())


func request(url: String, include_github_api: bool = false) -> Dictionary:
	if url == "":
		print("Url is empty")
		return { "error": NovaError.EMPTY_URL, "data": null }
	
	# Adding the HTTPRequest node and setting it up
	var Http_requester := HTTPRequest.new()
	add_child(Http_requester)
	Http_requester.use_threads = true
	Http_requester.download_file = ""
	
	var headers := PackedStringArray(["User-Agent: NovaProotHub/beta1", "Accept: application/vnd.github.v3+json"])
	if include_github_api:
		headers.append_array(PackedStringArray([
		"Authorization: token " + GithubApiMan.Api_key
		]))
	
	# requesting and freeing node after request
	print("request url: ", url)
	Http_requester.request(url, headers)
	var result = await Http_requester.request_completed
	Http_requester.queue_free()
	
	if result[0] != OK or result[1] != 200:
		print("Failed, result: %s, result_code: %s" % [result[0], result[1]])
		return {"error": NovaError.WRONG_RESPONSE, "data": null}
	
	# Parsing
	var json = JSON.new()
	var err = json.parse(result[3].get_string_from_utf8())
	
	print(result[2])
	if err != OK:
		print("Failed to parse: ", err)
		return {"error": NovaError.PARSE_ERROR, "data": null}
	var response = json.get_data()
	
	return {"error": NovaError.SUCESS, "data": response}


func request_file(url: String, file_name: String, include_github_api: bool = false, download_file_path: String="user://downloads") -> Dictionary:
	if url == "":
		print("Url is empty")
		return { "error": NovaError.EMPTY_URL, "data": null }
	
	# Adding the HTTPRequest node
	var Http_requester := HTTPRequest.new()
	add_child(Http_requester)
	Http_requester.use_threads = true
	Http_requester.download_file = download_file_path + "/" + file_name
	
	var headers := PackedStringArray(["User-Agent: NovaProotHub/beta1", "Accept: application/vnd.github.v3+json"])
	if include_github_api and not GithubApiMan.Api_key.is_empty():
		headers.append_array(PackedStringArray([
		"Authorization: token " + GithubApiMan.Api_key
		]))
	
	# Creating directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(download_file_path):
		DirAccess.make_dir_recursive_absolute(download_file_path)
	var file_save_path = download_file_path + "/" +file_name
	
	# requesting and freeing node after request
	print("request_file url: ", url)
	Http_requester.request(url, headers)
	var result = await Http_requester.request_completed
	Http_requester.queue_free()
	
	var result_headers := _convert_header_to_dict(result[2])
	if result_headers.has("X-RateLimit-Remaining"):
		GithubApiMan.Api_calls_remaining = int(result_headers.get("X-RateLimit-Remaining", GithubApiMan.Api_calls_remaining))
	if result_headers.has("X-RateLimit-Reset"):
		GithubApiMan.Api_calls_reset = int(result_headers.get("X-RateLimit-Reset", GithubApiMan.Api_calls_reset))
	if result_headers.has("X-RateLimit-Limit"):
		GithubApiMan.Api_calls_limit = int(result_headers.get("X-RateLimit-Limit", GithubApiMan.Api_calls_limit)) 
	
	if result[0] != OK or result[1] != 200:
		print("Failed, result: %s,result_code: %s" % [result[0], result[1]])
		return {"error": NovaError.WRONG_RESPONSE, "data": null}
	
	# Checking if file exists after request
	if not FileAccess.file_exists(file_save_path):
		print("Downloaded file, missing after write: ", file_save_path)
		return {"error": NovaError.DOWNLOAD_FAIL, "data": null}
	
	return {"error": NovaError.SUCESS, "data": file_save_path}


func _convert_header_to_dict(headers: PackedStringArray) -> Dictionary:
	var dict := {}
	for head in headers:
		var splitted := head.split(":")
		var trimmed := []
		for split in splitted:
			trimmed.append(split.trim_prefix(" ").trim_suffix(" "))
		var key: String = trimmed[0]
		var value
		if trimmed.size() > 2:
			value = []
			for valuer in trimmed:
				if valuer != key:
					value.append("valuer")
		else:
			value = trimmed[1]
		dict.set(key, value)
	
	print(dict)
	return dict
