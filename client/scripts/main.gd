extends Control

# ===== 主入口 — 游戏流程管理 =====

enum Screen {TITLE, LINGGEN, HUB, BATTLE, MAP, SHOP, EVENT, REST, CARD_SELECT}

var current_screen: Screen = Screen.TITLE
var screen_node: Control = null
var map_data: Array = []

var G: Node
var cards_db: Node


func _ready() -> void:
	G = get_node("/root/GameState")
	cards_db = get_node("/root/CardsDB")
	G.load_game()

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
		Screen.BATTLE:
			screen_node = _create_battle_screen()
		Screen.MAP:
			screen_node = _create_map_screen()
		Screen.CARD_SELECT:
			screen_node = _create_card_select_screen()
		Screen.EVENT:
			screen_node = _create_event_screen()
		Screen.REST:
			screen_node = _create_rest_screen()
		Screen.SHOP:
			screen_node = _create_shop_screen()

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
	_add_label(vbox, "%s灵根 | 境界%s | 修为%d" % [lg, G.realm, G.xiuwei], 14, Color(0.6, 0.6, 0.7))

	var btn_hub := Button.new()
	btn_hub.text = "🏠 进入洞府"
	btn_hub.custom_minimum_size = Vector2(200, 40)
	vbox.add_child(btn_hub)
	btn_hub.pressed.connect(func(): _show_screen(Screen.HUB))

	var btn_reset := Button.new()
	btn_reset.text = "🔄 重置存档"
	btn_reset.custom_minimum_size = Vector2(200, 36)
	vbox.add_child(btn_reset)
	btn_reset.pressed.connect(func():
		G.linggen = ""
		G.save_game()
		_show_screen(Screen.LINGGEN)
	)
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
	return node


func _create_battle_screen() -> Control:
	var scene: PackedScene = load("res://scenes/battle/battle.tscn")
	return scene.instantiate()


func _create_map_screen() -> Control:
	var root := _make_bg()
	_add_label(root, "🗺️ 幽冥谷 — 地图（待实现）", 20, Color(0.83, 0.71, 0.56))
	return root


func _create_card_select_screen() -> Control:
	var root := _make_bg()
	_add_label(root, "选择功法（待实现）", 20, Color(0.83, 0.71, 0.56))
	return root


func _create_event_screen() -> Control:
	var root := _make_bg()
	_add_label(root, "事件（待实现）", 20, Color(0.83, 0.71, 0.56))
	return root


func _create_rest_screen() -> Control:
	var root := _make_bg()
	_add_label(root, "休整点（待实现）", 20, Color(0.83, 0.71, 0.56))
	return root


func _create_shop_screen() -> Control:
	var root := _make_bg()
	_add_label(root, "商店（待实现）", 20, Color(0.83, 0.71, 0.56))
	return root


# ===== 游戏流程 =====

func _start_run() -> void:
	G.in_run = true
	G.run_seed = randi()
	G.current_layer = 0
	G.lingshi = 0
	G.deck = cards_db.build_starter_deck(G.linggen)
	G.reset_run()
	G.max_hp = 50
	G.hp = 50
	G.selected_pill = "回春丹"
	G.save_game()

	# 生成地图
	var mg := Node.new()
	mg.set_script(load("res://scripts/core/map_gen.gd"))
	add_child(mg)
	map_data = mg.generate(G.run_seed)
	mg.queue_free()

	_enter_node(0)


func _enter_node(layer: int) -> void:
	G.current_layer = layer
	var enemy_id: String = _pick_enemy(layer)

	screen_node = _create_battle_screen()
	add_child(screen_node)
	screen_node.start_battle(enemy_id, layer)


func _pick_enemy(layer: int) -> String:
	if layer >= 11:
		return "boss"
	if layer == 2 or layer == 8:
		return ["boar", "spider"][randi() % 2]
	var normals: Array = ["wolf", "snake", "vine", "bat", "toad"]
	return normals[randi() % normals.size()]


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