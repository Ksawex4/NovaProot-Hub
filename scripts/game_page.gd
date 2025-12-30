extends VBoxContainer

@onready var icon: TextureRect = $Icon
@onready var game_name: Label = $Middle/GameName
@onready var versions: OptionButton = $Middle/Versions


func update_shown_game(game_id: String, game_icon: Texture2D) -> void:
	versions.clear()
	var game = GamesMan.Games.get(game_id)
	if game:
		game_name.text = game.get("name", "Nonexistent Name")
		var game_versions := await GithubApiMan.get_repo_tags(game.get("repo", ""))
		for version in game_versions:
			versions.add_item(version)
	if game_icon:
		icon.texture = game_icon
