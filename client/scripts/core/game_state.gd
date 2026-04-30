extends Node

# ===== 全局状态管理 =====
# 作为 Autoload 单例使用，负责所有持久化存档

const SAVE_KEY := "xianxia_save"
const VERSION := 1

# ---- meta（永久进度）----
var linggen: String = ""       # fire/wood/earth/water/metal
var realm: int = 1             # 境界层数（1-15）
var xiuwei: int = 0            # 当前修为
var lingcao: int = 3           # 灵草
var kuangshi: int = 2          # 矿石
var yaodan: int = 0            # 妖丹
var po_jing_dan: int = 0       # 突破丹
var zhu_ji_dan: int = 0        # 筑基丹
var equipped_daotong: String = "basic"
var unlocked_daotong: Array = ["basic"]
var unlocked_shentong: Array = []
var equipped_shentong: Array = []
var collected_logs: Array = []  # 已收集的仙人日志ID
var hard_mode_unlocked: bool = false
var equipped_artifact: Dictionary = {}
var gongfa_collection: Array = []  # 已获得的功法名称列表
var runs: int = 0
var wins: int = 0
var last_online: int = 0       # 时间戳
var wudao_used: int = 0        # 上次悟道时间戳

# ---- run（当局肉鸽状态）----
var in_run: bool = false
var run_seed: int = 0
var current_layer: int = 0
var deck: Array = []           # 当前牌组
var draw_pile: Array = []
var discard_pile: Array = []
var exhaust_pile: Array = []
var hand: Array = []
var hp: int = 0
var max_hp: int = 0
var lingshi: int = 0
var selected_pill: String = ""
var used_pill_this_fight: bool = false
var layer_hp_history: Array = []

# ---- 战斗临时状态 ----
var fire_crow_bonus: int = 0   # 火鸦变加成
var dan_yi_stacks: int = 0     # 丹意凝形层数
var baicao_per_turn: int = 0   # 百草护元每回合格挡
var killed_elite: int = 0      # 已击杀精英数

# ---- 五行相生状态 ----
var sheng_ready: Dictionary = {}  # {"fire": true} 火生土就绪

# ---- 蓄力状态 ----
var charge_buffs: Array = []   # [{type, effect, charges}]

# ---- 神通追踪 ----
var consecutive_fire_count: int = 0
var consecutive_same_cost_count: int = 0
var last_cost: int = -1
var atk_played_this_turn: int = 0
var cards_played_this_turn: int = 0
var cards_by_name_this_turn: Dictionary = {}
var took_damage_this_turn: bool = false
var turns_without_damage: int = 0


func _ready() -> void:
	load_game()


# ===== 存档 =====

func save_game() -> void:
	var data := {
		"version": VERSION,
		"meta": {
			"linggen": linggen,
			"realm": realm,
			"xiuwei": xiuwei,
			"offline_xiuwei_accum": 0,
			"last_online": Time.get_unix_time_from_system(),
			"lingcao": lingcao,
			"kuangshi": kuangshi,
			"yaodan": yaodan,
			"po_jing_dan": po_jing_dan,
			"zhu_ji_dan": zhu_ji_dan,
			"equipped_daotong": equipped_daotong,
			"unlocked_daotong": unlocked_daotong,
			"unlocked_shentong": unlocked_shentong,
			"equipped_shentong": equipped_shentong,
			"collected_logs": collected_logs,
			"hard_mode_unlocked": hard_mode_unlocked,
			"equipped_artifact": equipped_artifact,
			"gongfa_collection": gongfa_collection,
			"runs": runs,
			"wins": wins,
			"wudao_used": wudao_used,
		},
		"run": null if not in_run else {
			"active": true,
			"seed": run_seed,
			"current_layer": current_layer,
			"deck": deck,
			"hp": hp,
			"max_hp": max_hp,
			"lingshi": lingshi,
			"pill": selected_pill,
			"used_pill_this_fight": used_pill_this_fight,
			"layer_hp_history": layer_hp_history,
		}
	}
	if OS.has_feature("web"):
		JavaScriptBridge.eval("localStorage.setItem('%s', JSON.stringify(%s))" % [SAVE_KEY, JSON.stringify(data)])
	else:
		var f := FileAccess.open("user://%s.save" % SAVE_KEY, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(data, "\t"))
			f.close()


func load_game() -> void:
	var data = _load_raw()
	if data == null:
		return
	if data.has("version") and data["version"] >= 1:
		var m = data.get("meta", {})
		if not m is Dictionary:
			m = {}
		linggen = m.get("linggen", "")
		realm = m.get("realm", 1)
		xiuwei = m.get("xiuwei", 0)
		lingcao = m.get("lingcao", 3)
		kuangshi = m.get("kuangshi", 2)
		yaodan = m.get("yaodan", 0)
		po_jing_dan = m.get("po_jing_dan", 0)
		zhu_ji_dan = m.get("zhu_ji_dan", 0)
		equipped_daotong = m.get("equipped_daotong", "basic")
		unlocked_daotong = m.get("unlocked_daotong", ["basic"])
		unlocked_shentong = m.get("unlocked_shentong", [])
		equipped_shentong = m.get("equipped_shentong", [])
		collected_logs = m.get("collected_logs", [])
		hard_mode_unlocked = m.get("hard_mode_unlocked", false)
		equipped_artifact = m.get("equipped_artifact", {})
		gongfa_collection = m.get("gongfa_collection", [])
		runs = m.get("runs", 0) as int
		wins = m.get("wins", 0) as int
		wudao_used = m.get("wudao_used", 0) as int
		collected_logs = m.get("collected_logs", [] as Array) as Array

		# 离线修为计算
		var last: int = m.get("last_online", 0) as int
		var now: int = Time.get_unix_time_from_system() as int
		var diff: int = now - last if last > 0 else 0
		var offline_secs: int = mini(diff, 8 * 3600)
		var offline_xiuwei: int = (offline_secs / 60) * 5
		xiuwei += offline_xiuwei

		var r = data.get("run", {})
		if not r is Dictionary:
			r = {}
		if r.get("active", false):
			in_run = true
			run_seed = r.get("seed", 0)
			current_layer = r.get("current_layer", 0)
			deck = r.get("deck", [])
			hp = r.get("hp", 0)
			max_hp = r.get("max_hp", 0)
			lingshi = r.get("lingshi", 0)
			selected_pill = r.get("pill", "")
			used_pill_this_fight = r.get("used_pill_this_fight", false)
			layer_hp_history = r.get("layer_hp_history", [])


func _load_raw():
	if OS.has_feature("web"):
		var json_str = JavaScriptBridge.eval("localStorage.getItem('%s')" % SAVE_KEY)
		if json_str and json_str != "null":
			return JSON.parse_string(json_str)
	else:
		if FileAccess.file_exists("user://%s.save" % SAVE_KEY):
			var f := FileAccess.open("user://%s.save" % SAVE_KEY, FileAccess.READ)
			if f:
				var content := f.get_as_text()
				f.close()
				return JSON.parse_string(content)
	return null


func reset_run() -> void:
	in_run = false
	deck = []
	draw_pile = []
	discard_pile = []
	exhaust_pile = []
	hand = []
	layer_hp_history = []
	fire_crow_bonus = 0
	dan_yi_stacks = 0
	baicao_per_turn = 0
	killed_elite = 0
	sheng_ready = {}
	charge_buffs = []
	reset_turn_trackers()


func reset_turn_trackers() -> void:
	consecutive_fire_count = 0
	consecutive_same_cost_count = 0
	last_cost = -1
	atk_played_this_turn = 0
	cards_played_this_turn = 0
	cards_by_name_this_turn = {}
	took_damage_this_turn = false