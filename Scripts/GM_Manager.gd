# ==========================================
# 魂穿凡人 - GM 工具箱脚本（修复版）
# 挂载：GM_Manager.tscn 根节点
# ==========================================

extends Control

var _nodes: Dictionary = {}
var current_system_idx: int = 0

const SYSTEM_KEYS: Array = ["alchemy_crit","forging_crit","beast_initial","beast_growth","combat_crit"]
const SYSTEM_NAMES: Array = ["炼丹暴击","炼器暴击","灵兽初值","灵兽成长","战斗暴击"]

const REALM_LIST: Array = [
	"炼气一层","炼气二层","炼气三层","炼气四层","炼气五层","炼气六层",
	"炼气七层","炼气八层","炼气九层","炼气十层","炼气十一层","炼气十二层",
	"筑基初期","筑基中期","筑基后期","筑基圆满",
	"结丹初期","结丹中期","结丹后期","结丹圆满",
	"元婴初期","元婴中期","元婴后期","元婴圆满",
	"化神初期","化神中期","化神后期","化神圆满",
]

var item_data: Array = []


# ==========================================
# 工具函数
# ==========================================
func _get_node(path: String) -> Node:
	var n: Node = get_node_or_null(path)
	if n == null:
		push_warning("GM_Manager：找不到节点 [%s]" % path)
	return n


func _cache_nodes() -> void:
	_nodes["prompt_option"]   = _get_node("MainPanel/VBox/TopBar/PromptOption")
	_nodes["system_option"]   = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/系统选择行/SystemOption")
	_nodes["rate_spin"]       = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/基础概率行/RateSpin")
	_nodes["luck_label"]      = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/保底等级行/LuckLabel")
	_nodes["max_rate_label"]  = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/最高概率行/MaxRateLabel")
	_nodes["apply_button"]    = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/按钮行/ApplyButton")
	_nodes["reset_button"]    = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/按钮行/ResetButton")
	_nodes["test_button"]     = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/按钮行/TestButton")
	_nodes["test_result"]     = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/测试结果")
	_nodes["realm_option"]    = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/境界行/RealmOption")
	_nodes["level_spin"]      = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/等级行/LevelSpin")
	_nodes["hp_spin"]         = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/生命行/HpSpin")
	_nodes["mp_spin"]         = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/灵力行/MpSpin")
	_nodes["max_level_btn"]   = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/按钮行/MaxLevelButton")
	_nodes["max_stat_btn"]    = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/按钮行/MaxStatButton")
	_nodes["search_edit"]     = _get_node("MainPanel/VBox/TabContainer/物品控制/VBox/搜索行/SearchEdit")
	_nodes["item_list"]       = _get_node("MainPanel/VBox/TabContainer/物品控制/VBox/ItemList")
	_nodes["add_button"]      = _get_node("MainPanel/VBox/TabContainer/物品控制/VBox/按钮行/AddButton")
	_nodes["delete_button"]   = _get_node("MainPanel/VBox/TabContainer/物品控制/VBox/按钮行/DeleteButton")
	_nodes["enemy_spin"]     = _get_node("MainPanel/VBox/TabContainer/战斗控制/VBox/敌人数量行/EnemySpin")
	_nodes["speed_slider"]    = _get_node("MainPanel/VBox/TabContainer/全局设置/VBox/游戏速度行/SpeedSlider")
	_nodes["speed_label"]     = _get_node("MainPanel/VBox/TabContainer/全局设置/VBox/游戏速度行/SpeedLabel")
	_nodes["debug_check"]     = _get_node("MainPanel/VBox/TabContainer/全局设置/VBox/调试模式行/DebugCheck")


# ==========================================
# 生命周期
# ==========================================
func _ready() -> void:
	print("🔧 GM 工具箱 初始化...")
	_cache_nodes()
	_init_prompt_option()
	_init_system_option()
	_init_realm_option()
	_connect_signals()
	_refresh_prob_ui()
	print("✅ GM 工具箱 初始化完成")


# ==========================================
# 初始化函数
# ==========================================
func _init_prompt_option() -> void:
	var n = _nodes.get("prompt_option")
	if n == null: return
	(n as OptionButton).clear()
	(n as OptionButton).add_item("关闭提示", 0)
	(n as OptionButton).add_item("仅核心提示", 1)
	(n as OptionButton).add_item("全量提示", 2)
	if Engine.has_singleton("GlobalLuckController"):
		(n as OptionButton).select(Engine.get_singleton("GlobalLuckController").current_prompt_level)


func _init_system_option() -> void:
	var n = _nodes.get("system_option")
	if n == null: return
	(n as OptionButton).clear()
	for name in SYSTEM_NAMES:
		(n as OptionButton).add_item(name)


func _init_realm_option() -> void:
	var n = _nodes.get("realm_option")
	if n == null: return
	(n as OptionButton).clear()
	for r in REALM_LIST:
		(n as OptionButton).add_item(r)


# ==========================================
# 信号连接（每个节点独立判断，不复用类型变量）
# ==========================================
func _connect_signals() -> void:
	# 提示强度
	var po = _nodes.get("prompt_option")
	if po: (po as OptionButton).item_selected.connect(_on_prompt_selected)

	# 概率控制页
	var so = _nodes.get("system_option")
	if so: (so as OptionButton).item_selected.connect(_on_system_selected)
	var rs = _nodes.get("rate_spin")
	if rs: (rs as SpinBox).value_changed.connect(_on_rate_changed)
	var ab = _nodes.get("apply_button")
	if ab: (ab as Button).pressed.connect(_on_apply_pressed)
	var rb = _nodes.get("reset_button")
	if rb: (rb as Button).pressed.connect(_on_reset_pressed)
	var tb = _nodes.get("test_button")
	if tb: (tb as Button).pressed.connect(_on_test_pressed)

	# 角色控制页
	var ro = _nodes.get("realm_option")
	if ro: (ro as OptionButton).item_selected.connect(_on_realm_selected)
	var mlb = _nodes.get("max_level_btn")
	if mlb: (mlb as Button).pressed.connect(_on_max_level_pressed)
	var msb = _nodes.get("max_stat_btn")
	if msb: (msb as Button).pressed.connect(_on_max_stat_pressed)

	# 物品控制页
	var se = _nodes.get("search_edit")
	if se: (se as LineEdit).text_changed.connect(_on_search_changed)
	var ab2 = _nodes.get("add_button")
	if ab2: (ab2 as Button).pressed.connect(_on_add_item_pressed)
	var db = _nodes.get("delete_button")
	if db: (db as Button).pressed.connect(_on_delete_item_pressed)

	# 全局设置页
	var ss = _nodes.get("speed_slider")
	if ss: (ss as HSlider).value_changed.connect(_on_speed_changed)
	var dc = _nodes.get("debug_check")
	if dc: (dc as CheckBox).toggled.connect(_on_debug_toggled)


# ==========================================
# 刷新概率 UI
# ==========================================
func _refresh_prob_ui() -> void:
	if not Engine.has_singleton("GlobalLuckController"): return
	var glc = Engine.get_singleton("GlobalLuckController")
	var key: String = SYSTEM_KEYS[current_system_idx]
	if not glc.luck_config.has(key): return
	var cfg: Dictionary = glc.luck_config[key]

	var rs = _nodes.get("rate_spin")
	if rs: (rs as SpinBox).value = cfg.base_rate * 100.0
	var ll = _nodes.get("luck_label")
	if ll: (ll as Label).text = "%.1f%%" % [cfg.current_luck * 100.0]
	var ml = _nodes.get("max_rate_label")
	if ml: (ml as Label).text = "%.1f%%" % [cfg.max_rate * 100.0]


# ==========================================
# 信号回调
# ==========================================
func _on_prompt_selected(index: int) -> void:
	if Engine.has_singleton("GlobalLuckController"):
		Engine.get_singleton("GlobalLuckController").set_prompt_level(index)
	print("🔔 提示强度 → %s" % ["关闭","仅核心","全量"][index])

func _on_system_selected(index: int) -> void:
	current_system_idx = index
	_refresh_prob_ui()

func _on_rate_changed(_value: float) -> void:
	pass

func _on_apply_pressed() -> void:
	if not Engine.has_singleton("GlobalLuckController"): return
	var glc = Engine.get_singleton("GlobalLuckController")
	var key: String = SYSTEM_KEYS[current_system_idx]
	var rate: float = (_nodes.get("rate_spin") as SpinBox).value / 100.0
	glc.set_base_rate(key, rate)
	_refresh_prob_ui()
	print("✅ 应用：%s 基础概率 → %.1f%%" % [SYSTEM_NAMES[current_system_idx], rate * 100.0])

func _on_reset_pressed() -> void:
	if not Engine.has_singleton("GlobalLuckController"): return
	var glc = Engine.get_singleton("GlobalLuckController")
	var key: String = SYSTEM_KEYS[current_system_idx]
	glc.reset_luck(key)
	_refresh_prob_ui()
	print("🔄 重置：%s 保底值" % SYSTEM_NAMES[current_system_idx])

func _on_test_pressed() -> void:
	if not Engine.has_singleton("GlobalLuckController"): return
	var glc = Engine.get_singleton("GlobalLuckController")
	var key: String = SYSTEM_KEYS[current_system_idx]
	var result: Array = glc.try_luck(key)
	var success: bool = result[0]
	var final_rate: float = result[1]
	var tl = _nodes.get("test_result")
	if tl:
		(tl as Label).text = "【%s 测试】%s（最终概率：%.1f%%）" % [
			SYSTEM_NAMES[current_system_idx],
			"✅ 成功" if success else "❌ 失败",
			final_rate * 100.0,
		]
	_refresh_prob_ui()

func _on_realm_selected(index: int) -> void:
	print("📊 境界 → %s" % REALM_LIST[index])

func _on_max_level_pressed() -> void:
	var ls = _nodes.get("level_spin")
	if ls: (ls as SpinBox).value = 999.0
	print("⚡ 一键满级")

func _on_max_stat_pressed() -> void:
	var hs = _nodes.get("hp_spin")
	var ms = _nodes.get("mp_spin")
	if hs: (hs as SpinBox).value = 999999.0
	if ms: (ms as SpinBox).value = 999999.0
	print("⚡ 一键满属性")

func _on_search_changed(_text: String) -> void:
	_filter_items()

func _filter_items() -> void:
	var list = _nodes.get("item_list") as ItemList
	var edit = _nodes.get("search_edit") as LineEdit
	if list == null or edit == null: return
	list.clear()
	var keyword: String = edit.text.to_lower()
	for item in item_data:
		if keyword == "" or keyword in item.name.to_lower():
			list.add_item("%s (ID:%s)" % [item.name, item.id])

func _on_add_item_pressed() -> void:
	var new_item: Dictionary = {
		"id": "item_%d" % [item_data.size() + 1],
		"name": "测试物品%d" % [item_data.size() + 1],
	}
	item_data.append(new_item)
	_filter_items()
	print("➕ 添加物品：%s" % new_item.name)

func _on_delete_item_pressed() -> void:
	var list = _nodes.get("item_list") as ItemList
	if list == null: return
	var selected: Array = list.get_selected_items()
	if selected.size() == 0: return
	var idx: int = selected[0]
	if idx < item_data.size():
		var item = item_data[idx]
		item_data.remove_at(idx)
		_filter_items()
		print("➖ 删除物品：%s" % item.name)

func _on_speed_changed(value: float) -> void:
	Engine.time_scale = value
	var sl = _nodes.get("speed_label")
	if sl: (sl as Label).text = "%.1fx" % value
	print("⏩ 游戏速度 → %.1fx" % value)

func _on_debug_toggled(pressed: bool) -> void:
	print("🐛 调试模式 → %s" % ("开启" if pressed else "关闭"))
