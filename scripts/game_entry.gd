extends Button

@onready var game_icon: TextureRect = $Icon
@onready var game_name: Label = $Name
var Game_id: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(game_icon.size.x + 20 + game_name.size.x, game_icon.size.y)
	size = custom_minimum_size


func update_game(new_game_id: String) -> void:
	Game_id = new_game_id
	if Game_id:
		var game_data = GamesMan.Games.get(Game_id)
		if game_data is Dictionary and game_data:
			game_name.text = game_data["name"]
	
	await get_tree().physics_frame
	custom_minimum_size = Vector2(game_icon.size.x + 20 + game_name.size.x, game_icon.size.y)
	size = custom_minimum_size
