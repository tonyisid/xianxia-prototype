extends Control

# ===== 战斗 HUD =====

@onready var enemy_name_label: Label = $EnemyArea/EnemyName
@onready var enemy_hp_bar: ProgressBar = $EnemyArea/HPBar
@onready var enemy_hp_text: Label = $EnemyArea/HPText
@onready var enemy_intent_label: Label = $EnemyArea/IntentLabel
@onready var enemy_status_label: Label = $EnemyArea/StatusLabel

@onready var player_hp_bar: ProgressBar = $PlayerArea/HPBar
@onready var player_hp_text: Label = $PlayerArea/HPText
@onready var player_sp_label: Label = $PlayerArea/SPLabel
@onready var player_block_label: Label = $PlayerArea/BlockLabel
@onready var player_status_label: Label = $PlayerArea/StatusLabel
@onready var end_turn_btn: Button = $PlayerArea/EndTurnBtn
@onready var pill_btn: Button = $PlayerArea/PillBtn

@onready var hand_container: HBoxContainer = $HandArea/HandContainer
@onready var log_label: RichTextLabel = $LogArea/LogText

@onready var progress_bar: HBoxContainer = $TopBar/ProgressContainer

const CardViewScene := preload("res://scenes/battle/card_view.tscn")

var G: Node  # GameState autoload
var combat: Node  # CombatEngine autoload
var enemy_ai: Node
var enemy_data: Dictionary = {}

# 日志
var log_lines: Array = []

# 程序化创建的控件
var deck_count_label: Label
var discard_count_label: Label
var top_spirit_label: Label
var _shentong_label: Label


func _ready() -> void:
	G = get_node("/root/GameState")
	combat = get_node("/root/CombatEngine")
	enemy_ai = Node.new()
	enemy_ai.set_script(load("res://scripts/core/enemy_ai.gd"))
	add_child(enemy_ai)

	# TSCN 节点缺失时完全动态构建UI
	# 检查所有关键 @onready 引用，任一为空则重建全部
	if _any_ui_null():
		_build_ui_from_scratch()

	# 在 TopBar 中程序化添加牌堆/弃牌/灵力标签
	var top_bar := $TopBar
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(8, 0)
	top_bar.add_child(spacer)

	deck_count_label = Label.new()
	deck_count_label.name = "DeckLabel"
	deck_count_label.text = "牌堆: 10"
	deck_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	deck_count_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	top_bar.add_child(deck_count_label)

	discard_count_label = Label.new()
	discard_count_label.name = "DiscardLabel"
	discard_count_label.text = "弃牌: 0"
	discard_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	discard_count_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	top_bar.add_child(discard_count_label)

	top_spirit_label = Label.new()
	top_spirit_label.name = "TopSpiritLabel"
	top_spirit_label.text = "灵力: 3/3"
	top_spirit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_spirit_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	top_bar.add_child(top_spirit_label)

	# 神通显示
	_shentong_label = Label.new()
	_shentong_label.name = "ShentongLabel"
	_shentong_label.text = ""
	_shentong_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shentong_label.add_theme_font_size_override("font_size", 14)
	_shentong_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	_shentong_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_shentong_label.offset_top = 202
	_shentong_label.offset_bottom = 218
	add_child(_shentong_label)

	if end_turn_btn:
		end_turn_btn.pressed.connect(_on_end_turn)
	if pill_btn:
		pill_btn.pressed.connect(_on_use_pill)

	combat.turn_started.connect(_on_turn_started)
	combat.card_played.connect(_on_card_played)
	combat.turn_ended.connect(_on_turn_ended)
	combat.fight_ended.connect(_on_fight_ended)
	combat.sheng_triggered.connect(_on_sheng)
	combat.shentong_triggered.connect(_on_shentong)


# ===== 动态构建UI（TSCN失效时的回退方案）=====

func _any_ui_null() -> bool:
	return (
		enemy_name_label == null or enemy_hp_bar == null or enemy_hp_text == null or
		enemy_intent_label == null or enemy_status_label == null or
		player_hp_bar == null or player_hp_text == null or player_sp_label == null or
		end_turn_btn == null or pill_btn == null or
		hand_container == null or log_label == null or progress_bar == null
	)


func _make_label(text: String, font_size: int, color: Color, halign: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = halign
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


func _build_ui_from_scratch() -> void:
	# BG
	if not has_node("BG"):
		var bg := ColorRect.new()
		bg.name = "BG"
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0.1, 0.1, 0.18, 1)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		move_child(bg, 0)

	# TopBar
	var top_bar: HBoxContainer
	if has_node("TopBar"):
		top_bar = $TopBar
	else:
		top_bar = HBoxContainer.new()
		top_bar.name = "TopBar"
		top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
		top_bar.offset_top = 8
		top_bar.offset_bottom = 36
		add_child(top_bar)

	# ProgressContainer
	if has_node("TopBar/ProgressContainer"):
		progress_bar = $TopBar/ProgressContainer
	else:
		progress_bar = HBoxContainer.new()
		progress_bar.name = "ProgressContainer"
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_bar.add_child(progress_bar)

	# EnemyArea + children
	var enemy_area: VBoxContainer
	if has_node("EnemyArea"):
		enemy_area = $EnemyArea
	else:
		enemy_area = VBoxContainer.new()
		enemy_area.name = "EnemyArea"
		enemy_area.set_anchors_preset(Control.PRESET_TOP_WIDE)
		enemy_area.offset_top = 40
		enemy_area.offset_bottom = 200
		enemy_area.add_theme_constant_override("separation", 4)
		add_child(enemy_area)

	var _ensure_child = _get_or_add_child.bind(enemy_area)

	enemy_name_label = _ensure_child.call("EnemyName", func(): return _make_label("野狼妖 🐺", 18, Color(0.9, 0.6, 0.4), HORIZONTAL_ALIGNMENT_CENTER))
	enemy_hp_bar = _ensure_child.call("HPBar", func(): return _make_progress_bar(Vector2(0, 20)))
	enemy_hp_text = _ensure_child.call("HPText", func(): return _make_label("30/30", 14, Color(1, 0.4, 0.4), HORIZONTAL_ALIGNMENT_CENTER))
	enemy_intent_label = _ensure_child.call("IntentLabel", func(): return _make_label("意图: ⚔️ 11", 14, Color(0.95, 0.4, 0.3), HORIZONTAL_ALIGNMENT_CENTER))
	enemy_status_label = _ensure_child.call("StatusLabel", func(): return _make_label("", 13, Color(0.5, 0.7, 0.5), HORIZONTAL_ALIGNMENT_CENTER))

	# LogArea
	var log_area: PanelContainer
	if has_node("LogArea"):
		log_area = $LogArea
	else:
		log_area = PanelContainer.new()
		log_area.name = "LogArea"
		log_area.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		log_area.offset_top = -48
		add_child(log_area)

	if has_node("LogArea/LogText"):
		log_label = $LogArea/LogText
	else:
		log_label = RichTextLabel.new()
		log_label.name = "LogText"
		log_label.bbcode_enabled = true
		log_label.text = "战斗开始"
		log_label.fit_content = true
		log_label.scroll_following = true
		log_area.add_child(log_label)

	# PlayerArea + children
	var player_area: HBoxContainer
	if has_node("PlayerArea"):
		player_area = $PlayerArea
	else:
		player_area = HBoxContainer.new()
		player_area.name = "PlayerArea"
		player_area.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		player_area.offset_top = -200
		player_area.offset_bottom = -160
		player_area.add_theme_constant_override("separation", 10)
		add_child(player_area)

	var _ensure_child2 = _get_or_add_child.bind(player_area)

	player_hp_bar = _ensure_child2.call("HPBar", func(): return _make_progress_bar(Vector2(200, 16)))
	player_hp_text = _ensure_child2.call("HPText", func(): return _make_label("50/50", 14, Color(1, 0.4, 0.4), HORIZONTAL_ALIGNMENT_LEFT))
	player_sp_label = _ensure_child2.call("SPLabel", func(): return _make_label("灵力: 3/3", 14, Color(0.5, 0.7, 0.9), HORIZONTAL_ALIGNMENT_LEFT))
	player_block_label = _ensure_child2.call("BlockLabel", func(): return _make_label("", 14, Color(0.6, 0.8, 0.6), HORIZONTAL_ALIGNMENT_LEFT))
	player_status_label = _ensure_child2.call("StatusLabel", func(): return _make_label("", 14, Color(0.7, 0.7, 0.7), HORIZONTAL_ALIGNMENT_LEFT))

	end_turn_btn = _ensure_child2.call("EndTurnBtn", func():
		var b := Button.new()
		b.text = "结束回合"
		return b)
	pill_btn = _ensure_child2.call("PillBtn", func():
		var b := Button.new()
		b.text = "💊 丹药"
		b.disabled = true
		return b)

	# HandArea
	var hand_area: ScrollContainer
	if has_node("HandArea"):
		hand_area = $HandArea
	else:
		hand_area = ScrollContainer.new()
		hand_area.name = "HandArea"
		hand_area.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		hand_area.offset_top = -300
		hand_area.offset_bottom = -50
		add_child(hand_area)

	if has_node("HandArea/HandContainer"):
		hand_container = $HandArea/HandContainer
	else:
		hand_container = HBoxContainer.new()
		hand_container.name = "HandContainer"
		hand_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hand_container.add_theme_constant_override("separation", 6)
		hand_area.add_child(hand_container)


# ---- helpers ----

func _make_progress_bar(min_size: Vector2) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.custom_minimum_size = min_size
	pb.max_value = 100
	pb.value = 100
	pb.show_percentage = false
	return pb


func _get_or_add_child(parent: Node, child_name: String, factory: Callable) -> Node:
	if parent.has_node(child_name):
		return parent.get_node(child_name)
	var child: Node = factory.call()
	child.name = child_name
	parent.add_child(child)
	return child


func start_battle(enemy_id: String, layer_idx: int) -> void:
	enemy_data = combat._enemies_by_id.get(enemy_id, {})
	combat.start_fight(enemy_id, layer_idx)
	_update_all()


func _on_turn_started() -> void:
	_add_log("— 回合开始 —")
	if pill_btn:
		pill_btn.disabled = G.used_pill_this_fight
	_update_all()


func _on_card_played(card: Dictionary, _success: bool) -> void:
	var name: String = card.get("name", "")
	_add_log("打出 [%s]" % name)
	_update_enemy()
	_update_top_bar()


func _on_turn_ended() -> void:
	_add_log("— 回合结束 —")


func _on_fight_ended(victory: bool) -> void:
	# 同步HP回GameState
	G.hp = combat.player_hp
	G.max_hp = combat.player_max_hp

	if victory:
		_add_log("★ 战斗胜利！")
	else:
		_add_log("✘ 战斗失败...")
	_update_all()


func _on_sheng(_src: String, _tgt: String, desc: String) -> void:
	_add_log("✦ %s" % desc)


func _on_shentong(_sid: String, desc: String) -> void:
	_add_log("⚡ %s" % desc)


func _on_end_turn() -> void:
	if end_turn_btn:
		end_turn_btn.disabled = true
	combat.end_player_turn()


func _on_use_pill() -> void:
	if G.used_pill_this_fight:
		return
	var pill: String = G.selected_pill
	if pill == "":
		return
	G.used_pill_this_fight = true
	if pill_btn:
		pill_btn.disabled = true
	match pill:
		"回春丹":
			combat.player_hp = mini(combat.player_hp + 15, combat.player_max_hp)
			_add_log("💊 回春丹 → 回复15HP")
		"凝元丹":
			# TODO: 下次攻击+5
			_add_log("💊 凝元丹 → 下次攻击+5")
		"护脉丹":
			combat.player_block += 10
			_add_log("💊 护脉丹 → +10格挡")
	_update_player()


func _play_card(card: Dictionary) -> void:
	if combat.state != 1:  # PLAYER_TURN
		return
	var success: bool = combat.play_card(card)
	if success:
		G.hand.erase(card)  # 从手牌中移除
		G.discard_pile.append(card)  # 放入弃牌堆
		_render_hand()
		_update_player()
		_update_top_bar()
	else:
		_add_log("灵力不足！")


# ===== 渲染 =====

func _update_all() -> void:
	_update_enemy()
	_update_player()
	_render_hand()
	_update_progress()
	_update_top_bar()
	_update_shentong()


func _update_top_bar() -> void:
	if deck_count_label:
		deck_count_label.text = "牌堆: %d" % G.draw_pile.size()
		discard_count_label.text = "弃牌: %d" % G.discard_pile.size()
	if top_spirit_label:
		top_spirit_label.text = "灵力: %d/%d" % [combat.player_sp, combat.player_max_sp]


func _update_enemy() -> void:
	if enemy_data.is_empty() or enemy_name_label == null or enemy_hp_bar == null:
		return
	enemy_name_label.text = "%s %s" % [enemy_data.get("emoji", ""), enemy_data.get("name", "")]
	enemy_hp_bar.max_value = combat.enemy_max_hp
	enemy_hp_bar.value = combat.enemy_hp
	enemy_hp_text.text = "%d/%d" % [combat.enemy_hp, combat.enemy_max_hp]

	# 意图
	var intent: Dictionary = combat.enemy_intent
	var intent_text: String = _intent_to_text(intent)
	enemy_intent_label.text = "意图: %s" % intent_text

	# 状态
	var statuses: Array = []
	if combat.enemy_burn > 0:
		statuses.append("灼烧×%d" % combat.enemy_burn)
	if combat.enemy_poison > 0:
		statuses.append("中毒×%d" % combat.enemy_poison)
	if combat.enemy_block > 0:
		statuses.append("格挡×%d" % combat.enemy_block)
	enemy_status_label.text = "  ".join(statuses)


func _update_player() -> void:
	if player_hp_bar == null:
		return
	player_hp_bar.max_value = combat.player_max_hp
	player_hp_bar.value = combat.player_hp
	player_hp_text.text = "%d/%d" % [combat.player_hp, combat.player_max_hp]
	player_sp_label.text = "灵力: %d/%d" % [combat.player_sp, combat.player_max_sp]
	player_block_label.text = "格挡: %d" % combat.player_block if combat.player_block > 0 else ""

	if end_turn_btn:
		end_turn_btn.disabled = (combat.state != 1)  # PLAYER_TURN

	var statuses: Array = []
	if combat.player_block > 0:
		statuses.append("格挡×%d" % combat.player_block)
	player_status_label.text = "  ".join(statuses)


func _render_hand() -> void:
	if hand_container == null:
		return
	for child in hand_container.get_children():
		child.queue_free()

	for card: Dictionary in G.hand:
		var card_view: Control = CardViewScene.instantiate()
		# 必须先 add_child，触发 _ready() 和 @onready 初始化，再调用 setup()
		hand_container.add_child(card_view)
		card_view.setup(card)
		card_view.card_clicked.connect(_play_card)
		# 灰显费用不足的牌
		var cost: int = int(card.get("cost", 0))
		card_view.set_playable(combat.player_sp >= cost)


func _update_progress() -> void:
	if progress_bar == null:
		return
	for child in progress_bar.get_children():
		child.queue_free()
	# TODO: 地图节点显示
	var label: Label = Label.new()
	label.text = "第 %d/12 层" % (G.current_layer + 1)
	label.add_theme_color_override("font_color", Color(0.83, 0.71, 0.56))
	progress_bar.add_child(label)


func _intent_to_text(intent: Dictionary) -> String:
	var type: String = intent.get("type", "")
	var val: int = int(intent.get("value", 0))
	match type:
		"atk":
			return "⚔️ %d" % val
		"atk_blk":
			return "⚔️%d 🛡️%d" % [val, int(intent.get("blk", 0))]
		"atk_lifesteal":
			return "⚔️%d 吸血" % val
		"def":
			return "🛡️ %d" % int(intent.get("blk", 0))
		"charge":
			return "💫 蓄力"
		"multi_atk":
			return "⚔️%d ×2" % val
		"poison":
			return "☠️ 中毒×%d" % val
		"special":
			return "⚡ %s" % intent.get("name", "")
		_:
			return "…"


func _add_log(text: String) -> void:
	log_lines.append(text)
	if log_lines.size() > 5:
		log_lines.pop_front()
	if log_label:
		log_label.text = "\n".join(log_lines)


func _update_shentong() -> void:
	if _shentong_label == null:
		return
	if G.equipped_shentong.size() == 0:
		_shentong_label.text = ""
		return
	var names: Array = []
	for sid: String in G.equipped_shentong:
		names.append(_shentong_name(sid))
	_shentong_label.text = "⚡ 神通: %s" % "、".join(names)


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
