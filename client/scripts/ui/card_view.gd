extends Control

# ===== 卡牌 UI 组件 =====

signal card_clicked(card: Dictionary)

var card_data: Dictionary = {}
var _playable: bool = true

@onready var name_label: Label = $VBox/NameLabel
@onready var cost_label: Label = $VBox/CostLabel
@onready var desc_label: Label = $DescLabel
@onready var el_label: Label = $VBox/ElLabel
@onready var bg_panel: PanelContainer = $BG


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func setup(data: Dictionary) -> void:
	card_data = data
	var name: String = data.get("name", "")
	var cost: int = int(data.get("cost", 0))
	var desc: String = data.get("desc", "")
	var el: String = data.get("el", "none")
	var rarity: String = data.get("rarity", "white")

	if name_label:
		name_label.text = name
	if cost_label:
		cost_label.text = "灵力:%d" % cost
	if desc_label:
		desc_label.text = desc
	if el_label:
		el_label.text = _el_emoji(el)

	# 稀有度边框色
	var border_color: Color = _rarity_color(rarity)
	if bg_panel:
		var style: StyleBoxFlat = bg_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = border_color


func set_playable(ok: bool) -> void:
	_playable = ok
	modulate.a = 1.0 if ok else 0.4


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _playable and not card_data.is_empty():
			card_clicked.emit(card_data)


func _el_emoji(el: String) -> String:
	return {"fire":"🔥","wood":"🌿","earth":"⛰️","water":"💧","metal":"⚔️","none":"🔮"}.get(el, "")


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"white":
			return Color(0.8, 0.8, 0.8)
		"green":
			return Color(0.18, 0.8, 0.44)
		"blue":
			return Color(0.2, 0.6, 0.93)
		"starter":
			return Color(0.7, 0.65, 0.5)
		_:
			return Color(0.6, 0.6, 0.6)