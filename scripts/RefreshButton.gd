extends Button


func _on_pressed() -> void:
	if text == "Refresh All Cache":
		text = "Refreshing"
		await CacheMan.recache_files(true)
		text = "Done"
		await get_tree().create_timer(2).timeout
		text = "Refresh All Cache"
