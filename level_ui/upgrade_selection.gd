# ABOUTME: Manages the upgrade selection UI that appears after completing a level
# ABOUTME: Displays 3 upgrade cards for player to choose from in roguelike style
class_name UpgradeSelection
extends CenterContainer

signal upgrade_selected(upgrade: BaseUpgrade)

@onready var card1_title: Label = $Panel/VBoxContainer/UpgradeCards/Card1/VBoxContainer/Title
@onready var card1_desc: Label = $Panel/VBoxContainer/UpgradeCards/Card1/VBoxContainer/Description
@onready
var card1_button: Button = $Panel/VBoxContainer/UpgradeCards/Card1/VBoxContainer/SelectButton

@onready var card2_title: Label = $Panel/VBoxContainer/UpgradeCards/Card2/VBoxContainer/Title
@onready var card2_desc: Label = $Panel/VBoxContainer/UpgradeCards/Card2/VBoxContainer/Description
@onready
var card2_button: Button = $Panel/VBoxContainer/UpgradeCards/Card2/VBoxContainer/SelectButton

@onready var card3_title: Label = $Panel/VBoxContainer/UpgradeCards/Card3/VBoxContainer/Title
@onready var card3_desc: Label = $Panel/VBoxContainer/UpgradeCards/Card3/VBoxContainer/Description
@onready
var card3_button: Button = $Panel/VBoxContainer/UpgradeCards/Card3/VBoxContainer/SelectButton

var current_upgrades: Array[BaseUpgrade] = []


func _ready() -> void:
	card1_button.pressed.connect(_on_card1_selected)
	card2_button.pressed.connect(_on_card2_selected)
	card3_button.pressed.connect(_on_card3_selected)


func show_upgrades(upgrades: Array[BaseUpgrade]) -> void:
	current_upgrades = upgrades

	# Fill cards with upgrade data
	if upgrades.size() >= 1:
		card1_title.text = upgrades[0].name
		card1_desc.text = upgrades[0].description

	if upgrades.size() >= 2:
		card2_title.text = upgrades[1].name
		card2_desc.text = upgrades[1].description

	if upgrades.size() >= 3:
		card3_title.text = upgrades[2].name
		card3_desc.text = upgrades[2].description

	show()


func hide_selection() -> void:
	hide()


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
