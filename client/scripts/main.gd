extends Control

# ===== 主入口 — 游戏流程管理 =====

enum Screen {TITLE, LINGGEN, HUB, BATTLE, MAP_NODE, SHOP, EVENT, REST, CARD_SELECT, END, DRUG_SELECT}

var current_screen: Screen = Screen.TITLE
var screen_node: Control = null
var _current_map: Array = []
var _current_node_idx: int = 0
var _last_node_type: String = ""
var _last_is_elite: bool = false
var _pending_card_rewards: Array = []
var _is_run_victory: bool = false

var G: Node
var cards_db: Node
var combat: Node
var cultivation: Node
var shop_events: Node


func _ready() -> void:
	G = get_node("/root/GameState")
	cards_db = get_node("/root/CardsDB")
	combat = get_node("/root/CombatEngine")
	G.load_game()

	cultivation = Node.new()
	cultivation.set_script(load("res://scripts/core/cultivation.gd"))
	add_child(cultivation)

	shop_events = Node.new()
	shop_events.set_script(load("res://scripts/core/shop_events.gd"))
	add_child(shop_events)

	if G.linggen == "":
		_show_screen(Screen.LINGGEN)
	else:
		_show_screen(Screen.TITLE)


func _show_screen(screen: Screen) -> void:
	current_screen = screen
	if screen_node:
		screen_node.queue_free()
		screen_node = null

	match screen:
		Screen.TITLE:
			screen_node = _create_title_screen()
		Screen.LINGGEN:
			screen_node = _create_linggen_screen()
		Screen.HUB:
			screen_node = _create_hub_screen()
		Screen.DRUG_SELECT:
			screen_node = _create_drug_select_screen()
		Screen.MAP_NODE:
			screen_node = _create_map_node_screen()
		Screen.BATTLE:
			screen_node = _create_battle_screen()
		Screen.CARD_SELECT:
			screen_node = _create_card_select_screen()
		Screen.SHOP:
			screen_node = _create_shop_screen()
		Screen.EVENT:
			screen_node = _create_event_screen()
		Screen.REST:
			screen_node = _create_rest_screen()
		Screen.END:
			screen_node = _create_end_screen()

	if screen_node:
		add_child(screen_node)


# ===== 场景工厂 =====

func _create_title_screen() -> Control:
	var root := _make_bg()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -150; vbox.offset_top = -120
	vbox.offset_right = 150; vbox.offset_bottom = 120
	vbox.add_theme_constant_override("separation", 14)
	root.add_child(vbox)

	var lg: String = {"fire":"🔥火","wood":"🌿木","earth":"⛰️土","water":"💧水","metal":"⚔️金"}.get(G.linggen, "?")
	_add_label(vbox, "凡人修仙 · 卡牌肉鸽", 26, Color(0.83, 0.71, 0.56))
	_add_label(vbox, "Godot 4 原型", 14, Color(0.4, 0.4, 0.5))
	_add_label(vbox, "%s灵根 | 境界%s | 修为%d" % [lg, cultivation.realm_name(G.realm), G.xiuwei], 14, Color(0.6, 0.6, 0.7))

	var btn_hub := Button.new()
	btn_hub.text = "进入洞府"
	btn_hub.custom_minimum_size = Vector2(200, 40)
	vbox.add_child(btn_hub)
	btn_hub.pressed.connect(func(): _show_screen(Screen.HUB))

	var btn_reset := Button.new()
	btn_reset.text = "重置存档"
	btn_reset.custom_minimum_size = Vector2(200, 36)
	vbox.add_child(btn_reset)
	btn_reset.pressed.connect(func():
		G.linggen = ""
		G.save_game()
		_show_screen(Screen.LINGGEN)
	)

	# 如果是断点续玩
	if G.in_run:
		var btn_continue := Button.new()
		btn_continue.text = "继续历练 (第%d层)" % (G.current_layer + 1)
		btn_continue.custom_minimum_size = Vector2(200, 40)
		btn_continue.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		vbox.add_child(btn_continue)
		btn_continue.pressed.connect(_on_continue_run)

	return root


func _create_linggen_screen() -> Control:
	var scene: PackedScene = load("res://scenes/hub/linggen.tscn")
	var node: Control = scene.instantiate()
	node.linggen_confirmed.connect(func(lg: String):
		G.linggen = lg
		G.realm = 1
		G.xiuwei = 0
		G.lingcao = 3
		G.kuangshi = 2
		G.yaodan = 0
		G.save_game()
		_show_screen(Screen.HUB)
	)
	return node


func _create_hub_screen() -> Control:
	var scene: PackedScene = load("res://scenes/hub/hub.tscn")
	var node: Control = scene.instantiate()
	node.start_run.connect(_on_start_run)
	return node


func _create_battle_screen() -> Control:
	var scene: PackedScene = load("res://scenes/battle/battle.tscn")
	var node: Control = scene.instantiate()
	if not combat.fight_ended.is_connected(_on_battle_complete):
		combat.fight_ended.connect(_on_battle_complete)
	return node


# ===== 丹药选择 =====

func _create_drug_select_screen() -> Control:
	var root := _make_bg()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -250; vbox.offset_top = -150
	vbox.offset_right = 250; vbox.offset_bottom = 150
	vbox.add_theme_constant_override("separation", 12)
	root.add_child(vbox)

	_add_label(vbox, "选择携带丹药", 24, Color(0.83, 0.71, 0.56))
	_add_label(vbox, "选择1种丹药带入秘境（每场战斗可用1次）", 13, Color(0.6, 0.6, 0.7))

	var pills: Array = [
		{"name": "回春丹", "desc": "回复15HP", "emoji": "💊"},
		{"name": "凝元丹", "desc": "下次攻击+5", "emoji": "⚡"},
		{"name": "护脉丹", "desc": "获得10格挡", "emoji": "🛡️"},
	]

	for pill: Dictionary in pills:
		var btn := Button.new()
		btn.text = "%s %s — %s" % [pill["emoji"], pill["name"], pill["desc"]]
		btn.custom_minimum_size = Vector2(480, 44)
		vbox.add_child(btn)
		var pname: String = pill["name"]
		btn.pressed.connect(func(): _on_drug_chosen(pname))

	var back_btn := Button.new()
	back_btn.text = "返回洞府"
	back_btn.custom_minimum_size = Vector2(200, 36)
	vbox.add_child(back_btn)
	back_btn.pressed.connect(func(): _show_screen(Screen.HUB))

	return root


func _on_drug_chosen(pill_name: String) -> void:
	G.selected_pill = pill_name
	_on_drug_confirm()


func _on_drug_confirm() -> void:
	# 开始历练 — 先清空上局残留，再设置新局
	G.reset_run()
	G.in_run = true
	G.run_seed = randi()
	G.current_layer = 0
	G.lingshi = 0
	G.deck = cards_db.build_starter_deck(G.linggen)
	G.max_hp = 50
	G.hp = 50
	G.used_pill_this_fight = false
	G.runs += 1
	G.save_game()

	# 生成地图
	var mg := Node.new()
	mg.set_script(load("res://scripts/core/map_gen.gd"))
	add_child(mg)
	_current_map = mg.generate(G.run_seed)
	mg.queue_free()

	_current_node_idx = 0
	_enter_map_node(_current_node_idx)


func _enter_map_node(layer: int) -> void:
	G.current_layer = layer
	var options: Array = _current_map[layer]

	if options.size() == 1:
		_handle_node_choice(options[0])
	else:
		_show_screen(Screen.MAP_NODE)


func _handle_node_choice(node_type: String) -> void:
	_last_node_type = node_type
	_last_is_elite = false

	match node_type:
		"F":
			_start_fight(false)
		"E":
			_last_is_elite = true
			_start_fight(true)
		"R":
			_show_screen(Screen.REST)
		"S":
			_show_screen(Screen.SHOP)
		"?":
			_show_screen(Screen.EVENT)
		"B":
			_start_boss()


# ===== 战斗 =====

func _start_fight(is_elite: bool) -> void:
	var enemy_id: String
	if is_elite:
		enemy_id = ["boar", "spider"][randi() % 2]
	else:
		var normals: Array = ["wolf", "snake", "vine", "bat", "toad"]
		enemy_id = normals[randi() % normals.size()]

	_show_screen(Screen.BATTLE)
	if screen_node and screen_node.has_method("start_battle"):
		screen_node.start_battle(enemy_id, _current_node_idx)


func _start_boss() -> void:
	_show_screen(Screen.BATTLE)
	if screen_node and screen_node.has_method("start_battle"):
		screen_node.start_battle("boss", _current_node_idx)


func _on_battle_complete(victory: bool) -> void:
	if combat.fight_ended.is_connected(_on_battle_complete):
		combat.fight_ended.disconnect(_on_battle_complete)

	# 同步HP状态
	G.hp = combat.player_hp
	G.max_hp = combat.player_max_hp

	if victory:
		_on_battle_victory()
	else:
		_on_battle_defeat()


func _on_battle_victory() -> void:
	# 发放奖励
	match _last_node_type:
		"F":
			G.lingcao += 2
			G.lingshi += 15
			_show_card_reward(3, false)
		"E":
			G.lingcao += 3
			G.kuangshi += 2
			G.yaodan += 1
			G.lingshi += 30
			_show_card_reward(4, true)
		"B":
			G.lingcao += 5
			G.kuangshi += 3
			G.yaodan += 2
			_show_artifact_select()
		_:
			G.lingcao += 2
			_show_card_reward(3, false)

	# 尝试掉落仙人日志
	if _last_node_type == "E" and randf() < 0.15:
		_try_drop_log()
	elif _last_node_type == "F" and randf() < 0.30:
		_try_drop_log()

	G.save_game()


func _on_battle_defeat() -> void:
	_is_run_victory = false
	# 部分奖励
	G.lingcao += _current_node_idx + 1
	if _current_node_idx >= 3:
		G.kuangshi += int(_current_node_idx / 2)
	G.in_run = false
	G.reset_run()
	G.save_game()
	_show_end_screen(false)


func _try_drop_log() -> void:
	if G.collected_logs.size() >= 10:
		return
	var uncollected: Array = range(10).filter(func(i: int): return not i in G.collected_logs)
	if uncollected.is_empty():
		return
	uncollected.shuffle()
	G.collected_logs.append(uncollected[0])
	if G.collected_logs.size() >= 10:
		G.hard_mode_unlocked = true


# ===== 卡牌选择 =====

func _show_card_reward(count: int, can_remove: bool) -> void:
	_pending_card_rewards = _generate_card_rewards(count)
	_show_screen(Screen.CARD_SELECT)
	# 在创建后填充卡牌选项
	setup_card_select(screen_node, _pending_card_rewards, can_remove)


func _generate_card_rewards(count: int) -> Array:
	# 按稀有度权重抽取
	var pool: Array = []
	for card: Dictionary in cards_db.all_cards:
		if card.get("rarity") == "starter":
			continue
		var weight: float = 1.0
		match card.get("rarity"):
			"white": weight = 60.0
			"green": weight = 35.0
			"blue": weight = 5.0
		# 灵根偏向
		if card.get("el") == G.linggen:
			weight *= 1.5
		for i in range(int(weight)):
			pool.append(card)

	var selected: Array = []
	var used_names: Array = []
	while selected.size() < count and pool.size() > 0:
		pool.shuffle()
		var candidate: Dictionary = pool[0]
		var cname: String = candidate.get("name", "")
		if cname in used_names:
			pool = pool.filter(func(c: Dictionary): return c.get("name") != cname)
			continue
		used_names.append(cname)
		selected.append(cards_db.make_card(candidate))
		pool = pool.filter(func(c: Dictionary): return c.get("name") != cname)

	return selected


func _create_card_select_screen() -> Control:
	var root := _make_bg()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -250; vbox.offset_top = -200
	vbox.offset_right = 250; vbox.offset_bottom = 200
	vbox.add_theme_constant_override("separation", 10)
	root.add_child(vbox)

	_add_label(vbox, "获得功法", 22, Color(0.83, 0.71, 0.56))
	_add_label(vbox, "选择一张加入牌组", 13, Color(0.6, 0.6, 0.7))

	return root


func setup_card_select(root: Control, rewards: Array, can_remove: bool) -> void:
	var vbox: VBoxContainer = root.get_child(1) as VBoxContainer

	# 按钮容器
	var btn_container := VBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_container)

	for card: Dictionary in rewards:
		var cname: String = card.get("name", "")
		var rar: String = card.get("rarity", "")
		var rar_text: String = {"white":"白","green":"绿","blue":"蓝"}.get(rar, "?")
		var el: String = card.get("el", "none")
		var el_emoji: String = {"fire":"🔥","wood":"🌿","earth":"⛰️","water":"💧","metal":"⚔️","none":"🔮"}.get(el, "")

		var btn := Button.new()
		btn.text = "[%s] %s %s — %s" % [rar_text, el_emoji, cname, card.get("desc", "")]
		btn.custom_minimum_size = Vector2(480, 44)
		btn_container.add_child(btn)
		btn.pressed.connect(func():
			G.deck.append(card)
			if not cname in G.gongfa_collection:
				G.gongfa_collection.append(cname)
			G.save_game()
			_next_node()
		)

	# 跳过按钮
	var skip_btn := Button.new()
	skip_btn.text = "跳过"
	skip_btn.custom_minimum_size = Vector2(200, 36)
	vbox.add_child(skip_btn)
	skip_btn.pressed.connect(_next_node)

	# 移除牌按钮（精英战）
	if can_remove:
		var remove_btn := Button.new()
		remove_btn.text = "移除一张牌"
		remove_btn.custom_minimum_size = Vector2(200, 36)
		remove_btn.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		vbox.add_child(remove_btn)
		remove_btn.pressed.connect(func():
			_show_card_remove_screen()
		)


# ===== 法器选择 (Boss) =====

func _show_artifact_select() -> void:
	var root := _make_bg()
	screen_node = root
	add_child(root)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -250; vbox.offset_top = -150
	vbox.offset_right = 250; vbox.offset_bottom = 150
	vbox.add_theme_constant_override("separation", 10)
	root.add_child(vbox)

	_add_label(vbox, "Boss击败！", 24, Color(1, 0.85, 0.3))
	_add_label(vbox, "选择一件法器", 14, Color(0.6, 0.6, 0.7))

	var artifacts: Array = [
		{"id": "sword", "name": "玄铁剑", "desc": "攻击牌+3伤害", "emoji": "⚔️"},
		{"id": "bead", "name": "灵木珠", "desc": "每场战斗后回复3HP", "emoji": "🟢"},
		{"id": "talisman", "name": "聚灵符", "desc": "首回合多抽1张", "emoji": "📜"},
	]
	artifacts.shuffle()
	var shown: Array = artifacts.slice(0, 2)
	for i: int in range(shown.size()):
		var art: Dictionary = shown[i]
		var btn := Button.new()
		btn.text = "%s %s — %s" % [art["emoji"], art["name"], art["desc"]]
		btn.custom_minimum_size = Vector2(480, 44)
		vbox.add_child(btn)
		var art_id: String = art["id"]
		var art_name: String = art["name"]
		btn.pressed.connect(func():
			G.equipped_artifact = {"id": art_id, "name": art_name}
			G.save_game()
			_on_run_victory()
		)


# ===== 地图节点选择 =====

func _create_map_node_screen() -> Control:
	var root := _make_bg()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -250; vbox.offset_top = -150
	vbox.offset_right = 250; vbox.offset_bottom = 150
	vbox.add_theme_constant_override("separation", 10)
	root.add_child(vbox)

	_add_label(vbox, "幽冥谷 — 第%d层" % (_current_node_idx + 1), 22, Color(0.83, 0.71, 0.56))

	# HP显示
	_add_label(vbox, "HP: %d/%d  灵石: %d" % [G.hp, G.max_hp, G.lingshi], 14, Color(0.6, 0.6, 0.7))

	var options: Array = _current_map[_current_node_idx]
	var node_names: Dictionary = {"F":"战斗","E":"精英","R":"休整","S":"商店","?":"事件","B":"Boss"}
	var node_emojis: Dictionary = {"F":"⚔️","E":"💀","R":"🏕️","S":"🛒","?":"❓","B":"👑"}

	for nt: String in options:
		var btn := Button.new()
		btn.text = "%s %s" % [node_emojis.get(nt, "?"), node_names.get(nt, nt)]
		btn.custom_minimum_size = Vector2(300, 44)
		vbox.add_child(btn)
		var node_type: String = nt
		btn.pressed.connect(func(): _handle_node_choice(node_type))

	return root


# ===== 商店 =====

func _create_shop_screen() -> Control:
	var root := _make_bg()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -250; vbox.offset_top = -150
	vbox.offset_right = 250; vbox.offset_bottom = 150
	vbox.add_theme_constant_override("separation", 10)
	root.add_child(vbox)

	_add_label(vbox, "商店", 22, Color(0.95, 0.8, 0.2))
	_add_label(vbox, "灵石: %d" % G.lingshi, 14, Color(0.6, 0.6, 0.7))
	_add_label(vbox, "HP: %d/%d" % [G.hp, G.max_hp], 14, Color(0.6, 0.6, 0.7))

	var items: Array = [
		{"text": "移除一张牌 (50灵石)", "action": "remove"},
		{"text": "升级一张牌 (30灵石)", "action": "upgrade"},
		{"text": "购买一张牌 (40灵石)", "action": "buy"},
	]

	for item: Dictionary in items:
		var btn := Button.new()
		btn.text = item["text"]
		btn.custom_minimum_size = Vector2(400, 44)
		vbox.add_child(btn)
		var action: String = item["action"]
		btn.pressed.connect(func(): _shop_action(action))

	var leave_btn := Button.new()
	leave_btn.text = "离开商店"
	leave_btn.custom_minimum_size = Vector2(200, 36)
	vbox.add_child(leave_btn)
	leave_btn.pressed.connect(_next_node)

	return root


func _shop_action(action: String) -> void:
	match action:
		"remove":
			if G.lingshi >= 50:
				_show_card_remove_screen_shop()
			else:
				_flash_message("灵石不足！")
		"upgrade":
			if G.lingshi >= 30:
				_show_card_upgrade_screen()
			else:
				_flash_message("灵石不足！")
		"buy":
			if G.lingshi >= 40:
				_shop_buy_card()
			else:
				_flash_message("灵石不足！")


func _shop_buy_card() -> void:
	var green_cards: Array = cards_db.all_cards.filter(func(c: Dictionary): return c.get("rarity") == "green")
	if green_cards.is_empty():
		_flash_message("没有可购买的牌")
		return
	green_cards.shuffle()
	var picked: Dictionary = cards_db.make_card(green_cards[0])
	G.deck.append(picked)
	G.lingshi -= 40
	if not picked.get("name", "") in G.gongfa_collection:
		G.gongfa_collection.append(picked.get("name", ""))
	G.save_game()
	_flash_message("获得 [%s]" % picked.get("name", ""))
	_show_screen(Screen.SHOP)


func _show_card_upgrade_screen() -> void:
	_show_card_list_screen("选择升级的牌", "upgrade", func(idx: int):
		if G.lingshi >= 30:
			G.deck[idx] = cards_db.upgrade_card(G.deck[idx])
			G.lingshi -= 30
			G.save_game()
			_flash_message("升级成功！")
			_show_screen(Screen.SHOP)
	)


func _show_card_remove_screen_shop() -> void:
	_show_card_list_screen("选择移除的牌", "remove", func(idx: int):
		if G.lingshi >= 50:
			G.deck.remove_at(idx)
			G.lingshi -= 50
			G.save_game()
			_flash_message("已移除")
			_show_screen(Screen.SHOP)
	)


func _show_card_remove_screen() -> void:
	_show_card_list_screen("选择移除的牌", "remove", func(idx: int):
		G.deck.remove_at(idx)
		G.save_game()
		_flash_message("已移除")
	)


func _show_card_list_screen(title: String, mode: String, callback: Callable) -> void:
	var root := _make_bg()
	var old: Control = screen_node
	screen_node = root
	add_child(root)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 40; scroll.offset_bottom = -20
	scroll.offset_left = 100; scroll.offset_right = -100
	root.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	_add_label(vbox, title, 22, Color(0.83, 0.71, 0.56))

	for i: int in range(G.deck.size()):
		var card: Dictionary = G.deck[i]
		var btn := Button.new()
		var cname: String = card.get("name", "")
		var upgraded: String = "★" if card.get("upgraded", false) else ""
		var el: String = card.get("el", "none")
		var el_emoji: String = {"fire":"🔥","wood":"🌿","earth":"⛰️","water":"💧","metal":"⚔️","none":"🔮"}.get(el, "")
		btn.text = "%s%s %s — 费用:%d | %s" % [upgraded, el_emoji, cname, int(card.get("cost", 0)), card.get("desc", "")]
		btn.custom_minimum_size = Vector2(600, 36)
		vbox.add_child(btn)
		var idx: int = i
		btn.pressed.connect(func(): callback.call(idx))

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(200, 36)
	vbox.add_child(back_btn)
	back_btn.pressed.connect(func():
		if old:
			screen_node = old
			root.queue_free()
	)


# ===== 休整 =====

func _create_rest_screen() -> Control:
	var root := _make_bg()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -250; vbox.offset_top = -150
	vbox.offset_right = 250; vbox.offset_bottom = 150
	vbox.add_theme_constant_override("separation", 10)
	root.add_child(vbox)

	_add_label(vbox, "休整点", 22, Color(0.3, 0.8, 0.4))
	_add_label(vbox, "HP: %d/%d" % [G.hp, G.max_hp], 14, Color(0.6, 0.6, 0.7))

	var rest_texts: Array = [
		"篝火旁，你整理功法，思考下一步。",
		"远处传来低沉的嚎叫。这里不会有安宁。",
		"你闭上眼，灵气缓缓流转。境界似乎近了一步。",
	]
	rest_texts.shuffle()
	_add_label(vbox, rest_texts[0], 13, Color(0.5, 0.7, 0.5))

	var items: Array = [
		{"text": "休息 (回复30%HP)", "action": "heal"},
		{"text": "升级一张牌", "action": "upgrade"},
		{"text": "移除一张牌", "action": "remove"},
	]

	for item: Dictionary in items:
		var btn := Button.new()
		btn.text = item["text"]
		btn.custom_minimum_size = Vector2(300, 44)
		vbox.add_child(btn)
		var action: String = item["action"]
		btn.pressed.connect(func(): _rest_action(action))

	return root


func _rest_action(action: String) -> void:
	match action:
		"heal":
			var heal_amount: int = maxi(1, int(G.max_hp * 0.3))
			G.hp = mini(G.hp + heal_amount, G.max_hp)
			G.save_game()
			_flash_message("回复 %d HP" % heal_amount)
			_next_node()
		"upgrade":
			_show_card_list_screen("选择升级的牌", "rest_upgrade", func(idx: int):
				G.deck[idx] = cards_db.upgrade_card(G.deck[idx])
				G.save_game()
				_flash_message("升级成功！")
				_next_node()
			)
		"remove":
			_show_card_list_screen("选择移除的牌", "rest_remove", func(idx: int):
				G.deck.remove_at(idx)
				G.save_game()
				_flash_message("已移除")
				_next_node()
			)


# ===== 事件 =====

func _create_event_screen() -> Control:
	var root := _make_bg()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -300; vbox.offset_top = -200
	vbox.offset_right = 300; vbox.offset_bottom = 200
	vbox.add_theme_constant_override("separation", 10)
	root.add_child(vbox)

	var event: Dictionary = shop_events.get_random_event()
	_add_label(vbox, event.get("name", "事件"), 22, Color(0.5, 0.5, 0.9))
	_add_label(vbox, event.get("desc", ""), 14, Color(0.7, 0.7, 0.8))
	_add_label(vbox, "HP: %d/%d  灵石: %d" % [G.hp, G.max_hp, G.lingshi], 13, Color(0.6, 0.6, 0.7))

	for i: int in range(event.get("options", []).size()):
		var opt: Dictionary = event["options"][i]
		var btn := Button.new()
		btn.text = opt.get("text", "")
		btn.custom_minimum_size = Vector2(520, 44)
		vbox.add_child(btn)
		var idx: int = i
		btn.pressed.connect(func():
			var result: Dictionary = shop_events.resolve_event(event, idx)
			_flash_message(result.get("message", ""))
			_next_node()
		)

	return root


# ===== 结束 =====

func _create_end_screen() -> Control:
	var root := _make_bg()
	var is_victory: bool = _is_run_victory

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -200; vbox.offset_top = -150
	vbox.offset_right = 200; vbox.offset_bottom = 150
	vbox.add_theme_constant_override("separation", 12)
	root.add_child(vbox)

	if is_victory:
		_add_label(vbox, "通关！", 28, Color(1, 0.85, 0.3))
		_add_label(vbox, "你击败了巨蝠妖，成功走出幽冥谷。", 14, Color(0.6, 0.6, 0.7))
	else:
		_add_label(vbox, "历练结束", 24, Color(0.9, 0.3, 0.3))
		_add_label(vbox, "你在幽冥谷中倒下...", 14, Color(0.5, 0.5, 0.6))

	_add_label(vbox, "到达第%d层" % (_current_node_idx + 1), 14, Color(0.7, 0.7, 0.8))
	_add_label(vbox, "牌组: %d张" % G.deck.size(), 14, Color(0.7, 0.7, 0.8))
	_add_label(vbox, "灵石: %d" % G.lingshi, 14, Color(0.7, 0.7, 0.8))

	var back_btn := Button.new()
	back_btn.text = "返回洞府"
	back_btn.custom_minimum_size = Vector2(200, 44)
	vbox.add_child(back_btn)
	back_btn.pressed.connect(_back_to_hub)

	return root


func _on_run_victory() -> void:
	_is_run_victory = true
	G.wins += 1
	G.xiuwei += _current_node_idx * 20 + 100  # 通关修为奖励
	G.in_run = false
	G.reset_run()
	G.save_game()
	_show_end_screen(true)


func _show_end_screen(victory: bool) -> void:
	_show_screen(Screen.END)


func _back_to_hub() -> void:
	G.lingcao += 1  # 保底材料
	G.xiuwei += _current_node_idx * 10  # 每层给10修为
	G.in_run = false
	G.reset_run()
	G.save_game()
	_show_screen(Screen.HUB)


# ===== 流程控制 =====

func _on_start_run() -> void:
	_show_screen(Screen.DRUG_SELECT)


func _on_continue_run() -> void:
	# 断点续玩 - 重建地图
	var mg := Node.new()
	mg.set_script(load("res://scripts/core/map_gen.gd"))
	add_child(mg)
	_current_map = mg.generate(G.run_seed)
	mg.queue_free()
	_current_node_idx = G.current_layer
	_enter_map_node(_current_node_idx)


func _next_node() -> void:
	_current_node_idx += 1
	if _current_node_idx >= _current_map.size():
		# 如果没有经过Boss就结束了（不应发生）
		_on_run_victory()
	else:
		_enter_map_node(_current_node_idx)


func _flash_message(msg: String) -> void:
	print("[游戏] %s" % msg)
	# 简单控制台输出，后续可改为弹窗
	if screen_node:
		var label := Label.new()
		label.text = msg
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		label.position = Vector2(300, 20)
		label.custom_minimum_size = Vector2(680, 30)
		screen_node.add_child(label)
		var tween := screen_node.create_tween()
		tween.tween_property(label, "modulate:a", 0.0, 2.0)
		tween.tween_callback(label.queue_free)


# ===== 辅助 =====

func _make_bg() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.06, 0.1, 1)
	root.add_child(bg)
	return root


func _add_label(parent: Node, text: String, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
