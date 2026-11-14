extends RefCounted
## Persists only the best completed round, using Godot's local data directory.

const SAVE_PATH := "user://save.cfg"


static func load_best(path: String = SAVE_PATH) -> int:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return 0
	var value: Variant = config.get_value("scores", "best", 0)
	if typeof(value) != TYPE_INT:
		return 0
	return maxi(0, value)


static func save_best(score: int, path: String = SAVE_PATH) -> Error:
	var config := ConfigFile.new()
	config.set_value("scores", "best", maxi(load_best(path), maxi(0, score)))
	return config.save(path)
