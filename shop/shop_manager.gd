# ABOUTME: Manages the shop system including available upgrades, purchases, and persistent state
# ABOUTME: Handles upgrade effects and tracks player's purchased items across game sessions
class_name ShopManager
extends Node


class ShopItemData:
	var id: String
	var name: String
	var description: String
	var cost: int
	var is_purchased: bool = false
	var is_stackable: bool = false
	var count: int = 0

	func _init(
		id_p: String,
		name_p: String,
		description_p: String,
		cost_p: int,
		is_stackable_p: bool = false,
	) -> void:
		self.id = id_p
		self.name = name_p
		self.description = description_p
		self.cost = cost_p
		self.is_stackable = is_stackable_p

	func can_purchase() -> bool:
		return is_stackable or not is_purchased

	func purchase() -> void:
		if self.is_purchased and not self.is_stackable:
			push_error("Tried to buy {0} again".format(self.id))
			return
		is_purchased = true
		count += 1


signal purchase_completed(item: ShopItemData)
signal purchase_failed(item: ShopItemData, reason: String)

# Upgrade IDs
const EXTRA_LIFE = "extra_life"
const COIN_MULTIPLIER = "coin_multiplier"
const SKIP_BUTTON = "skip_button"
const SLOWER_SEQUENCE = "slower_sequence"

# Shop items data
var shop_items: Array[ShopItemData] = [
	ShopItemData.new(EXTRA_LIFE, "Extra Life", "+1 starting life", 10, true),
	ShopItemData.new(COIN_MULTIPLIER, "Coin Multiplier", "2x coins per action", 25, false),
	ShopItemData.new(SKIP_BUTTON, "Skip Token", "Skip one step in sequence", 15, true),
	ShopItemData.new(SLOWER_SEQUENCE, "Slow Motion", "More time between flashes", 20, false)
]

var cash_manager: CashManager


func can_afford(item: ShopItemData) -> bool:
	return cash_manager.can_afford(item.cost)


func purchase_item(item: ShopItemData) -> bool:
	if not item.can_purchase():
		purchase_failed.emit(item.id, "Already purchased")
		return false

	if not can_afford(item):
		purchase_failed.emit(item.id, "Not enough coins")
		return false

	# Deduct cost
	cash_manager.pay(item.cost)

	# Mark as purchased
	item.purchase()

	purchase_completed.emit(item)
	return true
