extends Button

enum States {
	LAUNCH,
	DOWNLOAD
}
var State: States = States.DOWNLOAD


func update_state(game_id: String, version: String) -> void:
	if FileMan.game_version_exists(game_id, version):
		State =  States.LAUNCH
		text = "Launch"
	else:
		State = States.DOWNLOAD
		text = "Download"


func on_pressed(game_id: String, version: String, game_release: Dictionary, os: String) -> void:
	match State:
		States.LAUNCH:
			pass
		States.DOWNLOAD:
			FileMan.download_game(game_id, version, game_release, os)
