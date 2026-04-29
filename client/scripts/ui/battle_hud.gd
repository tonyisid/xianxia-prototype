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

@onready var hand_container: HBoxContainer = $HandArea/HandContainer
@onready var end_turn_btn: Button = $PlayerArea/EndTurnBtn
@onready var pill_btn: Button = $PlayerArea/PillBtn
@onready var log_label: RichTextLabel = $LogArea/LogText

@onready var progress_bar: HBoxContainer = $TopBar/ProgressContainer

const CardViewScene := preload("res://scenes/battle/card_view.tscn")

var G: Node  # GameState autoload
var combat: Node  # CombatEngine autoload
var enemy_ai: Node
var enemy_data: Dictionary = {}

# 日志
var log_lines: Array = []


func _ready() -> void:
	G = get_node("/root/GameState")
	combat = get_node("/root/CombatEngine")
	enemy_ai = Node.new()
	enemy_ai.set_script(load("res://scripts/core/enemy_ai.gd"))
	add_child(enemy_ai)

	end_turn_btn.pressed.connect(_on_end_turn)
	pill_btn.pressed.connect(_on_use_pill)

	combat.turn_started.connect(_on_turn_started)
	combat.card_played.connect(_on_card_played)
	combat.turn_ended.connect(_on_turn_ended)
	combat.fight_ended.connect(_on_fight_ended)
	combat.sheng_triggered.connect(_on_sheng)
	combat.shentong_triggered.connect(_on_shentong)


func start_battle(enemy_id: String, layer_idx: int) -> void:
	var cards_db = get_node("/root/CardsDB")
	enemy_data = cards_db.get_card(enemy_id)
	combat.start_fight(enemy_id, layer_idx)
	_update_all()


func _on_turn_started() -> void:
	_add_log("— 回合开始 —")
	pill_btn.disabled = G.used_pill_this_fight
	_update_all()


func _on_card_played(card: Dictionary, _success: bool) -> void:
	var name: String = card.get("name", "")
	_add_log("打出 [%s]" % name)
	_render_hand()
	_update_player()
	_update_enemy()


func _on_turn_ended() -> void:
	_add_log("— 回合结束 —")


func _on_fight_ended(victory: bool) -> void:
	if victory:
		_add_log("★ 战斗胜利！")
		# TODO: 显示卡牌选择
	else:
		_add_log("✘ 战斗失败...")
		# TODO: 返回洞府
	_update_all()


func _on_sheng(_src: String, _tgt: String, desc: String) -> void:
	_add_log("✦ %s" % desc)


func _on_shentong(_sid: String, desc: String) -> void:
	_add_log("⚡ %s" % desc)


func _on_end_turn() -> void:
	end_turn_btn.disabled = true
	combat.end_player_turn()


func _on_use_pill() -> void:
	if G.used_pill_this_fight:
		return
	var pill: String = G.selected_pill
	if pill == "":
		return
	G.used_pill_this_fight = true
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
	if not success:
		_add_log("灵力不足！")


# ===== 渲染 =====

func _update_all() -> void:
	_update_enemy()
	_update_player()
	_render_hand()
	_update_progress()


func _update_enemy() -> void:
	if enemy_data.is_empty():
		return
	enemy_name_label.text = "%s %s" % [enemy_data.get("emoji", ""), enemy_data.get("name", "")]
	enemy_hp_bar.max_value = combat.enemy_max_hp
	enemy_hp_bar.value = combat.enemy_hp
	enemy_hp_text.text = "%d/%d" % [combat.enemy_hp, combat.enemy_max_hp]

	# 意图
	var intent: Dictionary = combat.enemy_intent
	var intent_text: String = _intent_to_text(intent)
	enemy_intent_label.text = intent_text

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
	player_hp_bar.max_value = combat.player_max_hp
	player_hp_bar.value = combat.player_hp
	player_hp_text.text = "%d/%d" % [combat.player_hp, combat.player_max_hp]
	player_sp_label.text = "灵力: %d/%d" % [combat.player_sp, combat.player_max_sp]
	player_block_label.text = "格挡: %d" % combat.player_block if combat.player_block > 0 else ""

	end_turn_btn.disabled = (combat.state != 1)  # PLAYER_TURN

	var statuses: Array = []
	if combat.player_block > 0:
		statuses.append("格挡×%d" % combat.player_block)
	player_status_label.text = "  ".join(statuses)


func _render_hand() -> void:
	for child in hand_container.get_children():
		child.queue_free()

	for card: Dictionary in G.hand:
		var card_view: Control = CardViewScene.instantiate()
		card_view.setup(card)
		card_view.card_clicked.connect(_play_card)
		# 灰显费用不足的牌
		var cost: int = int(card.get("cost", 0))
		card_view.set_playable(combat.player_sp >= cost)
		hand_container.add_child(card_view)


func _update_progress() -> void:
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
	log_label.text = "\n".join(log_lines)