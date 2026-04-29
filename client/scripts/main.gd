extends Control

# ===== 主入口 =====

@onready var test_btn: Button = $VBox/TestBattle
@onready var status_label: Label = $VBox/Status

var battle_scene: Control = null


func _ready() -> void:
	test_btn.pressed.connect(_on_test_battle)
	var cards_db = get_node("/root/CardsDB")
	var count: int = cards_db.all_cards.size()
	status_label.text = "卡牌: %d张 | 敌人: 8种 | 道统: 6种" % count


func _on_test_battle() -> void:
	var G = get_node("/root/GameState")
	var cards_db = get_node("/root/CardsDB")

	# 初始化测试状态
	G.linggen = "fire"
	G.max_hp = 50
	G.hp = 50
	G.deck = cards_db.build_starter_deck("fire")
	G.selected_pill = "回春丹"
	G.used_pill_this_fight = false
	G.reset_run()

	# 加载战斗场景
	var battle_tscn: PackedScene = load("res://scenes/battle/battle.tscn")
	if battle_scene:
		battle_scene.queue_free()
	battle_scene = battle_tscn.instantiate()
	add_child(battle_scene)

	# 开始战斗
	battle_scene.start_battle("wolf", 0)