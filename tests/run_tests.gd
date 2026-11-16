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
	var pause := InputEventJoypadButton.new()
	pause.button_index = JOY_BUTTON_START
	pause.pressed = true
	Input.parse_input_event(pause)
	await process_frame
	_expect(game.screen == game.Screen.GAME_OVER, "Game over cannot be paused")
	pause.pressed = false
	Input.parse_input_event(pause)
	await process_frame
	var again: Button = game.menu.get_child(2)
	_expect(again.has_focus(), "Game over focuses Play again")
	again.pressed.emit()
	_expect(game.round_state.score == 0, "Play again resets the round")
	await _test_pause(game)
	await _test_pause_actions(game)
	game.show_title()
	await process_frame
	_expect(game.menu.get_child(2).has_focus(), "Returning to Title restores focus")
	game.free()
	_remove_save()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _test_pause(game: Node2D) -> void:
	var remaining: float = game.round_state.remaining
	var score: int = game.round_state.score
	game.items.assign([Vector2(300, 200)])
	var items: Array = game.items.duplicate()
	var player_x: float = game.player_x
	var hud: Label = game.hud
	var hint: Node = game.interface.get_child(1)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	_expect(game.screen == game.Screen.get("PAUSED"), "One Esc press opens pause")
	var overlay: Control = game.menu.get_parent()
	_expect(overlay != game.interface and overlay.is_visible_in_tree(), "Pause overlay is shown")
	var resume: Button = game.menu.get_child(2)
	var restart: Button = game.menu.get_child(3)
	var quit_button: Button = game.menu.get_child(4)
	_expect(
		[resume.text, restart.text, quit_button.text] == ["Resume", "Restart", "Quit"],
		"Pause offers Resume, Restart and Quit"
	)
	_expect(resume.has_focus(), "Pause focuses Resume")
	escape.echo = true
	Input.parse_input_event(escape)
	await process_frame
	_expect(game.screen == game.Screen.PAUSED, "Held Esc does not resume")
	escape.echo = false
	_expect(
		hud.get_parent() == game.interface and hint.get_parent() == game.interface,
		"Pause preserves the HUD and hint"
	)
	game.set_process(true)
	Input.action_press("move_right")
	game._process(1.0)
	await process_frame
	await process_frame
	game.set_process(false)
	Input.action_release("move_right")
	_expect(game.round_state.remaining == remaining, "Pause freezes the round clock")
	_expect(game.round_state.score == score, "Pause preserves score")
	_expect(game.items == items, "Pause freezes falling items and spawning")
	_expect(game.player_x == player_x, "Pause freezes movement")
	var buttons: Array[Button] = [resume, restart, quit_button]
	for index in buttons.size():
		var button := buttons[index]
		_expect(
			button.get_node(button.focus_neighbor_bottom) == buttons[(index + 1) % 3],
			"Pause Down follows screen order and wraps"
		)
		_expect(
			button.get_node(button.focus_neighbor_top) == buttons[(index + 2) % 3],
			"Pause Up follows reverse screen order and wraps"
		)
	var down := InputEventKey.new()
	down.keycode = KEY_DOWN
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	_expect(restart.has_focus(), "Injected Down focuses Restart")
	down.pressed = false
	Input.parse_input_event(down)
	await process_frame
	escape.pressed = false
	Input.parse_input_event(escape)
	await process_frame
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	_expect(game.screen == game.Screen.PLAY, "Second Esc resumes with a button focused")
	_expect(
		(
			game.interface.get_child_count() == 2
			and (not is_instance_valid(overlay) or not overlay.is_inside_tree())
		),
		"Resume removes only the pause overlay"
	)
	_expect(
		(
			game.round_state.remaining == remaining
			and game.items == items
			and game.round_state.score == score
			and game.player_x == player_x
		),
		"Resume preserves the round"
	)
	escape.pressed = false
	Input.parse_input_event(escape)
	await process_frame
	game._process(0.1)
	_expect(game.round_state.remaining < remaining, "Time advances after resuming")


func _test_pause_actions(game: Node2D) -> void:
	var start := InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	start.pressed = true
	Input.parse_input_event(start)
	await process_frame
	_expect(game.screen == game.Screen.PAUSED, "Gamepad Start pauses")
	_expect(game.menu.get_child(2).has_focus(), "Gamepad pause focuses Resume")
	start.pressed = false
	Input.parse_input_event(start)
	await process_frame
	var cancel: InputEventJoypadButton
	for event in InputMap.action_get_events("ui_cancel"):
		if event is InputEventJoypadButton:
			cancel = event.duplicate()
			break
	_expect(cancel != null, "Cancel has a gamepad binding")
	if cancel != null:
		cancel.pressed = true
		Input.parse_input_event(cancel)
		await process_frame
		_expect(game.screen == game.Screen.PLAY, "Gamepad cancel resumes")
		cancel.pressed = false
		Input.parse_input_event(cancel)
		await process_frame
	start.pressed = true
	Input.parse_input_event(start)
	await process_frame
	start.pressed = false
	Input.parse_input_event(start)
	await process_frame
	start.pressed = true
	Input.parse_input_event(start)
	await process_frame
	_expect(game.screen == game.Screen.PLAY, "Gamepad Start also resumes")
	start.pressed = false
	Input.parse_input_event(start)
	await process_frame
	start.pressed = true
	Input.parse_input_event(start)
	await process_frame
	start.pressed = false
	Input.parse_input_event(start)
	await process_frame
	game.menu.get_child(2).pressed.emit()
	_expect(game.screen == game.Screen.PLAY, "Resume button returns to play")
	game.round_state.score = 100
	game.round_state.advance(5.0)
	start.pressed = true
	Input.parse_input_event(start)
	await process_frame
	start.pressed = false
	Input.parse_input_event(start)
	await process_frame
	game.menu.get_child(3).pressed.emit()
	_expect(
		(
			game.screen == game.Screen.PLAY
			and game.round_state.score == 0
			and game.round_state.remaining == 30.0
		),
		"Restart starts a fresh round"
	)
	_expect(
		game.items.is_empty() and game.player_x == 400.0 and game.interface.get_child_count() == 2,
		"Restart resets the field and removes the overlay"
	)
	_expect(
		Store.load_best(SAVE) == 10 and game.best == 10, "Restart does not save abandoned score"
	)
	game.round_state.score = 200
	start.pressed = true
	Input.parse_input_event(start)
	await process_frame
	start.pressed = false
	Input.parse_input_event(start)
	await process_frame
	game.menu.get_child(4).pressed.emit()
	_expect(game.screen == game.Screen.TITLE, "Pause Quit returns to title")
	_expect(Store.load_best(SAVE) == 10 and game.best == 10, "Quit does not save abandoned score")
	start.pressed = true
	Input.parse_input_event(start)
	await process_frame
	_expect(game.screen == game.Screen.TITLE, "Title cannot be paused")
	start.pressed = false
	Input.parse_input_event(start)
	await process_frame


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _remove_save() -> void:
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(SAVE)
