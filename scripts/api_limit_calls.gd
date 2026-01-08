extends Label

func _process(_delta: float) -> void:
	text = "Api calls remaining: %s/%s" % [GithubApiMan.Api_calls_remaining, GithubApiMan.Api_calls_limit]
	$ResetTime.text = "Resets at: %s" % [GithubApiMan.Api_calls_reset]
