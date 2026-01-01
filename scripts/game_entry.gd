extends Button

@onready var game_icon: TextureRect = $Icon
@onready var Parent: VBoxContainer = $'..'
var Game_id: String = ""

func _ready() -> void:
	CacheMan.UpdateIcon.connect(_update_icon)


func update_game(new_game_id: String) -> void:
	Game_id = new_game_id
	if Game_id:
		var game_data = GamesMan.Games.get(Game_id)
		if game_data is Dictionary and game_data:
			await get_tree().physics_frame
			text = game_data.get("name", "Nonexistent Name")
			var iconer = game_data.get("icon")
			if iconer:
				game_icon.texture = await CacheMan.get_icon(Game_id, "icon.png", iconer)


func _on_pressed() -> void:
	Parent.game_page.update_shown_game(Game_id, icon)


func _update_icon(game_id: String, new_icon: Texture2D) -> void:
	if Game_id == game_id:
		$Icon.texture = new_icon
