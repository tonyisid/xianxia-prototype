extends Control

# ===== 灵根觉醒界面 =====

signal linggen_confirmed(linggen: String)

const LINGGEN_LIST: Array = [
	{"id": "fire",  "name": "🔥 火灵根", "color": Color(0.91, 0.3, 0.24), "desc": "攻击牌+1伤害"},
	{"id": "wood",  "name": "🌿 木灵根", "color": Color(0.18, 0.8, 0.44), "desc": "治疗效果+2"},
	{"id": "earth", "name": "⛰️ 土灵根", "color": Color(0.95, 0.61, 0.07), "desc": "开局+3格挡"},
	{"id": "water", "name": "💧 水灵根", "color": Color(0.2, 0.6, 0.86), "desc": "首回合多抽1张"},
	{"id": "metal", "name": "⚔️ 金灵根", "color": Color(0.74, 0.76, 0.78), "desc": "10%暴击(双倍伤害)"},
]

var chosen_linggen: String = ""
var result_label: Label
var desc_label: Label
var awaken_btn: Button
var confirm_btn: Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.06, 0.1, 1)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -200
	vbox.offset_top = -150
	vbox.offset_right = 200
	vbox.offset_bottom = 150
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	var title := Label.new()
	title.text = "⚡ 灵根觉醒"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.83, 0.71, 0.56))
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "天地灵气灌入体内，你的灵根正在觉醒..."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(sub)

	# 灵根显示
	result_label = Label.new()
	result_label.text = "正在感应..."
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(result_label)

	desc_label = Label.new()
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(desc_label)

	# 觉醒按钮
	awaken_btn = Button.new()
	awaken_btn.text = "✨ 觉醒灵根"
	awaken_btn.custom_minimum_size = Vector2(200, 40)
	vbox.add_child(awaken_btn)
	awaken_btn.pressed.connect(_on_awaken)

	# 确认按钮（初始隐藏）
	confirm_btn = Button.new()
	confirm_btn.text = "开始修仙之路"
	confirm_btn.visible = false
	confirm_btn.custom_minimum_size = Vector2(200, 40)
	vbox.add_child(confirm_btn)
	confirm_btn.pressed.connect(_on_confirm)


func _on_awaken() -> void:
	# 随机分配灵根
	var idx: int = randi() % LINGGEN_LIST.size()
	var lg: Dictionary = LINGGEN_LIST[idx]
	chosen_linggen = lg["id"]

	result_label.text = lg["name"]
	result_label.add_theme_color_override("font_color", lg["color"])
	desc_label.text = lg["desc"]
	awaken_btn.visible = false
	confirm_btn.visible = true


func _on_confirm() -> void:
	if chosen_linggen != "":
		linggen_confirmed.emit(chosen_linggen)