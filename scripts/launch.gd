extends Button

enum States {
	LAUNCH,
	DOWNLOAD,
	WAITING
}
var State: States = States.WAITING
var Os := ""
var Version = ""

func update_state(game_id: String, version: String, os: String) -> void:
	Os = os
	Version = version if version != "" else Version
	if FileMan.game_version_exists(game_id, Version, Os):
		State =  States.LAUNCH
		text = "Launch"
	else:
		State = States.DOWNLOAD
		text = "Download"


func on_pressed(game_id: String, version: String, game_release: Dictionary, os: String) -> void:
	match State:
		States.LAUNCH:
			OS.create_process(GamesMan.get_game_executable_path(game_id, version, os), [])
		States.DOWNLOAD:
			State = States.WAITING
			text = "Wait"
			Os = os
			await FileMan.download_game(game_id, version, game_release, os)
			update_state(game_id, version, Os)
