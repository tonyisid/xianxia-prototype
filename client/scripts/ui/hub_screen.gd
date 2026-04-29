extends Control

# ===== 洞府主界面 =====

signal start_run()
signal open_alchemy()
signal open_cultivation()

var G: Node
var cultivation: Node
var shop_events: Node


func _ready() -> void:
	G = get_node("/root/GameState")

	cultivation = Node.new()
	cultivation.set_script(load("res://scripts/core/cultivation.gd"))
	add_child(cultivation)

	shop_events = Node.new()
	shop_events.set_script(load("res://scripts/core/shop_events.gd"))
	add_child(shop_events)

	_build_ui()


func _build_ui() -> void:
	for child in get_children():
		if child is Control:
			child.queue_free()

	# 背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.1, 1)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -200
	vbox.offset_top = -250
	vbox.offset_right = 200
	vbox.offset_bottom = 250
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	# 标题
	var title := Label.new()
	title.text = "🏠 洞府"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.83, 0.71, 0.56))
	vbox.add_child(title)

	# 灵根+境界
	var lg_name: String = {"fire":"🔥火","wood":"🌿木","earth":"⛰️土","water":"💧水","metal":"⚔️金"}.get(G.linggen, "?")
	var info := Label.new()
	info.name = "InfoLabel"
	info.text = "%s灵根 | %s | 修为 %d/%d" % [lg_name, cultivation.realm_name(G.realm), G.xiuwei, cultivation.next_threshold(G.realm)]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(info)

	# 材料
	var mats := Label.new()
	mats.name = "MatsLabel"
	mats.text = "🌿灵草:%d  ⛏️矿石:%d  🔮妖丹:%d  💊突破丹:%d  ✨筑基丹:%d" % [G.lingcao, G.kuangshi, G.yaodan, G.po_jing_dan, G.zhu_ji_dan]
	mats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mats.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(mats)

	# 统计
	var stats := Label.new()
	stats.text = "历练:%d次 | 通关:%d次" % [G.runs, G.wins]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(stats)

	# 按钮区
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grid)

	var buttons: Array = [
		{"text": "⚔️ 历练", "desc": "进入幽冥谷", "action": "run"},
		{"text": "🧘 修炼", "desc": "打坐获得修为", "action": "meditate"},
		{"text": "⚗️ 炼丹", "desc": "消耗材料炼制丹药", "action": "alchemy"},
		{"text": "⚡ 悟道", "desc": "消耗200修为领悟神通", "action": "wudao"},
		{"text": "📖 功法阁", "desc": "查看卡牌收集", "action": "gongfa"},
		{"text": "📦 背包", "desc": "查看装备和存档", "action": "inventory"},
	]

	for btn_data: Dictionary in buttons:
		var btn := _make_hub_button(btn_data["text"], btn_data["desc"])
		var action: String = btn_data["action"]
		btn.pressed.connect(func(): _on_hub_action(action))
		grid.add_child(btn)

	# 突破按钮（条件显示）
	if cultivation.can_breakthrough():
		var bbtn := Button.new()
		bbtn.text = "✨ 突破！"
		bbtn.tooltip_text = "消耗丹药突破境界"
		bbtn.custom_minimum_size = Vector2(380, 40)
		bbtn.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		vbox.add_child(bbtn)
		bbtn.pressed.connect(_on_breakthrough)

	# 日志
	if G.collected_logs.size() > 0:
		var logs := Label.new()
		logs.text = "📜 仙人日志 %d/10" % G.collected_logs.size()
		logs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		logs.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
		vbox.add_child(logs)


func _make_hub_button(text: String, desc: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.tooltip_text = desc
	btn.custom_minimum_size = Vector2(180, 60)
	return btn


func _on_hub_action(action: String) -> void:
	match action:
		"run":
			start_run.emit()
		"meditate":
			var gain: int = cultivation.meditate()
			_build_ui()  # 刷新
		"alchemy":
			open_alchemy.emit()
		"wudao":
			if cultivation.wudao_available() and G.xiuwei >= 200:
				# TODO: 显示三选一界面
				var options: Array = cultivation.get_wudao_options()
				if options.size() > 0:
					cultivation.execute_wudao(options[0]["id"])
					_build_ui()
		"gongfa":
			pass  # TODO
		"inventory":
			pass  # TODO


func _on_breakthrough() -> void:
	if cultivation.execute_breakthrough():
		_build_ui()


func refresh() -> void:
	_build_ui()