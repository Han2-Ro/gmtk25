# ABOUTME: Manages the shop system including available upgrades, purchases, and persistent state
# ABOUTME: Handles upgrade effects and tracks player's purchased items across game sessions
class_name ShopManager
extends Node

signal purchase_completed(upgrade: BaseUpgrade)
signal purchase_failed(upgrade_id: String, reason: String)

var cash_manager: CashManager
var upgrade_manager: Node


func _ready():
	# Get upgrade manager reference
	upgrade_manager = get_node_or_null("/root/UpgradeManager")
	if upgrade_manager:
		# Load saved upgrade states
		upgrade_manager.load_upgrades_state()


func can_afford(upgrade: BaseUpgrade) -> bool:
	return cash_manager.can_afford(upgrade.cost)


func get_purchasable_upgrades() -> Array[BaseUpgrade]:
	if not upgrade_manager:
		return []
	return upgrade_manager.get_purchasable_upgrades()


func purchase_upgrade(upgrade_id: String) -> bool:
	if not upgrade_manager:
		purchase_failed.emit(upgrade_id, "Upgrade system not initialized")
		return false

	var upgrade = upgrade_manager.get_upgrade(upgrade_id)
	if not upgrade:
		purchase_failed.emit(upgrade_id, "Upgrade not found")
		return false

	if not upgrade.can_purchase():
		purchase_failed.emit(upgrade_id, "Already purchased maximum")
		return false

	if not can_afford(upgrade):
		purchase_failed.emit(upgrade_id, "Not enough coins")
		return false

	# Deduct cost
	cash_manager.pay(upgrade.cost)

	# Purchase through upgrade manager
	upgrade_manager.purchase_upgrade(upgrade_id)

	purchase_completed.emit(upgrade)
	return true
