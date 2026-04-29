extends Node

# ===== 卡牌数据加载和效果解析 =====

var all_cards: Array = []
var _cards_by_id: Dictionary = {}


func _ready() -> void:
	load_cards()


func load_cards() -> void:
	var f := FileAccess.open("res://scripts/data/cards.json", FileAccess.READ)
	if f == null:
		push_error("Cannot load cards.json: " + str(FileAccess.get_open_error()))
		return
	var json_str: String = f.get_as_text()
	f.close()
	var result: Variant = JSON.parse_string(json_str)
	if result == null:
		push_error("Failed to parse cards.json")
		return
	var data: Dictionary = result as Dictionary
	all_cards = data.get("cards", [])
	for card in all_cards:
		var c: Dictionary = card as Dictionary
		_cards_by_id[c["id"]] = c


func get_card(id: String) -> Dictionary:
	return _cards_by_id.get(id, {})


func get_cards_by_rarity(rarity: String) -> Array:
	return all_cards.filter(func(c: Dictionary): return c.get("rarity") == rarity)


func get_cards_by_element(el: String) -> Array:
	return all_cards.filter(func(c: Dictionary): return c.get("el") == el)


func select_random_cards(pool: Array, count: int, linggen_el: String = "") -> Array:
	var selected: Array = []
	var remaining: Array = pool.duplicate(true)
	remaining.shuffle()
	for i in range(mini(count, remaining.size())):
		selected.append(remaining[i])
	return selected


func make_card(card_data: Dictionary) -> Dictionary:
	return card_data.duplicate(true)


func build_starter_deck(linggen_el: String) -> Array:
	var deck: Array = []
	for i in range(4):
		deck.append(make_card(get_card("huoya_0")))
	for i in range(3):
		deck.append(make_card(get_card("lingcao_0")))
	for i in range(2):
		deck.append(make_card(get_card("danhuo_0")))
	deck.append(make_card(get_card("yaolu_0")))
	if linggen_el == "fire":
		deck.append(make_card(get_card("huoya_0")))
	elif linggen_el == "wood":
		deck.append(make_card(get_card("lingcao_0")))
	elif linggen_el == "metal":
		deck.append(make_card(get_card("jinren_38")))
	return deck


func upgrade_card(card: Dictionary) -> Dictionary:
	var upgraded: Dictionary = card.duplicate(true)
	upgraded["upgraded"] = true
	var eff: Dictionary = upgraded.get("effects", {})
	var chg: Dictionary = upgraded.get("charge", {})
	if eff.has("dmg"):
		eff["dmg"] = int(eff["dmg"] * 1.5)
	if eff.has("blk"):
		eff["blk"] = int(eff["blk"] * 1.5)
	if eff.has("burn"):
		eff["burn"] = eff["burn"] + 1
	if eff.has("poison"):
		eff["poison"] = eff["poison"] + 2
	if eff.has("draw"):
		eff["draw"] = eff["draw"] + 1
	if chg.has("charges"):
		chg["charges"] = chg["charges"] + 1
	return upgraded