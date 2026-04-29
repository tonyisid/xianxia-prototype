extends Node

# ===== 战斗引擎 =====

signal turn_started()
signal card_played(card: Dictionary, success: bool)
signal turn_ended()
signal fight_ended(victory: bool)
signal sheng_triggered(source_el: String, target_el: String, effect_desc: String)
signal shentong_triggered(shentong_id: String, desc: String)

# 五行相生映射表
var _sheng_map: Dictionary = {
	"fire":   {"target": "earth", "effect_type": "blk",  "value": 2},
	"earth":  {"target": "metal", "effect_type": "dmg",   "value": 2},
	"metal":  {"target": "water", "effect_type": "draw",  "value": 1},
	"water":  {"target": "wood",  "effect_type": "heal",  "value": 3},
	"wood":   {"target": "fire",  "effect_type": "burn",  "value": 2},
}

enum BattleState {IDLE, PLAYER_TURN, ENEMY_TURN, FIGHT_END}

var state: BattleState = BattleState.IDLE

var G: GameState
var cards_db: CardsDB

# 敌人状态
var enemy_hp: int = 0
var enemy_max_hp: int = 0
var enemy_block: int = 0
var enemy_burn: int = 0
var enemy_poison: int = 0
var enemy_intent: Dictionary = {}
var current_enemy_data: Dictionary = {}

# 玩家状态
var player_hp: int = 0
var player_max_hp: int = 0
var player_sp: int = 0
var player_max_sp: int = 3
var player_block: int = 0


func _ready() -> void:
	G = get_node("/root/GameState") as GameState
	cards_db = get_node("/root/CardsDB") as CardsDB


func start_fight(enemy_id: String, layer_idx: int) -> void:
	state = BattleState.IDLE
	var enemy_data: Dictionary = cards_db.get_card(enemy_id)
	current_enemy_data = enemy_data

	var scale: float = 1.0 + layer_idx * 0.04
	var hp_min_i: int = int(enemy_data["hp_base"]["min"])
	var hp_max_i: int = int(enemy_data["hp_base"]["max"])
	enemy_max_hp = int((randi() % (hp_max_i - hp_min_i + 1) + hp_min_i) * scale)
	enemy_hp = enemy_max_hp
	enemy_block = 0
	enemy_burn = 0
	enemy_poison = 0

	player_hp = G.hp
	player_max_hp = G.max_hp
	player_max_sp = 3 + _sp_bonus()
	player_sp = player_max_sp
	player_block = 0

	G.draw_pile = G.deck.duplicate(true)
	G.draw_pile.shuffle()
	G.discard_pile = []
	G.exhaust_pile = []
	G.hand = []

	G.reset_turn_trackers()
	G.charge_buffs = []
	G.baicao_per_turn = _baicao_bonus()
	G.fire_crow_bonus = 0

	start_turn()


func start_turn() -> void:
	state = BattleState.PLAYER_TURN
	player_sp = player_max_sp
	player_block = 0
	if G.baicao_per_turn > 0:
		player_block += G.baicao_per_turn
	_draw_cards(5 + _draw_bonus())
	_enemy_choose_intent()
	G.atk_played_this_turn = 0
	G.cards_played_this_turn = 0
	G.cards_by_name_this_turn = {}
	G.took_damage_this_turn = false
	turn_started.emit()


func _draw_cards(n: int) -> void:
	for i in n:
		if G.draw_pile.is_empty():
			if G.discard_pile.is_empty():
				break
			G.draw_pile = G.discard_pile.duplicate(true)
			G.draw_pile.shuffle()
			G.discard_pile = []
		if not G.draw_pile.is_empty():
			G.hand.append(G.draw_pile.pop_back())


func play_card(card: Dictionary) -> bool:
	if state != BattleState.PLAYER_TURN:
		return false
	var cost_i: int = int(card.get("cost", 0))
	if player_sp < cost_i:
		return false
	if not _check_card_condition(card):
		return false

	player_sp -= cost_i
	_apply_sheng(card)
	_apply_charge(card)

	var shentong_results: Array = _check_shentong_pre(card)
	_resolve_card_effects(card)

	for sid in shentong_results:
		shentong_triggered.emit(sid, _shentong_desc(sid))

	G.cards_played_this_turn += 1
	var cname: String = card.get("name", "")
	G.cards_by_name_this_turn[cname] = G.cards_by_name_this_turn.get(cname, 0) + 1
	if card.get("type") == "atk":
		G.atk_played_this_turn += 1

	card_played.emit(card, true)
	return true


func end_player_turn() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	state = BattleState.ENEMY_TURN

	G.charge_buffs = []
	G.discard_pile.append_array(G.hand)
	G.hand = []

	if enemy_burn > 0:
		var burn_dmg: int = enemy_burn
		enemy_burn = maxi(0, enemy_burn - 1)
		_apply_dmg_to_enemy(burn_dmg, false)

	turn_ended.emit()
	await get_tree().create_timer(0.5).timeout

	_enemy_act()

	if enemy_poison > 0:
		var poison_dmg: int = enemy_poison
		enemy_poison = maxi(0, enemy_poison - 1)
		_apply_dmg_to_enemy(poison_dmg, false)

	_check_survival_shentong()

	if enemy_hp <= 0:
		state = BattleState.FIGHT_END
		fight_ended.emit(true)
		return
	if player_hp <= 0:
		state = BattleState.FIGHT_END
		fight_ended.emit(false)
		return

	if player_block > 0:
		G.turns_without_damage = 0
	else:
		G.turns_without_damage += 1

	start_turn()


func _apply_sheng(card: Dictionary) -> void:
	var el: String = card.get("el", "none")
	if el == "none":
		return

	var target_map: Dictionary = _sheng_map.get(el, {})
	var tgt_el: String = target_map.get("target", "")
	if tgt_el != "":
		for src_el: String in G.sheng_ready.keys():
			var src_map: Dictionary = _sheng_map.get(src_el, {})
			if src_map.get("target", "") == el and G.sheng_ready.get(src_el, false):
				var e_type: String = src_map.get("effect_type", "")
				var eval: int = src_map.get("value", 0)
				var src_name: String = _el_name(src_el)
				var tgt_name: String = _el_name(el)
				sheng_triggered.emit(src_el, el, "%s生%s %s+%d" % [src_name, tgt_name, e_type, eval])
				G.sheng_ready.erase(src_el)
				_match_sheng_effect(card, e_type, eval)

	G.sheng_ready[el] = true


func _match_sheng_effect(card: Dictionary, effect_type: String, value: int) -> void:
	var eff: Dictionary = card.get("effects", {})
	match effect_type:
		"dmg": eff["dmg"] = eff.get("dmg", 0) + value
		"blk": eff["blk"] = eff.get("blk", 0) + value
		"burn": eff["burn"] = eff.get("burn", 0) + value
		"draw": eff["draw"] = eff.get("draw", 0) + value
		"heal": eff["heal"] = eff.get("heal", 0) + value


func _el_name(el: String) -> String:
	return {"fire":"火","wood":"木","earth":"土","water":"水","metal":"金"}.get(el, el)


func _apply_charge(card: Dictionary) -> void:
	if G.charge_buffs.is_empty():
		return
	var card_type: String = card.get("type", "")
	for i in range(G.charge_buffs.size() - 1, -1, -1):
		var cb: Dictionary = G.charge_buffs[i]
		if cb.get("type") == "any" or cb.get("type") == card_type:
			var chg_eff: Dictionary = cb.get("effect", {})
			var card_eff: Dictionary = card.get("effects", {})
			for k in chg_eff.keys():
				card_eff[k] = card_eff.get(k, 0) + chg_eff[k]
			cb["charges"] = cb.get("charges", 1) - 1
			if cb.get("charges", 0) <= 0:
				G.charge_buffs.remove_at(i)


func _check_card_condition(card: Dictionary) -> bool:
	var cond: Dictionary = card.get("condition", {})
	if cond.is_empty():
		return true
	match cond.get("type"):
		"hpBelow30":
			return player_hp <= player_max_hp * 3 / 10
		"hpBelow50":
			return player_hp <= player_max_hp / 2
		"tookDmgThisTurn":
			return G.took_damage_this_turn
		"handLE3":
			if G.hand.size() <= 3:
				var draw_n: int = cond.get("drawOnCond", 0)
				if draw_n > 0:
					_draw_cards(draw_n)
			return G.hand.size() <= 3
		"missingCards":
			pass
	return true


func _resolve_card_effects(card: Dictionary) -> void:
	var eff: Dictionary = card.get("effects", {})
	var special: Dictionary = card.get("special", {})
	var charge: Dictionary = card.get("charge", {})
	var cond: Dictionary = card.get("condition", {})

	if charge.has("charges"):
		G.charge_buffs.append({
			"type": charge.get("type"),
			"effect": charge.get("effect", {}).duplicate(true),
			"charges": charge.get("charges", 1)
		})

	if eff.has("dmg"):
		var dmg: int = _calc_dmg(eff.get("dmg", 0), card)
		_apply_dmg_to_enemy(dmg, true)

	if eff.has("blk"):
		player_block += int(eff["blk"])

	if eff.has("burn"):
		enemy_burn += int(eff["burn"])

	if eff.has("poison"):
		enemy_poison += int(eff["poison"])

	if eff.has("draw"):
		_draw_cards(int(eff["draw"]))

	if eff.has("heal"):
		var heal_amount: int = int(eff["heal"]) + _heal_bonus()
		player_hp = mini(player_hp + heal_amount, player_max_hp)

	if special.has("fireCrowBonus"):
		G.fire_crow_bonus += int(special["fireCrowBonus"])
	if special.has("danYiStacks"):
		G.dan_yi_stacks += int(special["danYiStacks"])
	if special.has("baicaoPerTurn"):
		G.baicao_per_turn += int(special["baicaoPerTurn"])


func _calc_dmg(base: int, card: Dictionary) -> int:
	var el: String = card.get("el", "none")
	var result: float = float(base)

	if G.linggen == "fire" and el == "fire":
		result += 1.0

	var cname: String = card.get("name", "")
	if cname == "火鸦":
		result += float(G.fire_crow_bonus)

	if el == "fire":
		result += float(G.dan_yi_stacks)

	if el == "fire":
		G.consecutive_fire_count += 1
		if G.consecutive_fire_count >= 3 and _has_shentong("fentian"):
			result *= 2.0
	else:
		G.consecutive_fire_count = 0

	if G.atk_played_this_turn >= 3 and _has_shentong("lianhuan"):
		result *= 1.5

	var crit_chance: float = _crit_chance()
	if G.linggen == "metal":
		crit_chance += 10.0
	if randf() < crit_chance / 100.0:
		result *= 2.0

	var cond: Dictionary = card.get("condition", {})
	if cond.get("type") == "missingCards":
		var missing: int = maxi(0, G.hand.size())
		result += float(missing * cond.get("dmgPerMissing", 0))

	return int(floor(result))


func _apply_dmg_to_enemy(dmg: int, apply_block: bool) -> void:
	if apply_block and enemy_block > 0:
		var blocked: int = mini(enemy_block, dmg)
		enemy_block -= blocked
		dmg -= blocked
	enemy_hp = maxi(0, enemy_hp - dmg)


func _enemy_choose_intent() -> void:
	var is_enrage: bool = current_enemy_data.get("is_boss", false) and \
		enemy_hp <= enemy_max_hp * current_enemy_data.get("enrage_below", 0.3)
	var pool: Array = current_enemy_data.get("intents_normal" if not is_enrage else "intents_enrage", [])

	var total_w: float = 0.0
	for intent: Dictionary in pool:
		total_w += float(intent.get("weight", 1))

	var roll: float = randf() * total_w
	var cumulative: float = 0.0
	for intent: Dictionary in pool:
		cumulative += float(intent.get("weight", 1))
		if roll <= cumulative:
			enemy_intent = intent
			return
	if pool.size() > 0:
		enemy_intent = pool[0]


func _enemy_act() -> void:
	var intent_type: String = enemy_intent.get("type", "atk")
	match intent_type:
		"atk":
			_apply_dmg_to_player(enemy_intent.get("value", 0))
		"atk_blk":
			enemy_block += int(enemy_intent.get("blk", 0))
			_apply_dmg_to_player(enemy_intent.get("value", 0))
		"atk_lifesteal":
			var lifesteal_dmg: int = enemy_intent.get("value", 0)
			_apply_dmg_to_player(lifesteal_dmg)
			player_hp = maxi(0, player_hp - lifesteal_dmg)
		"def":
			enemy_block += int(enemy_intent.get("blk", 0))
		"charge":
			pass
		"multi_atk":
			_apply_dmg_to_player(enemy_intent.get("value", 0))
		"special":
			pass
	_enemy_choose_intent()


func _apply_dmg_to_player(dmg: int) -> void:
	if player_block > 0:
		var blocked: int = mini(player_block, dmg)
		player_block -= blocked
		dmg -= blocked
	if dmg > 0:
		player_hp = maxi(0, player_hp - dmg)
		G.took_damage_this_turn = true


func _check_shentong_pre(card: Dictionary) -> Array:
	var triggered: Array = []
	var cname: String = card.get("name", "")
	var count: int = G.cards_by_name_this_turn.get(cname, 0)
	if count == 1 and _has_shentong("poxian"):
		triggered.append("poxian")
	if _has_shentong("lingsheng") and G.last_cost == card.get("cost", 0):
		G.consecutive_same_cost_count += 1
		if G.consecutive_same_cost_count >= 3:
			_draw_cards(1)
			triggered.append("lingsheng")
	else:
		G.consecutive_same_cost_count = 1
	G.last_cost = card.get("cost", 0)
	return triggered


func _check_survival_shentong() -> void:
	if _has_shentong("niepan") and player_hp <= 0:
		player_hp = 1
		shentong_triggered.emit("niepan", "涅槃触发！")
	if _has_shentong("bumie") and player_hp <= player_max_hp * 3 / 10 and player_block == 0:
		player_block += 15
		shentong_triggered.emit("bumie", "不灭金身触发！")


func _has_shentong(sid: String) -> bool:
	return sid in G.equipped_shentong


func _shentong_desc(sid: String) -> String:
	return {
		"fentian": "焚天",
		"lingsheng": "灵力共振",
		"lianhuan": "连环诀",
		"poxian": "破绽洞察",
		"niepan": "涅槃",
		"bumie": "不灭金身",
		"kuhuan": "枯荣",
		"houtut": "厚土"
	}.get(sid, sid)


func _sp_bonus() -> int:
	return 1 if G.equipped_daotong == "shuiyun" else 0


func _draw_bonus() -> int:
	return 1 if G.linggen == "water" else 0


func _heal_bonus() -> int:
	return 2 if G.linggen == "wood" else 0


func _crit_chance() -> float:
	return 5.0 if G.equipped_daotong == "jinrui" else 0.0


func _baicao_bonus() -> int:
	return G.baicao_per_turn