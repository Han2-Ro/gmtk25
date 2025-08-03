extends Label


func update_cash(amount: int) -> void:
	self.text = "Coins: %d" % amount
