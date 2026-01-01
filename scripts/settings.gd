extends TabBar

func _ready() -> void:
	$RemoveAfterInstall.set_pressed_no_signal(ZipMan.Remove_after_install)

func _on_github_api_key_text_submitted(new_text: String) -> void:
	GithubApiMan.Api_key = new_text
	$GithubApiKey.text = ""
	SaveMan.save_file("config.nova", { "api_key": GithubApiMan.Api_key, "remove_after_install": ZipMan.Remove_after_install })


func _on_remove_after_install_toggled(toggled_on: bool) -> void:
	ZipMan.Remove_after_install = toggled_on
	SaveMan.save_file("config.nova", { "api_key": GithubApiMan.Api_key, "remove_after_install": ZipMan.Remove_after_install })


func _on_clear_cache_pressed() -> void:
	CacheMan.clear_all_cache()


func _on_show_api_key_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$ShowApiKey/ApiKey.text = GithubApiMan.Api_key
	else:
		$ShowApiKey/ApiKey.text = ""
