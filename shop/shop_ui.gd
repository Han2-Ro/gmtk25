# ABOUTME: Shop UI controller that manages the shop interface and item display
# ABOUTME: Handles shop opening/closing, item updates, and purchase interactions
class_name ShopUI
extends Control

signal shop_closed
signal play_again_pressed

@onready var cash_label: Label = $Panel/VBoxContainer/HeaderContainer/CashLabel
@onready var items_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ItemsContainer
@onready var close_button: Button = $Panel/VBoxContainer/ButtonContainer/CloseButton
@onready var play_again_button: Button = $Panel/VBoxContainer/ButtonContainer/PlayAgainButton

var shop_manager: ShopManager
var shop_item_scene = preload("res://shop/shop_item.tscn")
var item_instances = {}


func setup(manager: ShopManager) -> void:
	shop_manager = manager
	shop_manager.purchase_completed.connect(_on_purchase_completed)
	shop_manager.purchase_failed.connect(_on_purchase_failed)

	create_shop_items()
	update_cash_display()


func create_shop_items() -> void:
	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()
	item_instances.clear()

	# Create item UI for each purchasable upgrade
	var upgrades = shop_manager.get_purchasable_upgrades()
	for upgrade in upgrades:
		var item_instance: ShopItem = shop_item_scene.instantiate()
		items_container.add_child(item_instance)
		item_instance.setup(upgrade, shop_manager)
		item_instance.purchase_requested.connect(_on_item_purchase_requested)
		item_instances[upgrade.id] = item_instance


func update_cash_display() -> void:
	if shop_manager and shop_manager.cash_manager:
		cash_label.text = "Coins: %d" % shop_manager.cash_manager.current_cash
	else:
		cash_label.text = "Coins: 0"


func update_all_items() -> void:
	for upgrade_id in item_instances:
		var instance = item_instances[upgrade_id]
		if instance and is_instance_valid(instance):
			instance.update_button_state()


func _on_item_purchase_requested(upgrade_id: String) -> void:
	if shop_manager.purchase_upgrade(upgrade_id):
		update_cash_display()
		# Recreate shop items in case an upgrade is no longer purchasable
		create_shop_items()


func _on_purchase_completed(upgrade: BaseUpgrade) -> void:
	# Could add purchase animation or sound here
	print("Purchased: ", upgrade.name)


func _on_purchase_failed(upgrade_id: String, reason: String) -> void:
	# Could show error message
	print("Purchase of ", upgrade_id, " failed: ", reason)


func _on_close_button_pressed() -> void:
	hide()
	shop_closed.emit()


func _on_play_again_button_pressed() -> void:
	play_again_pressed.emit()


func open_shop() -> void:
	show()
	update_cash_display()
	update_all_items()
