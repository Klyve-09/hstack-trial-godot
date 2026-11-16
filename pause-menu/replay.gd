extends SceneTree
# Usage: godot --path <repo> --fixed-fps 60 --script <this file> -- <replay.json> <out_dir>

var spec: Dictionary
var out_dir: String
var frame := 0
var game: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	spec = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	out_dir = args[1]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var packed: PackedScene = load(spec.scene)
	if packed == null:
		push_error("Cannot open scene %s" % spec.scene)
		quit(2)
		return
	root.size = Vector2i(spec.resolution[0], spec.resolution[1])
	game = packed.instantiate()
	root.add_child(game)
	if "random" in game:
		game.random.seed = int(spec.seed)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	frame += 1
	for input in spec.inputs:
		if int(input.frame) == frame:
			var event := InputEventAction.new()
			event.action = input.action
			event.pressed = input.pressed
			Input.parse_input_event(event)
	if frame in spec.captures.map(func(f): return int(f)):
		_capture.call_deferred(frame)
	if frame >= int(spec.end_frame):
		print("replay reached end frame %d, screen=%s" % [frame, game.get("screen")])
		quit(0)


func _capture(at: int) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("%s/frame-%04d.png" % [out_dir, at])
	print("frame %d screen=%s remaining=%.3f focus=%s" % [at, game.get("screen"), game.round_state.remaining, root.gui_get_focus_owner().text if root.gui_get_focus_owner() is Button else "-"])
