extends TabBar

func _ready() -> void:
	$GithubApiKey.text = GithubApiMan.Api_key
	$RemoveAfterInstall.set_pressed_no_signal(ZipMan.Remove_after_install)

func _on_github_api_key_text_submitted(new_text: String) -> void:
	GithubApiMan.Api_key = new_text
	SaveMan.save_file("config.nova", { "api_key": GithubApiMan.Api_key, "remove_after_install": ZipMan.Remove_after_install })


func _on_remove_after_install_toggled(toggled_on: bool) -> void:
	ZipMan.Remove_after_install = toggled_on
