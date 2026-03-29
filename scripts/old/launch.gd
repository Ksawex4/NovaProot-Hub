extends Button

enum States {
	LAUNCH,
	DOWNLOAD,
	WAITING
}
@onready var uninstall: Button = $"../Uninstall"
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
	if uninstall:
		uninstall.update_state(game_id, version, os)


func on_pressed(game_id: String, version: String, game_release: Dictionary, os: String, update_uninstall: bool=false) -> void:
	match State:
		States.LAUNCH:
			var executable_path: String = GamesMan.get_game_executable_path(game_id, version, os)
			
			match OS.get_name():
				"Android":
					print("Currently not avaible")
				"Windows":
					OS.create_process(executable_path, [])
				"Linux":
					if os == "Linux":
						print(executable_path)
						OS.create_process(executable_path, [])
			
		States.DOWNLOAD:
			State = States.WAITING
			text = "Wait"
			Os = os
			await FileMan.download_game(game_id, version, game_release, os)
			update_state(game_id, version, Os)
			if update_uninstall and uninstall:
				uninstall.update_state(game_id, version, os)
