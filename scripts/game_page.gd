extends VBoxContainer

@onready var icon: TextureRect = $Icon
@onready var game_name: Label = $Middle/GameName
@onready var versions: OptionButton = $Middle/Versions
@onready var launch: Button = $Middle/Launch
@onready var os: OptionButton = $Middle/Os
@onready var changelog: RichTextLabel = $Changelog
var Game_version: Dictionary = {}
var Game_id: String = ""


func _ready() -> void:
	CacheMan.UpdateTags.connect(_update_tags)
	CacheMan.UpdateVersion.connect(_update_version)


func update_shown_game(game_id: String, game_icon: Texture2D) -> void:
	versions.clear()
	var game = GamesMan.Games.get(game_id)
	Game_id = game_id
	if game:
		game_name.text = game.get("name", "Nonexistent Name")
		var game_versions := await GithubApiMan.get_repo_tags(game.get("repo", ""), game_id)
		for version in game_versions:
			versions.add_item(version)
		_on_versions_item_selected(0)
	if game_icon:
		icon.texture = game_icon


func _on_versions_item_selected(index: int) -> void:
	var version := versions.get_item_text(index)
	var game = GamesMan.Games.get(Game_id)
	var requestere := await GithubApiMan.get_repo_version(game.get("repo", ""), Game_id, version)
	Game_version = requestere["data"]["data"]
	os.clear()
	var asset_keys: Array = Game_version.get("assets", {}).keys()
	for asset in asset_keys:
		os.add_item(asset)
	var asset_index := asset_keys.find(OS.get_name(), 0)
	if asset_index != -1:
		os.select(asset_index)
	launch.update_state(Game_id, version, os.get_item_text(os.selected))
	changelog.text = Game_version.get("name", "fail") + "\n" + Game_version.get("body", "fail") 


func _on_os_item_selected(index: int) -> void:
	launch.update_state(Game_id, "", os.get_item_text(index))


func _on_launch_pressed() -> void:
	var version := versions.get_item_text(versions.selected)
	var Os := os.get_item_text(os.selected)
	launch.on_pressed(Game_id, version, Game_version, Os)


func _update_tags(game_id: String, tags: PackedStringArray) -> void:
	if game_id == Game_id:
		var game: Dictionary = GamesMan.Games.get(game_id)
		if game:
			game_name.text = game.get("name", "Nonexistent Name")
			var game_versions := await GithubApiMan.get_repo_tags(game.get("repo", ""), game_id)
			for version in game_versions:
				versions.add_item(version)
			versions.select(0)
			_on_versions_item_selected(0)


func _update_version(game_id: String, version: String) -> void:
	if game_id == Game_id and version == versions.get_item_text(versions.selected):
		Game_version = await GithubApiMan.get_repo_version(GamesMan.Games.get("game", ""), Game_id, version)
		changelog.text = Game_version.get("name", "fail") + "\n" + Game_version.get("body", "fail")
