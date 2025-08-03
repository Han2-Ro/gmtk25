class_name LevelUI
extends Control

signal restart_button_pressed
signal next_level_pressed
signal shop_button_pressed
signal shop_closed
signal upgrade_selected(upgrade: BaseUpgrade)
signal upgrade_skipped
signal fast_forward_pressed
signal try_again_pressed

@onready var overlay: Control = $Overlay
@onready var overlay_label: Label = $Overlay/Panel/VBoxContainer/Label
@onready var overlay_level_label: Label = $Overlay/Panel/VBoxContainer/LevelLabel
@onready var overlay_high_score_label: Label = $Overlay/Panel/VBoxContainer/HighScoreLabel
@onready var mini_win_label: Label = $MiniWinContainer/MiniWinLabel
@onready var cash_label: Control = $Cash
@onready var progress_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Progress
@onready var level_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Level
@onready var fast_forward_button: Button = $FastForwardButton
@onready var try_again_button: Button = $TryAgainButton
@onready var shop_button: Button = $Overlay/Panel/VBoxContainer/ShopButton
@onready
var restart_button: Button = $Overlay/Panel/VBoxContainer/RestartButtonContainer/RestartButton
@onready var shop_ui: ShopUI = $ShopUI
@onready var upgrade_selection: UpgradeSelection = $UpgradeSelection
@onready var lives: Control = $Lives
@onready var panel_container: PanelContainer = $PanelContainer
@onready var upgrades_container: HBoxContainer = $UpgradesContainer
@onready var mini_win_container: CenterContainer = $MiniWinContainer

var is_win_state: bool = false

# Store original positions for animations
var original_lives_pos: Vector2
var original_cash_pos: Vector2
var original_panel_pos: Vector2
var original_upgrades_pos: Vector2
var original_ff_button_pos: Vector2
var original_try_again_pos: Vector2
var original_mini_win_alpha: float


func _ready():
	# Store original positions for animations
	original_lives_pos = lives.position
	original_cash_pos = cash_label.position
	original_panel_pos = panel_container.position
	original_upgrades_pos = upgrades_container.position
	original_ff_button_pos = fast_forward_button.position
	original_try_again_pos = try_again_button.position
	original_mini_win_alpha = mini_win_container.modulate.a

	# Ensure overlay is hidden at start
	overlay.visible = false
	overlay_label.text = ""

	# Hide level until game starts
	level_label.visible = false

	# Connect upgrade selection signal
	upgrade_selection.upgrade_selected.connect(_on_upgrade_selected)
	upgrade_selection.upgrade_skipped.connect(_on_upgrade_skipped)

	# Connect fast forward button
	fast_forward_button.pressed.connect(_on_fast_forward_pressed)

	# Connect try again button
	try_again_button.pressed.connect(_on_try_again_pressed)
	try_again_button.visible = false

	# Hide upgrade selection by default
	upgrade_selection.hide()

	# Hide all UI elements initially
	hide_ui_elements()


func show_overlay(
	is_win: bool,
	last_completed_level: int = 0,
	is_new_high_score: bool = false,
	high_score: int = 0
) -> void:
	is_win_state = is_win
	if is_win:
		overlay_label.text = "YOU WON!"
		overlay_level_label.text = ""
		overlay_high_score_label.text = ""
		shop_button.visible = true
		restart_button.text = "Next level"
	else:
		overlay_label.text = "Game Over!"
		if last_completed_level > 0:
			overlay_level_label.text = "You completed level %d" % last_completed_level
		else:
			overlay_level_label.text = ""

		# Set high score message
		if is_new_high_score:
			overlay_high_score_label.text = "New Highscore!"
		elif high_score > 0:
			overlay_high_score_label.text = "Your highest score yet: %d" % high_score
		else:
			overlay_high_score_label.text = ""

		shop_button.visible = false
		restart_button.text = "Start again"
		# Hide try again button on game over
		try_again_button.visible = false
	overlay.visible = true


func show_mini_win(current_step: int, total_steps: int) -> void:
	var progress_percentage = (float(current_step) / float(total_steps)) * 100.0
	var messages: Array[String] = []

	if progress_percentage <= 25.0:
		# First quarter - small encouragements
		messages = ["Nice!", "Good!", "Keep going!", "You got it!", "Solid!"]
	elif progress_percentage <= 50.0:
		# Second quarter - medium encouragements
		messages = ["Great!", "Perfect!", "Excellent!", "Well done!", "Fantastic!"]
	elif progress_percentage <= 75.0:
		# Third quarter - bigger encouragements
		messages = ["Amazing!", "Outstanding!", "Incredible!", "You're on fire!", "Spectacular!"]
	else:
		# Final quarter - high-energy encouragements
		messages = ["WOW!", "PHENOMENAL!", "UNSTOPPABLE!", "LEGENDARY!", "ABSOLUTELY AMAZING!"]

	var message = messages.pick_random()
	mini_win_label.text = "%s (%d/%d)" % [message, current_step, total_steps]

	# Cancel any existing tween
	if mini_win_label.has_meta("tween"):
		var old_tween: Tween = mini_win_label.get_meta("tween")
		old_tween.kill()

	# Create fade in/out animation
	mini_win_label.visible = true
	var tween = create_tween()
	mini_win_label.set_meta("tween", tween)

	# Fade in
	tween.tween_property(mini_win_label, "modulate:a", 1.0, 0.2)
	# Hold
	tween.tween_interval(0.8)
	# Fade out
	tween.tween_property(mini_win_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): mini_win_label.visible = false)


func show_victory_message() -> void:
	var messages: Array[String] = [
		"SEQUENCE COMPLETE!", "LEVEL COMPLETE!", "MASTERED!", "VICTORY!", "YOU DID IT!"
	]
	var message = messages.pick_random()
	mini_win_label.text = message

	# Cancel any existing tween
	if mini_win_label.has_meta("tween"):
		var old_tween: Tween = mini_win_label.get_meta("tween")
		old_tween.kill()

	# Create fade in/out animation with longer display time
	mini_win_label.visible = true
	var tween = create_tween()
	mini_win_label.set_meta("tween", tween)

	# Fade in
	tween.tween_property(mini_win_label, "modulate:a", 1.0, 0.2)
	# Hold longer for victory
	tween.tween_interval(1.5)
	# Fade out
	tween.tween_property(mini_win_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): mini_win_label.visible = false)


func _on_restart_button_pressed() -> void:
	if is_win_state:
		next_level_pressed.emit()
	else:
		restart_button_pressed.emit()


func update_cash(amount: int) -> void:
	cash_label.update_cash(amount)


func _on_shop_button_pressed() -> void:
	shop_button_pressed.emit()


func setup_upgrades(upgrade_manager: UpgradeManager) -> void:
	var upgrades_container: HBoxContainer = $UpgradesContainer
	upgrade_manager.register_ui_container(upgrades_container)


func setup_shop(shop_manager: ShopManager) -> void:
	shop_ui.setup(shop_manager)
	shop_ui.shop_closed.connect(_on_shop_closed)
	shop_ui.play_again_pressed.connect(_on_play_again_pressed)


func setup_upgrade_selection(shop_manager: ShopManager) -> void:
	upgrade_selection.setup(shop_manager)


func open_shop() -> void:
	overlay.visible = false
	shop_ui.open_shop()


func close_shop() -> void:
	shop_ui.hide()
	overlay.visible = true


func close_overlay() -> void:
	overlay.visible = false


func close() -> void:
	close_shop()
	close_overlay()


func _on_shop_closed() -> void:
	shop_ui.hide()
	# Only show overlay if game has started (overlay was previously shown)
	if overlay_label.text != "":
		overlay.visible = true
	shop_closed.emit()


func _on_play_again_pressed() -> void:
	next_level_pressed.emit()


func show_upgrade_selection(upgrades: Array[BaseUpgrade]) -> void:
	# Hide overlay and show upgrade selection
	overlay.visible = false
	upgrade_selection.show_upgrades(upgrades)


func _on_upgrade_selected(upgrade: BaseUpgrade) -> void:
	# Hide upgrade selection and emit signal
	upgrade_selection.hide()
	upgrade_selected.emit(upgrade)


func _on_upgrade_skipped() -> void:
	# Hide upgrade selection and emit signal
	upgrade_selection.hide()
	upgrade_skipped.emit()


func show_fast_forward_button() -> void:
	fast_forward_button.visible = true


func hide_fast_forward_button() -> void:
	fast_forward_button.visible = false


func update_fast_forward_state(is_enabled: bool) -> void:
	if is_enabled:
		fast_forward_button.text = "FF ON "
		fast_forward_button.modulate = Color.GREEN
	else:
		fast_forward_button.text = "FF OFF"
		fast_forward_button.modulate = Color.WHITE


func _on_fast_forward_pressed() -> void:
	fast_forward_pressed.emit()


func show_try_again_button() -> void:
	try_again_button.visible = true


func hide_try_again_button() -> void:
	try_again_button.visible = false


func _on_try_again_pressed() -> void:
	# Hide the mistake notification
	var tween = create_tween()
	tween.tween_property(mini_win_label, "modulate:a", 0, 0.3)
	tween.tween_callback(
		func():
			mini_win_label.visible = false
			mini_win_label.remove_theme_color_override("font_color")  # Reset theme color
	)

	try_again_pressed.emit()


func update_step_progress(current_step: int, total_steps: int) -> void:
	progress_label.text = "Step %d/%d" % [current_step, total_steps]


func update_subsequence_progress(current_round: int, total_rounds: int) -> void:
	progress_label.text = "Round %d/%d" % [current_round, total_rounds]


func clear_progress() -> void:
	progress_label.text = ""


func show_level() -> void:
	level_label.visible = true


func show_mistake_notification() -> void:
	var messages: Array[String] = [
		"Whoops!", "Oops!", "Try again!", "Almost!", "So close!", "Nice try!"
	]
	var message = messages.pick_random()
	mini_win_label.text = message

	# Cancel any existing tween
	if mini_win_label.has_meta("tween"):
		var old_tween: Tween = mini_win_label.get_meta("tween")
		old_tween.kill()

	# Create fade in/out animation with reddish tint for mistakes
	mini_win_label.visible = true
	# Set color using add_theme_color_override to ensure it applies
	mini_win_label.add_theme_color_override("font_color", Color.ORANGE_RED)
	mini_win_label.modulate = Color(1, 1, 1, 0)  # Start transparent but keep white modulation
	var tween = create_tween()
	mini_win_label.set_meta("tween", tween)

	# Fade in
	tween.tween_property(mini_win_label, "modulate:a", 1.0, 0.2)
	# Stay visible until try again button is pressed (no auto-hide)


func hide_ui_elements() -> void:
	# Position elements off-screen but keep UI visible for animations
	self.visible = true

	# Move elements off-screen
	lives.position = Vector2(original_lives_pos.x - 200, original_lives_pos.y - 100)
	cash_label.position = Vector2(original_cash_pos.x, original_cash_pos.y - 100)
	panel_container.position = Vector2(original_panel_pos.x, original_panel_pos.y - 150)
	upgrades_container.position = Vector2(original_upgrades_pos.x + 350, original_upgrades_pos.y)
	fast_forward_button.position = Vector2(original_ff_button_pos.x + 100, original_ff_button_pos.y)
	try_again_button.position = Vector2(original_try_again_pos.x, original_try_again_pos.y + 300)
	mini_win_container.modulate.a = 0


func show_ui_elements() -> void:
	# Show all game UI elements with staggered slide-in animations
	self.visible = true

	# Create staggered animations for each element
	var animation_duration = 0.4
	var stagger_delay = 0.1

	# Lives - slide in from top-left
	var lives_tween = create_tween()
	lives_tween.tween_interval(0.0)
	lives_tween.tween_property(lives, "position", original_lives_pos, animation_duration).set_ease(
		Tween.EASE_OUT
	)

	# Cash - slide in from top-right
	var cash_tween = create_tween()
	cash_tween.tween_interval(stagger_delay)
	(
		cash_tween
		. tween_property(cash_label, "position", original_cash_pos, animation_duration)
		. set_ease(Tween.EASE_OUT)
	)

	# Panel container - slide down from top-center
	var panel_tween = create_tween()
	panel_tween.tween_interval(stagger_delay * 2)
	(
		panel_tween
		. tween_property(panel_container, "position", original_panel_pos, animation_duration)
		. set_ease(Tween.EASE_OUT)
	)

	# Upgrades container - slide in from right
	var upgrades_tween = create_tween()
	upgrades_tween.tween_interval(stagger_delay * 3)
	(
		upgrades_tween
		. tween_property(upgrades_container, "position", original_upgrades_pos, animation_duration)
		. set_ease(Tween.EASE_OUT)
	)

	# Fast forward button - slide in from right
	var ff_tween = create_tween()
	ff_tween.tween_interval(stagger_delay * 4)
	(
		ff_tween
		. tween_property(
			fast_forward_button, "position", original_ff_button_pos, animation_duration
		)
		. set_ease(Tween.EASE_OUT)
	)

	# Try again button - slide up from bottom
	var try_again_tween = create_tween()
	try_again_tween.tween_interval(stagger_delay * 5)
	(
		try_again_tween
		. tween_property(try_again_button, "position", original_try_again_pos, animation_duration)
		. set_ease(Tween.EASE_OUT)
	)

	# Mini win container - fade in
	var mini_win_tween = create_tween()
	mini_win_tween.tween_interval(stagger_delay * 6)
	(
		mini_win_tween
		. tween_property(
			mini_win_container, "modulate:a", original_mini_win_alpha, animation_duration
		)
		. set_ease(Tween.EASE_OUT)
	)
