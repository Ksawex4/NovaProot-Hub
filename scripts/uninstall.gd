extends Button

enum States {
	NOT_INSTALLED,
	UNINSTALL,
	WAITING,
}
var State: States = States.WAITING
@onready var launch: Button = $"../Launch"
var Game_id := ""
var Version := ""
var Os := ""

func _on_pressed() -> void:
	print("Duck", State)
	if State == 1:
		print("uninstalin")
		State = States.WAITING
		text = "Wait"
		FileMan.remove_game(Game_id, Version, Os)
		update_state(Game_id, Version, Os, true)


func update_state(game_id: String, version: String, os: String, update_launch: bool=false) -> void:
	Game_id = game_id
	Version = version
	Os = os
	if FileMan.game_version_exists(game_id, version, os):
		State = States.UNINSTALL
		text = "Uninstall"
	else:
		State = States.NOT_INSTALLED
		text = "Not installed"
	if update_launch:
		launch.update_state(game_id, version, os)
