# ABOUTME: Individual shop item UI component that displays item info and handles purchase interaction
# ABOUTME: Shows item name, description, cost, and purchase state with appropriate visual feedback
class_name ShopItem
extends PanelContainer

signal purchase_requested(item_id: String)

@export var item_id: String = ""

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var cost_label: Label = $VBoxContainer/HBoxContainer/CostLabel
@onready var buy_button: Button = $VBoxContainer/HBoxContainer/BuyButton

var shop_manager: ShopManager
var item_data: ShopManager.ShopItemData


func setup(id: String, data: ShopManager.ShopItemData, manager: ShopManager) -> void:
	item_id = id
	item_data = data
	shop_manager = manager

	name_label.text = data.name
	description_label.text = data.description
	cost_label.text = "%d coins" % data.cost

	update_button_state()


func update_button_state() -> void:
	if not item_data.is_stackable and item_data.is_purchased:
		buy_button.text = "Owned"
		buy_button.disabled = true
	elif item_data.is_stackable and item_data.count > 0:
		buy_button.text = "Buy (%d)" % item_data.count
		buy_button.disabled = not shop_manager.can_afford(item_data)
	else:
		buy_button.text = "Buy"
		buy_button.disabled = not shop_manager.can_afford(item_data)


func _on_buy_button_pressed() -> void:
	purchase_requested.emit(item_id)
