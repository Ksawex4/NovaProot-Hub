extends VBoxContainer

const GAME_ENTRY = preload("uid://dfkjh6coao8y6")
@onready var game_page: VBoxContainer = $"../GamePage"


func _ready() -> void:
	GamesMan.UpdateGames.connect(self._update_list)


func _update_list() -> void:
	for x in get_children():
		x.queue_free()
	
	for game in GamesMan.Games.keys():
		var game_entry = GAME_ENTRY.instantiate()
		add_child(game_entry)
		game_entry.update_game(game)
