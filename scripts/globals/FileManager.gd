extends Node


func _ready() -> void:
	OS.request_permissions()


func game_version_exists(game_id: String, version: String, os: String) -> bool:
	return DirAccess.dir_exists_absolute("user://games/%s/%s-%s" % [game_id, version, os])


func download_game(game_id: String, version: String, game_release: Dictionary, os: String) -> bool:
	print("Starting download for " + game_id + " version: " + version + "\ngame_release: %s\nos: %s" % [game_release, os])
	var assets: Dictionary = game_release.get("assets", {})
	var game_url: String = assets.get(os, "")
	if game_url == "":
		return false
	var install_path := "user://games/%s/%s-%s" % [game_id, version, os]
	var extension = ".zip"
	if os == "Android":
		extension = ".apk"
	var download_path := await GithubApiMan.download_game(game_url, "%s-%s-%s%s" % [game_id, version, os, extension] ,"user://downloads")
	
	if not FileAccess.file_exists(download_path):
		print("File doesn't exist!!")
		return false
	
	if game_version_exists(game_id, version, os):
		DirAccess.remove_absolute("user://games/%s/%s-%s" % [game_id, version, os])
	
	if os != "Android" and OS.get_name() != "Android":
		ZipMan.unzip_to_directory(download_path, install_path)
	else:
		install_apk(download_path)
	
	if OS.get_name() == "Linux":
		var dir := DirAccess.open(install_path)
		var files := dir.get_files()
		for file in files:
			var lower_file = file.to_lower()
			if lower_file.ends_with(".x86_64") or lower_file.ends_with(".appimage"):
				var full_path := ProjectSettings.globalize_path(dir.get_current_dir())
				OS.create_process("chmod", ["+x", full_path.path_join(file)])
	
	print("Finished ", game_id, " ", version)
	return true


func install_apk(download_path: String) -> void:
	if OS.get_name() != "Android":
		push_warning("Not an Android device")
		return
	
	OS.request_permissions()
	if !OS.request_permission("android.permission.MANAGE_EXTERNAL_STORAGE"):
		print("Dont have permissions")
		print(OS.get_granted_permissions())
		return
	
	var file: String = download_path.get_file()
	var downloads_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS).path_join("NovaProotHub")
	var file_path: String = downloads_path.path_join(file)
	
	move_to_downloads(download_path)
	
	OS.shell_show_in_file_manager(file_path, false)


## for moving files from user://downloads to downloads/NovaProotHub
func move_to_downloads(download_path: String) -> void:
	var file: String = download_path.get_file()
	var downloads_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS).path_join("NovaProotHub")
	var file_path: String = downloads_path.path_join(file)
	
	if !DirAccess.dir_exists_absolute(downloads_path):
		DirAccess.make_dir_recursive_absolute(downloads_path)
	
	DirAccess.copy_absolute(download_path, file_path)
	DirAccess.remove_absolute(download_path)


func remove_game(game_id: String, version: String, os: String) -> void:
	var install_path := "user://games/%s/%s-%s" % [game_id, version, os]
	if DirAccess.dir_exists_absolute(install_path):
		var files := CacheMan.get_all_files(install_path)
		for file in files:
			DirAccess.remove_absolute(file)
		DirAccess.remove_absolute(install_path)


func get_version_directory(game_id: String, version: String, os: String) -> String:
	var path := "user://games/%s/%s-%s" % [game_id, version, os]
	if DirAccess.dir_exists_absolute(path):
		return path
	return "user://"
