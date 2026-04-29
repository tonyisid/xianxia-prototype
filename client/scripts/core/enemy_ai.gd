extends Node

# ===== 敌人意图引擎 =====

# 加权随机选择意图，不连续2回合相同（除非只剩1种）

var _last_intent_type: String = ""


func choose_intent(enemy_data: Dictionary, hp: int, max_hp: int) -> Dictionary:
	var is_boss: bool = enemy_data.get("is_boss", false)
	var is_enrage: bool = false

	if is_boss:
		var enrage_below: float = enemy_data.get("enrage_below", 0.3)
		is_enrage = hp <= int(max_hp * enrage_below)

	var pool: Array
	if is_boss and is_enrage:
		pool = enemy_data.get("intents_enrage", [])
	else:
		pool = enemy_data.get("intents", [])

	if pool.is_empty():
		pool = enemy_data.get("intents_normal", [])

	if pool.size() == 1:
		_last_intent_type = pool[0].get("type", "")
		return pool[0]

	# 过滤掉和上次相同的意图（如果还有其他选项）
	var filtered: Array = pool.filter(func(i: Dictionary): return i.get("type", "") != _last_intent_type)
	if filtered.is_empty():
		filtered = pool

	# 加权随机
	var total_w: float = 0.0
	for intent: Dictionary in filtered:
		total_w += float(intent.get("weight", 1))

	var roll: float = randf() * total_w
	var cumulative: float = 0.0
	for intent: Dictionary in filtered:
		cumulative += float(intent.get("weight", 1))
		if roll <= cumulative:
			_last_intent_type = intent.get("type", "")
			return intent

	var chosen: Dictionary = filtered[0]
	_last_intent_type = chosen.get("type", "")
	return chosen


func reset() -> void:
	_last_intent_type = ""