extends Control

# ===== 分支地图视图 =====

signal node_selected(layer: int, option_idx: int)

var map_data: Array = []
var current_layer: int = 0
var map_gen: Node = null


func _ready() -> void:
	map_gen = Node.new()
	map_gen.set_script(load("res://scripts/core/map_gen.gd"))
	add_child(map_gen)


func setup(seed_val: int, layer: int) -> void:
	map_data = map_gen.generate(seed_val)
	current_layer = layer
	_render()


func advance(layer: int) -> void:
	current_layer = layer
	_render()


func _render() -> void:
	# 清空
	for child in get_children():
		child.queue_free()

	# 纵向排列每层
	var vbox := VBoxContainer.new()
	vbox.set("anchor_right", 1.0)
	vbox.set("anchor_bottom", 1.0)
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	for layer: int in range(map_data.size()):
		var options: Array = map_data[layer]
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 12)
		vbox.add_child(hbox)

		# 层号标签
		var layer_label := Label.new()
		layer_label.text = "%2d" % (layer + 1)
		layer_label.custom_minimum_size = Vector2(24, 0)
		layer_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		hbox.add_child(layer_label)

		for opt_idx: int in range(options.size()):
			var type: String = options[opt_idx]
			var btn := Button.new()
			btn.text = map_gen.node_display_name(type)

			var is_current: bool = (layer == current_layer)
			var is_past: bool = (layer < current_layer)

			if is_past:
				btn.disabled = true
				btn.modulate.a = 0.4
			elif is_current:
				# 高亮当前层
				btn.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.5))
			else:
				btn.disabled = true
				btn.modulate.a = 0.6

			btn.custom_minimum_size = Vector2(80, 32)
			var _layer := layer
			var _opt := opt_idx
			btn.pressed.connect(func(): node_selected.emit(_layer, _opt))
			hbox.add_child(btn)