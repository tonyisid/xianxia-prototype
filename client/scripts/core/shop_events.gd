extends Node

# ===== 炼丹 + 炼器 + 商店 + 事件系统 =====

var G: Node
var cards_db: Node


func _ready() -> void:
	G = get_node("/root/GameState")
	cards_db = get_node("/root/CardsDB")


# ===== 炼丹 =====

const DAN_RECIPES: Array = [
	{"id": "poJingDan", "name": "突破丹", "cost": {"lingcao": 2, "yaodan": 1}, "desc": "炼气层间突破消耗品", "type": "breakthrough"},
	{"id": "zhuJiDan", "name": "筑基丹", "cost": {"lingcao": 3, "kuangshi": 2, "yaodan": 2}, "desc": "筑基突破消耗品", "type": "breakthrough"},
	{"id": "xiaohuichun", "name": "小回春丹", "cost": {"lingcao": 2}, "desc": "永久maxHp+5", "type": "equip", "effect": {"max_hp": 5}},
	{"id": "ningqi", "name": "凝气丹", "cost": {"lingcao": 2, "kuangshi": 1}, "desc": "每场战斗灵力+1", "type": "equip", "effect": {"max_sp": 1}},
	{"id": "tiebi", "name": "铁壁丹", "cost": {"lingcao": 1, "kuangshi": 2}, "desc": "每场战斗初始格挡+3", "type": "equip", "effect": {"init_blk": 3}},
	{"id": "cuidu", "name": "淬毒丹", "cost": {"lingcao": 2, "yaodan": 1}, "desc": "中毒牌+2中毒", "type": "equip", "effect": {"poison_bonus": 2}},
	{"id": "lieyan", "name": "烈焰丹", "cost": {"lingcao": 2, "yaodan": 1}, "desc": "灼烧牌+2灼烧", "type": "equip", "effect": {"burn_bonus": 2}},
	{"id": "xisui", "name": "洗髓丹", "cost": {"lingcao": 3, "kuangshi": 2, "yaodan": 1}, "desc": "下次历练移除1张起始牌", "type": "one_shot"},
]


func get_available_recipes() -> Array:
	return DAN_RECIPES.duplicate(true)


func can_craft(recipe_id: String) -> bool:
	var recipe: Dictionary = _find_recipe(recipe_id)
	if recipe.is_empty():
		return false
	var cost: Dictionary = recipe.get("cost", {})
	for mat: String in cost.keys():
		var needed: int = cost[mat]
		var have: int = _get_material(mat)
		if have < needed:
			return false
	return true


func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		return false
	var recipe: Dictionary = _find_recipe(recipe_id)
	var cost: Dictionary = recipe.get("cost", {})
	for mat: String in cost.keys():
		_spend_material(mat, cost[mat])

	var rtype: String = recipe.get("type", "")
	match rtype:
		"breakthrough":
			_add_pill(recipe_id)
		"equip":
			pass  # TODO: 装备丹药到角色
		"one_shot":
			pass
	G.save_game()
	return true


func _find_recipe(id: String) -> Dictionary:
	for r: Dictionary in DAN_RECIPES:
		if r["id"] == id:
			return r
	return {}


func _get_material(mat: String) -> int:
	match mat:
		"lingcao": return G.lingcao
		"kuangshi": return G.kuangshi
		"yaodan": return G.yaodan
		_: return 0


func _spend_material(mat: String, amount: int) -> void:
	match mat:
		"lingcao": G.lingcao -= amount
		"kuangshi": G.kuangshi -= amount
		"yaodan": G.yaodan -= amount


func _add_pill(id: String) -> void:
	match id:
		"poJingDan": G.po_jing_dan += 1
		"zhuJiDan": G.zhu_ji_dan += 1


# ===== 商店 =====

func shop_remove_cost() -> int:
	return 50


func shop_upgrade_cost() -> int:
	return 30


func shop_buy_cost() -> int:
	return 40


func shop_remove_card(deck: Array, idx: int) -> Array:
	if G.lingshi < shop_remove_cost():
		return deck
	if idx < 0 or idx >= deck.size():
		return deck
	G.lingshi -= shop_remove_cost()
	deck.remove_at(idx)
	return deck


func shop_buy_card(deck: Array) -> Array:
	if G.lingshi < shop_buy_cost():
		return deck
	var green_cards: Array = cards_db.get_cards_by_rarity("green")
	if green_cards.is_empty():
		return deck
	green_cards.shuffle()
	var picked: Dictionary = cards_db.make_card(green_cards[0])
	deck.append(picked)
	G.lingshi -= shop_buy_cost()
	return deck


func shop_upgrade_card(deck: Array, idx: int) -> Array:
	if G.lingshi < shop_upgrade_cost():
		return deck
	if idx < 0 or idx >= deck.size():
		return deck
	deck[idx] = cards_db.upgrade_card(deck[idx])
	G.lingshi -= shop_upgrade_cost()
	return deck


# ===== 事件 =====

const EVENTS: Array = [
	{
		"id": "xianren",
		"name": "仙人指路",
		"desc": "一位老道士出现在你面前，指引三条路。",
		"options": [
			{"text": "获得一张稀有功法", "reward": {"type": "rare_card"}},
			{"text": "获得灵草×5 矿石×3", "reward": {"type": "material", "lingcao": 5, "kuangshi": 3}},
			{"text": "获得100修为", "reward": {"type": "xiuwei", "amount": 100}},
		]
	},
	{
		"id": "duju",
		"name": "赌局",
		"desc": "一位赌仙邀请你对赌。",
		"options": [
			{"text": "押50灵石（50%赢150）", "reward": {"type": "gamble", "cost": 50, "win": 150}},
			{"text": "不赌，拿30灵石走人", "reward": {"type": "lingshi", "amount": 30}},
		]
	},
	{
		"id": "baoxiang",
		"name": "宝箱",
		"desc": "你发现了一座古修洞府。",
		"options": [
			{"text": "直接开（70%稀有功法/30%-10HP）", "reward": {"type": "risk_box"}},
			{"text": "小心打开（100%绿功法）", "reward": {"type": "safe_box"}},
		]
	},
	{
		"id": "xidemon",
		"name": "心魔",
		"desc": "心魔试炼！面对自己。",
		"options": [
			{"text": "迎战心魔", "reward": {"type": "heart_demon"}},
		]
	},
	{
		"id": "jitan",
		"name": "远古祭坛",
		"desc": "一座散发着微光的祭坛。",
		"options": [
			{"text": "献祭1张牌→获得稀有功法", "reward": {"type": "sacrifice_card"}},
			{"text": "献祭10HP→+5maxHP", "reward": {"type": "sacrifice_hp"}},
		]
	},
]


func get_random_event() -> Dictionary:
	var pool: Array = EVENTS.duplicate(true)
	pool.shuffle()
	return pool[0]


func resolve_event(event: Dictionary, option_idx: int) -> Dictionary:
	var options: Array = event.get("options", [])
	if option_idx < 0 or option_idx >= options.size():
		return {"success": false}
	var opt: Dictionary = options[option_idx]
	var reward: Dictionary = opt.get("reward", {})
	var rtype: String = reward.get("type", "")

	var result: Dictionary = {"success": true, "message": ""}

	match rtype:
		"material":
			G.lingcao += reward.get("lingcao", 0)
			G.kuangshi += reward.get("kuangshi", 0)
			G.yaodan += reward.get("yaodan", 0)
			result["message"] = "获得材料！"
		"xiuwei":
			G.xiuwei += reward.get("amount", 0)
			result["message"] = "获得%d修为！" % reward.get("amount", 0)
		"lingshi":
			G.lingshi += reward.get("amount", 0)
			result["message"] = "获得%d灵石！" % reward.get("amount", 0)
		"gamble":
			if G.lingshi >= reward.get("cost", 0):
				G.lingshi -= reward.get("cost", 0)
				if randf() < 0.5:
					G.lingshi += reward.get("win", 0)
					result["message"] = "赢了！+%d灵石！" % reward.get("win", 0)
				else:
					result["message"] = "输了...-%d灵石" % reward.get("cost", 0)
			else:
				result["message"] = "灵石不够！"
				result["success"] = false
		"rare_card":
			result["message"] = "获得一张稀有功法！"
			# TODO: 添加到牌组
		"risk_box":
			if randf() < 0.7:
				result["message"] = "宝箱里有稀有功法！"
			else:
				result["message"] = "陷阱！-10HP"
		"safe_box":
			result["message"] = "小心打开，获得绿功法。"
		"heart_demon":
			result["message"] = "心魔战斗！（待实现）"
		"sacrifice_card":
			result["message"] = "献祭成功，获得稀有功法！"
		"sacrifice_hp":
			result["message"] = "献祭HP，+5maxHP！"

	G.save_game()
	return result


# ===== 休整点 =====

func rest_heal(hp: int, max_hp: int) -> int:
	"""回复30%HP"""
	var heal: int = maxi(1, int(max_hp * 0.3))
	return mini(hp + heal, max_hp)