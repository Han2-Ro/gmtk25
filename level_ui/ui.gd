class_name LevelUI
extends Control

signal restart_button_pressed
signal next_level_pressed
signal shop_button_pressed
signal shop_closed
signal upgrade_selected(upgrade: BaseUpgrade)

@onready var overlay: Control = $Overlay
@onready var overlay_label: Label = $Overlay/Panel/VBoxContainer/Label
@onready var mini_win_label: Label = $MiniWinContainer/MiniWinLabel
@onready var cash_label: Label = $Cash
@onready var shop_button: Button = $Overlay/Panel/VBoxContainer/ShopButton
@onready var restart_button: Button = $Overlay/Panel/VBoxContainer/RestartButton
@onready var shop_ui: ShopUI = $ShopUI
@onready var upgrade_selection: UpgradeSelection = $UpgradeSelection

var is_win_state: bool = false


func _ready():
	# Ensure overlay is hidden at start
	overlay.visible = false
	overlay_label.text = ""

	# Connect upgrade selection signal
	upgrade_selection.upgrade_selected.connect(_on_upgrade_selected)

	# Hide upgrade selection by default
	upgrade_selection.hide()


func show_overlay(is_win: bool) -> void:
	is_win_state = is_win
	if is_win:
		overlay_label.text = "YOU WON!"
		shop_button.visible = true
		restart_button.text = "Next level"
	else:
		overlay_label.text = "YOU ARE A LOOOOOSER"
		shop_button.visible = false
		restart_button.text = "Start again"
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
	cash_label.text = "Coins: %d" % amount


func _on_shop_button_pressed() -> void:
	shop_button_pressed.emit()


func setup_upgrades(upgrade_manager: UpgradeManager) -> void:
	var upgrades_container: HBoxContainer = $UpgradesContainer
	upgrade_manager.register_ui_container(upgrades_container)


func setup_shop(shop_manager: ShopManager) -> void:
	shop_ui.setup(shop_manager)
	shop_ui.shop_closed.connect(_on_shop_closed)
	shop_ui.play_again_pressed.connect(_on_play_again_pressed)


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
