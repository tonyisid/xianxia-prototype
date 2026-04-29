extends Node

# ===== 修炼系统 =====
# 自动修炼(离线算) + 突破 + 悟道

const REALM_THRESHOLDS: Array = [0, 100, 200, 350, 500, 700, 1000, 1400, 1900, 2500, 3200, 4000, 5000, 6200, 7500]
const REALM_NAMES: Array = [
	"炼气1层", "炼气2层", "炼气3层", "炼气4层", "炼气5层",
	"炼气6层", "炼气7层", "炼气8层", "炼气9层",
	"筑基初期", "筑基中期", "筑基后期",
	"金丹初期", "金丹中期", "金丹后期",
]

var G: Node


func _ready() -> void:
	G = get_node("/root/GameState")


func realm_name(level: int) -> String:
	if level < 1 or level > 15:
		return "凡人"
	return REALM_NAMES[level - 1]


func realm_threshold(level: int) -> int:
	if level < 1 or level > 15:
		return 999999
	return REALM_THRESHOLDS[level - 1]


func next_threshold(level: int) -> int:
	if level >= 15:
		return 999999
	return REALM_THRESHOLDS[level]


func can_breakthrough() -> bool:
	var level: int = G.realm
	if level >= 15:
		return false
	if G.xiuwei < next_threshold(level):
		return false
	# 炼气层间需要突破丹
	if level < 9:
		return G.po_jing_dan >= 1
	# 炼气→筑基/筑基内需要筑基丹
	return G.zhu_ji_dan >= 1


func execute_breakthrough() -> bool:
	if not can_breakthrough():
		return false

	var level: int = G.realm
	# 消耗丹药
	if level < 9:
		G.po_jing_dan -= 1
	else:
		G.zhu_ji_dan -= 1

	G.realm += 1
	G.xiuwei = 0  # 重置修为（保留溢出）
	G.max_hp += 5
	# 每3层+1灵力
	if G.realm % 3 == 0:
		# max_sp bonus stored in game state
		pass

	G.save_game()
	return true


func meditate() -> int:
	"""打坐获得10-30随机修为"""
	var gain: int = randi() % 21 + 10
	G.xiuwei += gain
	G.save_game()
	return gain


func wudao_available() -> bool:
	"""悟道是否冷却完毕（1小时）"""
	var now_msec: int = int(Time.get_unix_time_from_system() * 1000)
	return (now_msec - G.wudao_used) >= 3600000


func get_wudao_options() -> Array:
	"""返回三选一的神通选项"""
	var all_shentong: Array = [
		{"id": "fentian", "name": "焚天", "desc": "连续第3张火牌伤害翻倍", "cond": "元素连击"},
		{"id": "kuhuan", "name": "枯荣", "desc": "打出木牌且HP<50%额外回复3HP", "cond": "元素连击"},
		{"id": "houtut", "name": "厚土", "desc": "打出土牌后+2格挡", "cond": "元素连击"},
		{"id": "lingsheng", "name": "灵力共振", "desc": "连续3张同费用抽1张", "cond": "连招"},
		{"id": "lianhuan", "name": "连环诀", "desc": "一回合≥4张攻击牌最后一张+50%", "cond": "连招"},
		{"id": "poxian", "name": "破绽洞察", "desc": "同名牌第2张打出费用-1", "cond": "连招"},
		{"id": "bumie", "name": "不灭金身", "desc": "HP<30%获得15格挡(每场1次)", "cond": "生存"},
		{"id": "niepan", "name": "涅槃", "desc": "死亡时1HP复活(每场1次)", "cond": "生存"},
	]
	# 过滤已学会的
	var available: Array = all_shentong.filter(func(s: Dictionary): return not s["id"] in G.unlocked_shentong)
	available.shuffle()
	return available.slice(0, mini(3, available.size()))


func execute_wudao(chosen_id: String) -> bool:
	if not wudao_available():
		return false
	if G.xiuwei < 200:
		return false
	G.xiuwei -= 200
	G.wudao_used = int(Time.get_unix_time_from_system() * 1000)
	G.unlocked_shentong.append(chosen_id)
	G.save_game()
	return true