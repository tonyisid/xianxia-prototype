extends Node

# ===== 分支地图生成器 =====
# 12层，每层2-3个节点可选
# 参考 DESIGN-MVP §9.2 的约束规则

const LAYER_COUNT := 12

# 固定层约束：层号→固定节点类型
const FIXED_LAYERS: Dictionary = {
	0: ["F"],        # 层1：固定战斗
	4: ["S"],        # 层5：固定商店
	7: ["R"],        # 层8：固定休整
	10: ["?"],       # 层11：固定事件
	11: ["B"],       # 层12：固定Boss
}

# 节点类型权重
const NODE_WEIGHTS: Dictionary = {
	"F": 50,
	"E": 15,
	"S": 10,
	"?": 15,
	"R": 10,
}

# 节点中文名
const NODE_NAMES: Dictionary = {
	"F": "⚔️ 战斗",
	"E": "💀 精英",
	"R": "🏕️ 休整",
	"S": "🛒 商店",
	"?": "❓ 事件",
	"B": "👑 Boss",
}


func generate(seed_val: int) -> Array:
	"""返回 map[layers][options] 结构"""
	var map: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	for layer: int in range(LAYER_COUNT):
		var options: Array = []

		# 固定层
		if FIXED_LAYERS.has(layer):
			options = FIXED_LAYERS[layer].duplicate(true)
		else:
			# 2或3个选项
			var option_count: int = 2 if rng.randf() < 0.5 else 3
			for i in range(option_count):
				options.append(_weighted_random(rng))

			# 不连续出现相同类型的所有选项
			if layer > 0:
				var prev_types: Array = map[layer - 1] if layer - 1 < map.size() else []
				_ensure_diversity(options, prev_types, rng)

			# 约束：层2无精英，层3至少1战斗，层9至少1精英
			if layer == 1:
				options = options.map(func(t: String): return "E" if t == "E" else t)
				# 层2无精英：替换为战斗
				for i in range(options.size()):
					if options[i] == "E":
						options[i] = "F"
			if layer == 2:
				# 层3至少1战斗
				if not "F" in options:
					options[rng.randi() % options.size()] = "F"
			if layer == 8:
				# 层9：战斗+精英
				options = ["F", "E"]

		map.append(options)

	return map


func _weighted_random(rng: RandomNumberGenerator) -> String:
	var total: float = 0.0
	for w: float in NODE_WEIGHTS.values():
		total += w
	var roll: float = rng.randf() * total
	var cumulative: float = 0.0
	for type: String in NODE_WEIGHTS.keys():
		cumulative += NODE_WEIGHTS[type]
		if roll <= cumulative:
			return type
	return "F"


func _ensure_diversity(options: Array, prev_types: Array, rng: RandomNumberGenerator) -> void:
	"""如果所有选项和上一层所有选项类型完全相同，替换一个"""
	if options.is_empty() or prev_types.is_empty():
		return
	var all_same: bool = true
	var first: String = options[0]
	for t: String in options:
		if t != first:
			all_same = false
			break
	if all_same and first == prev_types[0]:
		# 替换第一个为不同类型
		var alternatives: Array = ["F", "E", "S", "?", "R"].filter(func(t: String): return t != first)
		options[0] = alternatives[rng.randi() % alternatives.size()]


func node_display_name(type: String) -> String:
	return NODE_NAMES.get(type, type)


func get_node_color(type: String) -> Color:
	match type:
		"F":
			return Color(0.83, 0.71, 0.56)  # 暖色
		"E":
			return Color(0.9, 0.3, 0.3)     # 红
		"R":
			return Color(0.3, 0.8, 0.4)     # 绿
		"S":
			return Color(0.95, 0.8, 0.2)    # 金
		"?":
			return Color(0.5, 0.5, 0.9)     # 蓝
		"B":
			return Color(0.9, 0.2, 0.6)     # 粉红
		_:
			return Color(0.6, 0.6, 0.6)