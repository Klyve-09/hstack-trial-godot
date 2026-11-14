extends SceneTree

const Rules = preload("res://scripts/round_rules.gd")
const Store = preload("res://scripts/score_store.gd")
const SAVE := "user://score_test.cfg"

var failures := 0
var checks := 0


func _initialize() -> void:
	_test_rules()
	_test_storage()
	call_deferred("_test_scene")


func _test_rules() -> void:
	var round_state := Rules.new()
	_expect(round_state.score == 0, "A round starts at zero")
	_expect(round_state.remaining == 30.0, "A round lasts thirty seconds")
	round_state.catch_item()
	round_state.catch_item()
	_expect(round_state.score == 20, "Each catch earns ten points")
	round_state.advance(0.5)
	_expect(is_equal_approx(round_state.remaining, 29.5), "Time advances by delta")
	round_state.advance(-10.0)
	_expect(is_equal_approx(round_state.remaining, 29.5), "Negative delta cannot add time")
	round_state.advance(40.0)
	_expect(round_state.remaining == 0.0 and round_state.is_finished(), "Time clamps to zero")
	round_state.catch_item()
	_expect(round_state.score == 20, "Catches after the deadline do not score")
	_expect(Rules.new().score == 0, "A new round resets the score")


func _test_storage() -> void:
	_remove_save()
	_expect(Store.load_best(SAVE) == 0, "Missing save returns zero")
	_expect(Store.save_best(40, SAVE) == OK, "Saving succeeds")
	_expect(Store.load_best(SAVE) == 40, "Best score survives a fresh read")
	Store.save_best(10, SAVE)
	_expect(Store.load_best(SAVE) == 40, "A lower score cannot replace the best")
	Store.save_best(70, SAVE)
	_expect(Store.load_best(SAVE) == 70, "A higher score replaces the best")
	var config := ConfigFile.new()
	config.set_value("scores", "best", "invalid")
	config.save(SAVE)
	_expect(Store.load_best(SAVE) == 0, "Non-integer scores are ignored")
	config.set_value("scores", "best", -20)
	config.save(SAVE)
	_expect(Store.load_best(SAVE) == 0, "Negative stored scores are ignored")
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string("not a config file [")
	file.close()
	_expect(Store.load_best(SAVE) == 0, "Malformed files recover to zero")
	_remove_save()
	Store.save_best(-10, SAVE)
	_expect(Store.load_best(SAVE) == 0, "Negative scores save as zero")
	_remove_save()


func _test_scene() -> void:
	var game: Node2D = load("res://main.tscn").instantiate()
	game.save_path = SAVE
	root.add_child(game)
	await process_frame
	var start: Button = game.menu.get_child(2)
	var quit_button: Button = game.menu.get_child(3)
	_expect(start.has_focus(), "Title focuses Start")
	_expect(start.get_node(start.focus_neighbor_bottom) == quit_button, "Down moves to Quit")
	_expect(quit_button.get_node(quit_button.focus_neighbor_bottom) == start, "Menu focus wraps")
	var down := InputEventJoypadButton.new()
	down.button_index = JOY_BUTTON_DPAD_DOWN
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	_expect(quit_button.has_focus(), "Gamepad D-pad moves menu focus")
	down.pressed = false
	Input.parse_input_event(down)
	var up := InputEventKey.new()
	up.keycode = KEY_UP
	up.pressed = true
	Input.parse_input_event(up)
	await process_frame
	_expect(start.has_focus(), "Keyboard arrows move menu focus")
	up.pressed = false
	Input.parse_input_event(up)
	var accept := InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	accept.pressed = true
	Input.parse_input_event(accept)
	await process_frame
	accept.pressed = false
	Input.parse_input_event(accept)
	await process_frame
	_expect(game.screen == game.Screen.PLAY, "Start opens the round")
	game.set_process(false)
	Input.action_press("move_right")
	var before: float = game.player_x
	game._process(0.1)
	Input.action_release("move_right")
	_expect(is_equal_approx(game.player_x - before, 43.0), "Movement uses delta and input actions")
	game.items.clear()
	game.items.append(Vector2(game.player_x, 500))
	game._process(0.1)
	_expect(game.round_state.score == 10, "A falling item scores on a basket collision")
	game.round_state.advance(30.0)
	game._process(0.01)
	await process_frame
	_expect(game.screen == game.Screen.GAME_OVER, "Deadline opens game over")
	_expect(Store.load_best(SAVE) == 10, "Completed rounds persist the best")
	var again: Button = game.menu.get_child(2)
	_expect(again.has_focus(), "Game over focuses Play again")
	again.pressed.emit()
	_expect(game.round_state.score == 0, "Play again resets the round")
	game.show_title()
	await process_frame
	_expect(game.menu.get_child(2).has_focus(), "Returning to Title restores focus")
	game.free()
	_remove_save()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _remove_save() -> void:
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(SAVE)
