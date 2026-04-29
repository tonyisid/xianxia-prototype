extends Control

# ===== 主入口 — 游戏流程管理 =====

enum Screen {TITLE, LINGGEN, HUB, BATTLE, MAP, SHOP, EVENT, REST}

var current_screen: Screen = Screen.TITLE
var screen_node: Control = null

# 游戏状态引用
var G: Node
var cards_db: Node


func _ready() -> void:
	G = get_node("/root/GameState")
	cards_db = get_node("/root/CardsDB")

	# 尝试加载存档
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

	if screen_node:
		add_child(screen_node)


func _create_title_screen() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.06, 0.1, 1)
	root.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -150
	vbox.offset_top = -100
	vbox.offset_right = 150
	vbox.offset_bottom = 100
	vbox.add_theme_constant_override("separation", 16)
	root.add_child(vbox)

	var title := Label.new()
	title.text = "凡人修仙 · 卡牌肉鸽"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.83, 0.71, 0.56))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Godot 4 原型 v0.1"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(sub)

	var info := Label.new()
	info.text = "灵根: %s | 境界: %d层 | 修为: %d" % [_linggen_name(G.linggen), G.realm, G.xiuwei]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)

	var btn_battle := Button.new()
	btn_battle.text = "⚔️ 进入幽冥谷"
	btn_battle.custom_minimum_size = Vector2(200, 40)
	vbox.add_child(btn_battle)
	btn_battle.pressed.connect(func(): _start_run())

	var btn_reset := Button.new()
	btn_reset.text = "🔄 重置存档"
	btn_reset.custom_minimum_size = Vector2(200, 36)
	vbox.add_child(btn_reset)
	btn_reset.pressed.connect(func(): G.linggen = ""; G.save_game(); _show_screen(Screen.LINGGEN))

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
		_show_screen(Screen.TITLE)
	)
	return node


func _create_hub_screen() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	return root


func _create_battle_screen() -> Control:
	var scene: PackedScene = load("res://scenes/battle/battle.tscn")
	var node: Control = scene.instantiate()
	return node


func _create_map_screen() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	return root


func _start_run() -> void:
	G.in_run = true
	G.run_seed = randi()
	G.current_layer = 0
	G.lingshi = 0
	G.deck = cards_db.build_starter_deck(G.linggen)
	G.reset_run()
	G.save_game()

	# 生成地图
	var map_gen_script := load("res://scripts/core/map_gen.gd")
	var map_gen := Node.new()
	map_gen.set_script(map_gen_script)
	add_child(map_gen)
	var map_data: Array = map_gen.generate(G.run_seed)
	map_gen.queue_free()

	# 进入第一层战斗
	_enter_node(0)


func _enter_node(layer: int) -> void:
	# TODO: 根据map_data[layer]类型决定进入哪个场景
	# 暂时都进战斗
	G.current_layer = layer
	var enemy_id: String = _pick_enemy(layer)

	screen_node = _create_battle_screen()
	add_child(screen_node)
	screen_node.start_battle(enemy_id, layer)


func _pick_enemy(layer: int) -> String:
	# Boss
	if layer >= 11:
		return "boss"
	# 精英 (层3, 9)
	if layer == 2 or layer == 8:
		return ["boar", "spider"][randi() % 2]
	# 普通
	var normals: Array = ["wolf", "snake", "vine", "bat", "toad"]
	return normals[randi() % normals.size()]


func _linggen_name(lg: String) -> String:
	return {"fire":"🔥火","wood":"🌿木","earth":"⛰️土","water":"💧水","metal":"⚔️金"}.get(lg, "未觉醒")