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
var upgrade: BaseUpgrade


func setup(upgrade_ref: BaseUpgrade, manager: ShopManager) -> void:
	upgrade = upgrade_ref
	item_id = upgrade.id
	shop_manager = manager

	name_label.text = upgrade.get_display_name()
	description_label.text = upgrade.description
	cost_label.text = "%d coins" % upgrade.cost

	update_button_state()


func update_button_state() -> void:
	if not upgrade:
		return

	# Update name with count if applicable
	name_label.text = upgrade.get_display_name()

	if not upgrade.is_stackable and upgrade.purchased_count > 0:
		buy_button.text = "Owned"
		buy_button.disabled = true
	elif upgrade.is_stackable and upgrade.purchased_count > 0:
		if upgrade.max_stack > 0 and upgrade.purchased_count >= upgrade.max_stack:
			buy_button.text = "Max (%d)" % upgrade.purchased_count
			buy_button.disabled = true
		else:
			buy_button.text = "Buy"
			buy_button.disabled = not shop_manager.can_afford(upgrade)
	else:
		buy_button.text = "Buy"
		buy_button.disabled = not shop_manager.can_afford(upgrade)


func _on_buy_button_pressed() -> void:
	purchase_requested.emit(item_id)
