extends Control

# ===== 洞府主界面 =====

signal start_run()

var G: Node
var cultivation: Node
var shop_events: Node

var _modal: Control = null  # 当前弹窗
var _wudao_pending_options: Array = []


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
	# 清除旧的弹窗
	if _modal:
		_modal.queue_free()
		_modal = null

	for child in get_children():
		if child is Control and child != _modal:
			child.queue_free()

	# 背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.1, 1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	title.text = "洞府"
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
		# 用局部变量避免闭包陷阱
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

	# 装备/神通简要显示
	if not G.equipped_artifact.is_empty():
		var art_label := Label.new()
		art_label.text = "法器: %s" % G.equipped_artifact.get("name", "")
		art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		art_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.3))
		vbox.add_child(art_label)

	if G.equipped_shentong.size() > 0:
		var st_label := Label.new()
		var st_names: Array = []
		for sid: String in G.equipped_shentong:
			st_names.append(_shentong_name(sid))
		st_label.text = "神通: %s" % "、".join(st_names)
		st_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
		vbox.add_child(st_label)

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
			_do_meditate()
		"alchemy":
			_show_alchemy_modal()
		"wudao":
			_do_wudao()
		"gongfa":
			_show_gongfa_modal()
		"inventory":
			_show_inventory_modal()


func _do_meditate() -> void:
	var gain: int = cultivation.meditate()
	_flash("打坐获得 %d 修为" % gain)
	_build_ui()


func _on_breakthrough() -> void:
	if cultivation.execute_breakthrough():
		_flash("突破成功！境界提升至 %s" % cultivation.realm_name(G.realm))
		_build_ui()
	else:
		_flash("材料不足，无法突破")


# ===== 悟道 =====

func _do_wudao() -> void:
	if not cultivation.wudao_available():
		_flash("悟道冷却中，每小时1次")
		return
	if G.xiuwei < 200:
		_flash("修为不足200，无法悟道")
		return

	_wudao_pending_options = cultivation.get_wudao_options()
	if _wudao_pending_options.is_empty():
		_flash("已领悟全部神通！")
		return

	_show_wudao_selection()


func _show_wudao_selection() -> void:
	_close_modal()
	_modal = _make_modal_container()

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_modal.add_child(vbox)

	_add_modal_label(vbox, "悟道 — 选择神通", 22, Color(0.83, 0.71, 0.56))
	_add_modal_label(vbox, "消耗200修为选择一个神通", 14, Color(0.6, 0.6, 0.7))

	for st: Dictionary in _wudao_pending_options:
		var btn := Button.new()
		btn.text = "%s [%s] — %s" % [st["name"], st["cond"], st["desc"]]
		btn.custom_minimum_size = Vector2(480, 44)
		vbox.add_child(btn)
		var st_id: String = st["id"]
		btn.pressed.connect(func():
			if cultivation.execute_wudao(st_id):
				if G.equipped_shentong.size() < 2:
					G.equipped_shentong.append(st_id)
				G.save_game()
				_flash("领悟新神通：%s！" % st["name"])
				_close_modal()
				_build_ui()
		)

	var skip_btn := Button.new()
	skip_btn.text = "跳过"
	skip_btn.custom_minimum_size = Vector2(200, 36)
	vbox.add_child(skip_btn)
	skip_btn.pressed.connect(func():
		_close_modal()
		_build_ui()
	)


# ===== 炼丹 =====

func _show_alchemy_modal() -> void:
	_close_modal()
	_modal = _make_modal_container()

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 20; scroll.offset_bottom = -20
	scroll.offset_left = 20; scroll.offset_right = -20
	_modal.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	_add_modal_label(vbox, "炼丹炉", 22, Color(0.83, 0.71, 0.56))
	_add_modal_label(vbox, "材料: 🌿%d ⛏️%d 🔮%d  丹药: 💊%d ✨%d" % [G.lingcao, G.kuangshi, G.yaodan, G.po_jing_dan, G.zhu_ji_dan], 13, Color(0.6, 0.6, 0.7))

	for recipe: Dictionary in shop_events.get_available_recipes():
		var cost: Dictionary = recipe.get("cost", {})
		var cost_text: String = ""
		var parts: Array = []
		if cost.has("lingcao"): parts.append("🌿×%d" % cost["lingcao"])
		if cost.has("kuangshi"): parts.append("⛏️×%d" % cost["kuangshi"])
		if cost.has("yaodan"): parts.append("🔮×%d" % cost["yaodan"])
		cost_text = " + ".join(parts)

		var btn := Button.new()
		btn.text = "%s — %s [%s]" % [recipe["name"], recipe["desc"], cost_text]
		btn.custom_minimum_size = Vector2(520, 40)
		vbox.add_child(btn)

		var rid: String = recipe["id"]
		var rname: String = recipe["name"]
		if not shop_events.can_craft(rid):
			btn.disabled = true
		btn.pressed.connect(func():
			if shop_events.craft(rid):
				_flash("炼制成功：%s！" % rname)
				_close_modal()
				_build_ui()
			else:
				_flash("材料不足！")
		)

	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(200, 36)
	vbox.add_child(close_btn)
	close_btn.pressed.connect(func():
		_close_modal()
		_build_ui()
	)


# ===== 功法阁 =====

func _show_gongfa_modal() -> void:
	_close_modal()
	_modal = _make_modal_container()

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 20; scroll.offset_bottom = -20
	scroll.offset_left = 20; scroll.offset_right = -20
	_modal.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	_add_modal_label(vbox, "功法阁", 22, Color(0.83, 0.71, 0.56))

	# 当前道统
	var dt_text: String = _daotong_name(G.equipped_daotong)
	_add_modal_label(vbox, "当前道统: %s" % dt_text, 16, Color(0.7, 0.7, 0.9))

	# 已解锁道统
	if G.unlocked_daotong.size() > 1:
		var dt_list: String = "已解锁: "
		for dt: String in G.unlocked_daotong:
			if dt != "basic":
				dt_list += _daotong_name(dt) + " "
		_add_modal_label(vbox, dt_list, 13, Color(0.5, 0.7, 0.5))

	# 功法收集
	_add_modal_label(vbox, "功法收集: %d张" % G.gongfa_collection.size(), 16, Color(0.7, 0.7, 0.8))

	if G.gongfa_collection.size() > 0:
		var col_label := Label.new()
		col_label.text = "、".join(G.gongfa_collection)
		col_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col_label.custom_minimum_size = Vector2(520, 0)
		col_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		col_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(col_label)

	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(200, 36)
	vbox.add_child(close_btn)
	close_btn.pressed.connect(func():
		_close_modal()
		_build_ui()
	)


# ===== 背包 =====

func _show_inventory_modal() -> void:
	_close_modal()
	_modal = _make_modal_container()

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 20; scroll.offset_bottom = -20
	scroll.offset_left = 20; scroll.offset_right = -20
	_modal.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	_add_modal_label(vbox, "背包", 22, Color(0.83, 0.71, 0.56))

	# 灵根
	var lg_name: String = {"fire":"🔥火","wood":"🌿木","earth":"⛰️土","water":"💧水","metal":"⚔️金"}.get(G.linggen, "?")
	_add_modal_label(vbox, "灵根: %s" % lg_name, 16, Color(0.8, 0.7, 0.5))

	# 境界
	_add_modal_label(vbox, "境界: %s (第%d层)" % [cultivation.realm_name(G.realm), G.realm], 16, Color(0.8, 0.7, 0.5))

	# 材料
	_add_modal_label(vbox, "材料: 🌿%d  ⛏️%d  🔮%d" % [G.lingcao, G.kuangshi, G.yaodan], 14, Color(0.6, 0.6, 0.7))

	# 丹药库存
	_add_modal_label(vbox, "丹药: 💊突破丹×%d  ✨筑基丹×%d" % [G.po_jing_dan, G.zhu_ji_dan], 14, Color(0.6, 0.6, 0.7))

	# 法器
	if not G.equipped_artifact.is_empty():
		_add_modal_label(vbox, "装备法器: %s" % G.equipped_artifact.get("name", ""), 14, Color(0.7, 0.5, 0.3))
	else:
		_add_modal_label(vbox, "装备法器: 无", 14, Color(0.4, 0.4, 0.5))

	# 道统
	_add_modal_label(vbox, "当前道统: %s" % _daotong_name(G.equipped_daotong), 14, Color(0.7, 0.7, 0.9))

	# 神通
	if G.equipped_shentong.size() > 0:
		var st_names: Array = []
		for sid: String in G.equipped_shentong:
			st_names.append(_shentong_name(sid))
		_add_modal_label(vbox, "装备神通: %s" % "、".join(st_names), 14, Color(0.5, 0.7, 0.9))
	else:
		_add_modal_label(vbox, "装备神通: 无", 14, Color(0.4, 0.4, 0.5))

	# 日志进度
	_add_modal_label(vbox, "仙人日志: %d/10" % G.collected_logs.size(), 14, Color(0.5, 0.7, 0.5))

	# 统计
	_add_modal_label(vbox, "历练: %d次  通关: %d次" % [G.runs, G.wins], 14, Color(0.6, 0.6, 0.7))

	# 重置存档
	var reset_btn := Button.new()
	reset_btn.text = "重置存档"
	reset_btn.custom_minimum_size = Vector2(200, 36)
	reset_btn.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	vbox.add_child(reset_btn)
	reset_btn.pressed.connect(func():
		G.linggen = ""
		G.realm = 1
		G.xiuwei = 0
		G.lingcao = 3
		G.kuangshi = 2
		G.yaodan = 0
		G.po_jing_dan = 0
		G.zhu_ji_dan = 0
		G.equipped_daotong = "basic"
		G.unlocked_daotong = ["basic"]
		G.unlocked_shentong = []
		G.equipped_shentong = []
		G.collected_logs = []
		G.hard_mode_unlocked = false
		G.equipped_artifact = {}
		G.gongfa_collection = []
		G.runs = 0
		G.wins = 0
		G.in_run = false
		G.save_game()
		get_tree().reload_current_scene()
	)

	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(200, 36)
	vbox.add_child(close_btn)
	close_btn.pressed.connect(func():
		_close_modal()
		_build_ui()
	)


# ===== 工具 =====

func _make_modal_container() -> Control:
	var modal := Control.new()
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP

	# 半透明背景
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	modal.add_child(overlay)

	# 弹窗内容
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_top = -250
	panel.offset_right = 300
	panel.offset_bottom = 250
	modal.add_child(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	add_child(modal)
	return modal


func _add_modal_label(parent: Node, text: String, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


func _close_modal() -> void:
	if _modal:
		_modal.queue_free()
		_modal = null


func _flash(msg: String) -> void:
	print("[洞府] %s" % msg)
	var label := Label.new()
	label.text = msg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	label.position = Vector2(300, 20)
	label.custom_minimum_size = Vector2(680, 30)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(label.queue_free)


func _shentong_name(sid: String) -> String:
	return {
		"fentian": "焚天",
		"kuhuan": "枯荣",
		"houtut": "厚土",
		"lingsheng": "灵力共振",
		"lianhuan": "连环诀",
		"poxian": "破绽洞察",
		"bumie": "不灭金身",
		"niepan": "涅槃",
	}.get(sid, sid)


func _daotong_name(dt: String) -> String:
	return {
		"basic": "无名散修",
		"yanhuo": "炎火道统",
		"muling": "木灵道统",
		"houtu": "厚土道统",
		"jinrui": "金锐道统",
		"shuiyun": "水云道统",
	}.get(dt, dt)


func refresh() -> void:
	_build_ui()
