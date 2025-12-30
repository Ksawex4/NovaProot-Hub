extends TabBar


func _ready() -> void:
	var data := SaveMan.get_data_from_file("config.nova")
	GithubApiMan.Api_key = data.get("api_key", "")


func _on_github_api_key_text_submitted(new_text: String) -> void:
	GithubApiMan.Api_key = new_text
	SaveMan.save_file("config.nova", { "api_key": GithubApiMan.Api_key })
