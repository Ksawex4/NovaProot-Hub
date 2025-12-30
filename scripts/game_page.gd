extends VBoxContainer

@onready var icon: TextureRect = $Icon
@onready var game_name: Label = $Middle/GameName
@onready var versions: OptionButton = $Middle/Versions
@onready var launch: Button = $Middle/Launch
@onready var os: OptionButton = $Middle/Os
@onready var changelog: RichTextLabel = $Changelog
var Game_version: Dictionary = {}
var Game_id: String = ""


func update_shown_game(game_id: String, game_icon: Texture2D) -> void:
	versions.clear()
	var game = GamesMan.Games.get(game_id)
	Game_id = game_id
	if game:
		game_name.text = game.get("name", "Nonexistent Name")
		var game_versions := await GithubApiMan.get_repo_tags(game.get("repo", ""))
		for version in game_versions:
			versions.add_item(version)
		_on_versions_item_selected(0)
	if game_icon:
		icon.texture = game_icon


func _on_versions_item_selected(index: int) -> void:
	var version := versions.get_item_text(index)
	launch.update_state(Game_id, version)
	var game = GamesMan.Games.get(Game_id)
	Game_version = await GithubApiMan.get_repo_version(game.get("repo", ""), version)
	changelog.text = Game_version.get("name", "fail") + "\n" + Game_version.get("body", "fail") 


func _on_launch_pressed() -> void:
	var version := versions.get_item_text(versions.selected)
	launch.on_pressed(Game_id, version, Game_version, "Linux")
