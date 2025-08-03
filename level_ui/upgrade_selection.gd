# ABOUTME: Manages the upgrade selection UI that appears after completing a level
# ABOUTME: Displays 3 upgrade cards for player to choose from in roguelike style
class_name UpgradeSelection
extends CenterContainer

signal upgrade_selected(upgrade: BaseUpgrade)
signal upgrade_skipped

var current_upgrades: Array[BaseUpgrade] = []
var shop_manager: ShopManager

@onready
var card1_title: Label = $Panel/MarginContainer/VBoxContainer/UpgradeCards/Card1/VBoxContainer/Title
@onready
var card1_desc: Label = $Panel/MarginContainer/VBoxContainer/UpgradeCards/Card1/VBoxContainer/Description
@onready
var card1_price: Label = $Panel/MarginContainer/VBoxContainer/UpgradeCards/Card1/VBoxContainer/Price
@onready
var card1_button: Button = $Panel/MarginContainer/VBoxContainer/UpgradeCards/Card1/VBoxContainer/SelectButton

@onready
var card2_title: Label = $Panel/MarginContainer/VBoxContainer/UpgradeCards/Card2/VBoxContainer/Title
@onready
var card2_desc: Label = $Panel/MarginContainer/VBoxContainer/UpgradeCards/Card2/VBoxContainer/Description
@onready
var card2_price: Label = $Panel/MarginContainer/VBoxContainer/UpgradeCards/Card2/VBoxContainer/Price
@onready
var card2_button: Button = $Panel/MarginContainer/VBoxContainer/UpgradeCards/Card2/VBoxContainer/SelectButton

@onready
var card3_title: Label = $Panel/MarginContainer/VBoxContainer/UpgradeCards/Card3/VBoxContainer/Title
@onready
var card3_desc: Label = $Panel/MarginContainer/VBoxContainer/UpgradeCards/Card3/VBoxContainer/Description
@onready
var card3_price: Label = $Panel/MarginContainer/VBoxContainer/UpgradeCards/Card3/VBoxContainer/Price
@onready
var card3_button: Button = $Panel/MarginContainer/VBoxContainer/UpgradeCards/Card3/VBoxContainer/SelectButton

@onready var skip_button: Button = $Panel/MarginContainer/VBoxContainer/SkipButton
@onready var panel: Panel = $Panel

# Store original panel scale for animations
var original_panel_scale: Vector2


func _ready() -> void:
	# Store original panel scale for animations
	original_panel_scale = panel.scale

	card1_button.pressed.connect(_on_card1_selected)
	card2_button.pressed.connect(_on_card2_selected)
	card3_button.pressed.connect(_on_card3_selected)
	skip_button.pressed.connect(_on_skip_pressed)


func setup(manager: ShopManager) -> void:
	shop_manager = manager


func show_upgrades(upgrades: Array[BaseUpgrade]) -> void:
	current_upgrades = upgrades

	# Fill cards with upgrade data
	if upgrades.size() >= 1:
		card1_title.text = upgrades[0].name
		card1_desc.text = upgrades[0].description
		card1_price.text = "%d coins" % upgrades[0].cost
		_update_button_state(card1_button, upgrades[0])

	if upgrades.size() >= 2:
		card2_title.text = upgrades[1].name
		card2_desc.text = upgrades[1].description
		card2_price.text = "%d coins" % upgrades[1].cost
		_update_button_state(card2_button, upgrades[1])

	if upgrades.size() >= 3:
		card3_title.text = upgrades[2].name
		card3_desc.text = upgrades[2].description
		card3_price.text = "%d coins" % upgrades[2].cost
		_update_button_state(card3_button, upgrades[2])

	_show_with_animation()


func hide_selection() -> void:
	_hide_with_animation()


func _show_with_animation() -> void:
	# Show the UI and start with scaled down panel
	show()
	modulate.a = 0
	panel.scale = Vector2(0.8, 0.8)

	# Create smooth fade in and scale up animation
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade in background
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

	# Scale up panel with bounce effect
	(
		tween
		. tween_property(panel, "scale", original_panel_scale, 0.4)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_BACK)
	)


func _hide_with_animation() -> void:
	# Create smooth fade out and scale down animation
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade out background
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)

	# Scale down panel
	tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.2).set_ease(Tween.EASE_IN)

	# Hide after animation completes
	tween.tween_callback(hide)


func _update_button_state(button: Button, upgrade: BaseUpgrade) -> void:
	if not shop_manager:
		return

	if shop_manager.can_afford(upgrade):
		button.disabled = false
		button.text = "Select"
	else:
		button.disabled = true
		button.text = "Can't afford"


func _on_card1_selected() -> void:
	if current_upgrades.size() >= 1:
		upgrade_selected.emit(current_upgrades[0])
		hide_selection()


func _on_card2_selected() -> void:
	if current_upgrades.size() >= 2:
		upgrade_selected.emit(current_upgrades[1])
		hide_selection()


func _on_card3_selected() -> void:
	if current_upgrades.size() >= 3:
		upgrade_selected.emit(current_upgrades[2])
		hide_selection()


func _on_skip_pressed() -> void:
	upgrade_skipped.emit()
	hide_selection()
