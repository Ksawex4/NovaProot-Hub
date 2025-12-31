extends Button

@onready var game_icon: TextureRect = $Icon
@onready var Parent: VBoxContainer = $'..'
var Game_id: String = ""
var Http_requester := HTTPRequest.new()


func _ready() -> void:
	Http_requester.request_completed.connect(self._update_icon)
	add_child(Http_requester)
	Http_requester.use_threads = true


func update_game(new_game_id: String) -> void:
	Game_id = new_game_id
	if Game_id:
		var game_data = GamesMan.Games.get(Game_id)
		if game_data is Dictionary and game_data:
			await get_tree().physics_frame
			text = game_data.get("name", "Nonexistent Name")
			var iconer = game_data.get("icon")
			if iconer:
				Http_requester.request(iconer)
			

func _update_icon(result, _response_code, _headers, body) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		push_warning("Image couldn't be downloaded.")
		return

	var image = Image.new()
	if not body:
		return
	var error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("Couldn't load the image.")
	var texture = ImageTexture.create_from_image(image)
	if texture:
		game_icon.texture = texture


func _on_pressed() -> void:
	Parent.game_page.update_shown_game(Game_id, icon)
