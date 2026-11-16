extends Node2D

enum Screen { TITLE, PLAY, PAUSED, GAME_OVER }

const Rules = preload("res://scripts/round_rules.gd")
const ScoreStore = preload("res://scripts/score_store.gd")
const FIELD := Rect2(36, 110, 728, 446)
const PLAYER_SIZE := Vector2(92, 22)
const PLAYER_Y := 516.0
const SPEED := 430.0
const FALL_SPEED := 230.0
const ITEM_RADIUS := 11.0
const SPAWN_INTERVAL := 0.55

var screen := Screen.TITLE
var round_state := Rules.new()
var best := 0
var save_path := ScoreStore.SAVE_PATH
var player_x := 400.0
var spawn_remaining := 0.0
var items: Array[Vector2] = []
var random := RandomNumberGenerator.new()
var interface: Control
var menu: VBoxContainer
var hud: Label
var pause_overlay: ColorRect


func _ready() -> void:
	random.randomize()
	best = ScoreStore.load_best(save_path)
	var layer := CanvasLayer.new()
	add_child(layer)
	interface = Control.new()
	interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(interface)
	show_title()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if screen == Screen.PLAY and event.is_action_pressed("pause"):
		show_pause()
		get_viewport().set_input_as_handled()
	elif (
		screen == Screen.PAUSED
		and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"))
	):
		resume_round()
		get_viewport().set_input_as_handled()


func show_pause() -> void:
	screen = Screen.PAUSED
	pause_overlay = ColorRect.new()
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.color = Color(0, 0, 0, 0.65)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface.add_child(pause_overlay)
	_create_menu("PAUSED", "Take a break. Your round will wait.")
	menu.reparent(pause_overlay)
	_add_button("Resume", resume_round)
	_add_button("Restart", start_round)
	_add_button("Quit", show_title)
	_focus_menu()


func resume_round() -> void:
	interface.remove_child(pause_overlay)
	pause_overlay.queue_free()
	pause_overlay = null
	screen = Screen.PLAY


func _process(delta: float) -> void:
	if screen != Screen.PLAY:
		return
	round_state.advance(delta)
	if round_state.is_finished():
		finish_round()
		return
	player_x += Input.get_axis("move_left", "move_right") * SPEED * delta
	player_x = clampf(player_x, FIELD.position.x + 46, FIELD.end.x - 46)
	spawn_remaining -= delta
	if spawn_remaining <= 0.0:
		items.append(Vector2(random.randf_range(FIELD.position.x + 16, FIELD.end.x - 16), 124))
		spawn_remaining += SPAWN_INTERVAL
	var basket := Rect2(Vector2(player_x - PLAYER_SIZE.x / 2, PLAYER_Y), PLAYER_SIZE)
	for index in range(items.size() - 1, -1, -1):
		var previous_y := items[index].y
		items[index].y += FALL_SPEED * delta
		# Test the swept vertical path so a slow frame cannot skip a catch.
		if (
			absf(items[index].x - player_x) <= PLAYER_SIZE.x / 2 + ITEM_RADIUS
			and previous_y - ITEM_RADIUS <= basket.end.y
			and items[index].y + ITEM_RADIUS >= basket.position.y
		):
			round_state.catch_item()
			items.remove_at(index)
		elif items[index].y > FIELD.end.y + ITEM_RADIUS:
			items.remove_at(index)
	hud.text = (
		"Score  %d     Best  %d     Time  %02d"
		% [round_state.score, best, ceili(round_state.remaining)]
	)
	queue_redraw()


func _draw() -> void:
	if screen != Screen.PLAY and screen != Screen.PAUSED:
		return
	draw_style_box(_field_style(), FIELD)
	for item in items:
		draw_circle(item, ITEM_RADIUS, Color("ffd36b"))
		draw_circle(item + Vector2(-3, -3), 3, Color("fff2cb"))
	var basket := Rect2(Vector2(player_x - PLAYER_SIZE.x / 2, PLAYER_Y), PLAYER_SIZE)
	draw_rect(basket, Color("6ce5cd"))
	draw_rect(Rect2(basket.position, Vector2(PLAYER_SIZE.x, 4)), Color("c2fff1"))


func show_title() -> void:
	screen = Screen.TITLE
	_clear_interface()
	_create_menu("STAR BASKET", "Catch the falling stars in 30 seconds.\nBest score: %d" % best)
	_add_button("Start", start_round)
	_add_button("Quit", get_tree().quit)
	_add_caption("Move: A / D, arrow keys, D-pad or left stick\nMenus: arrows / D-pad, Enter / A")
	_focus_menu()


func start_round() -> void:
	screen = Screen.PLAY
	round_state = Rules.new()
	player_x = 400.0
	spawn_remaining = 0.0
	items.clear()
	_clear_interface()
	hud = Label.new()
	hud.position = Vector2(36, 38)
	hud.add_theme_font_size_override("font_size", 25)
	interface.add_child(hud)
	var hint := Label.new()
	hint.text = "Catch gold stars • Move with A / D, arrows or left stick"
	hint.position = Vector2(36, 568)
	interface.add_child(hint)
	queue_redraw()


func finish_round() -> void:
	screen = Screen.GAME_OVER
	best = maxi(best, round_state.score)
	var save_error := ScoreStore.save_best(best, save_path)
	_clear_interface()
	_create_menu("ROUND COMPLETE", "Score: %d\nBest score: %d" % [round_state.score, best])
	_add_button("Play again", start_round)
	_add_button("Title", show_title)
	if save_error != OK:
		_add_caption("Could not save your best score to this device.")
	_focus_menu()
	queue_redraw()


func _clear_interface() -> void:
	for child in interface.get_children():
		interface.remove_child(child)
		child.queue_free()
	queue_redraw()


func _create_menu(title: String, subtitle: String) -> void:
	menu = VBoxContainer.new()
	menu.position = Vector2(190, 140)
	menu.size = Vector2(420, 0)
	menu.add_theme_constant_override("separation", 20)
	interface.add_child(menu)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 36)
	menu.add_child(heading)
	_add_caption(subtitle)


func _add_caption(text: String) -> void:
	var caption := Label.new()
	caption.text = text
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(caption)


func _add_button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 54)
	button.add_theme_font_size_override("font_size", 23)
	button.pressed.connect(action)
	menu.add_child(button)


func _focus_menu() -> void:
	var buttons: Array[Button] = []
	for child in menu.get_children():
		if child is Button:
			buttons.append(child)
	for index in buttons.size():
		var previous := buttons[(index - 1 + buttons.size()) % buttons.size()]
		var next := buttons[(index + 1) % buttons.size()]
		buttons[index].focus_neighbor_top = buttons[index].get_path_to(previous)
		buttons[index].focus_neighbor_bottom = buttons[index].get_path_to(next)
		buttons[index].focus_next = buttons[index].get_path_to(next)
		buttons[index].focus_previous = buttons[index].get_path_to(previous)
	buttons[0].grab_focus()


func _field_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111e38")
	style.border_color = Color("263b60")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style
