# =========================================
# 魂穿凡人 - GM 工具箱脚本（完整修复版）
# 挂载：GM_Manager.tscn 根节点
# 功能：5标签页 + 概率控制 + 角色控制 + 物品控制 + 战斗控制 + 全局设置
# =========================================

extends Control

# =========================================
# 节点缓存（get_node路径统一在这里维护）
# =========================================
var _nodes: Dictionary = {}

# 当前选中的概率系统索引
var current_system_idx: int = 0

# 概率系统配置（与 GlobalLuckController 保持一致）
const SYSTEM_KEYS: Array = ["alchemy_crit","forging_crit","beast_initial","beast_growth","combat_crit"]
const SYSTEM_NAMES: Array = ["炼丹暴击","炼器暴击","灵兽初值","灵兽成长","战斗暴击"]

# 境界列表
const REALM_LIST: Array = [
	"炼气一层","炼气二层","炼气三层","炼气四层","炼气五层","炼气六层",
	"炼气七层","炼气八层","炼气九层","炼气十层","炼气十一层","炼气十二层",
	"筑基初期","筑基中期","筑基后期","筑基圆满",
	"结丹初期","结丹中期","结丹后期","结丹圆满",
	"元婴初期","元婴中期","元婴后期","元婴圆满",
	"化神初期","化神中期","化神后期","化神圆满",
]

# 物品数据（演示用，正式版从游戏数据读取）
var item_data: Array = []


# =========================================
# 节点安全获取
# =========================================
func _get_node(path: String) -> Node:
	var n: Node = get_node_or_null(path)
	if n == null:
		push_warning("GM_Manager：找不到节点 [%s]" % path)
	return n


func _cache_nodes() -> void:
	"""将所有子节点缓存到 _nodes 字典，路径修改只改这里"""
	_nodes["prompt_option"]  = _get_node("MainPanel/VBox/TopBar/PromptOption")
	_nodes["system_option"]  = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/系统选择行/SystemOption")
	_nodes["rate_spin"]      = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/基础概率行/RateSpin")
	_nodes["luck_label"]     = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/保底等级行/LuckLabel")
	_nodes["max_rate_label"] = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/最高概率行/MaxRateLabel")
	_nodes["apply_button"]   = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/按钮行/ApplyButton")
	_nodes["reset_button"]   = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/按钮行/ResetButton")
	_nodes["test_button"]    = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/按钮行/TestButton")
	_nodes["test_result"]    = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/测试结果")
	_nodes["realm_option"]   = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/境界行/RealmOption")
	_nodes["level_spin"]     = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/等级行/LevelSpin")
	_nodes["hp_spin"]        = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/生命行/HpSpin")
	_nodes["mp_spin"]        = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/灵力行/MpSpin")
	_nodes["max_level_btn"]  = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/按钮行/MaxLevelButton")
	_nodes["max_stat_btn"]   = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/按钮行/MaxStatButton")
	_nodes["search_edit"]    = _get_node("MainPanel/VBox/TabContainer/物品控制/VBox/搜索行/SearchEdit")
	_nodes["item_list"]      = _get_node("MainPanel/VBox/TabContainer/物品控制/VBox/ItemList")
	_nodes["add_button"]     = _get_node("MainPanel/VBox/TabContainer/物品控制/VBox/按钮行/AddButton")
	_nodes["delete_button"]  = _get_node("MainPanel/VBox/TabContainer/物品控制/VBox/按钮行/DeleteButton")
	_nodes["enemy_spin"]    = _get_node("MainPanel/VBox/TabContainer/战斗控制/VBox/敌人数量行/EnemySpin")
	_nodes["speed_slider"]   = _get_node("MainPanel/VBox/TabContainer/全局设置/VBox/游戏速度行/SpeedSlider")
	_nodes["speed_label"]    = _get_node("MainPanel/VBox/TabContainer/全局设置/VBox/游戏速度行/SpeedLabel")
	_nodes["debug_check"]    = _get_node("MainPanel/VBox/TabContainer/全局设置/VBox/调试模式行/DebugCheck")
	_nodes["export_button"]  = _get_node("MainPanel/VBox/TabContainer/全局设置/VBox/配置按钮行/ExportButton")
	_nodes["import_button"]  = _get_node("MainPanel/VBox/TabContainer/全局设置/VBox/配置按钮行/ImportButton")
	_nodes["export_dialog"]  = _get_node("ExportDialog")
	_nodes["import_dialog"]  = _get_node("ImportDialog")
	# TabContainer 本身
	_nodes["tab_container"]  = _get_node("MainPanel/VBox/TabContainer")

	print("✅ 节点缓存完成，共缓存 %d 个节点" % _nodes.size())


# =========================================
# 生命周期
# =========================================
func _ready() -> void:
	print("🔧 GM 工具箱 初始化...")
	_cache_nodes()
	_init_prompt_option()
	_init_system_option()
	_init_realm_option()
	_init_item_list()
	_connect_signals()
	_refresh_prob_ui()
	# 确保面板可见
	visible = true
	print("✅ GM 工具箱 初始化完成，面板已显示")


# =========================================
# 初始化下拉选项
# =========================================
func _init_prompt_option() -> void:
	var n: OptionButton = _nodes.get("prompt_option")
	if n == null:
		push_warning("PromptOption 节点为空，跳过初始化")
		return
	n.clear()
	n.add_item("关闭提示", 0)
	n.add_item("仅核心提示", 1)
	n.add_item("全量提示", 2)
	if Engine.has_singleton("GlobalLuckController"):
		var glc = Engine.get_singleton("GlobalLuckController")
		n.select(glc.current_prompt_level)
	print("✅ 提示强度下拉初始化完成")


func _init_system_option() -> void:
	var n: OptionButton = _nodes.get("system_option")
	if n == null:
		push_warning("SystemOption 节点为空，跳过初始化")
		return
	n.clear()
	for name in SYSTEM_NAMES:
		n.add_item(name)
	n.select(0)
	print("✅ 事件选择下拉初始化完成")


func _init_realm_option() -> void:
	var n: OptionButton = _nodes.get("realm_option")
	if n == null:
		push_warning("RealmOption 节点为空，跳过初始化")
		return
	n.clear()
	for r in REALM_LIST:
		n.add_item(r)
	n.select(0)
	print("✅ 境界选择下拉初始化完成")


func _init_item_list() -> void:
	"""初始化演示物品数据"""
	item_data = [
		{"id": "item_001", "name": "筑基丹"},
		{"id": "item_002", "name": "回灵丹"},
		{"id": "item_003", "name": "下品灵石"},
		{"id": "item_004", "name": "中品灵石"},
		{"id": "item_005", "name": "上品灵石"},
	]
	_filter_items()
	print("✅ 物品列表初始化完成，共 %d 个物品" % item_data.size())


# =========================================
# 信号连接（call_deferred 确保节点完全 ready）
# =========================================
func _connect_signals() -> void:
	print("🔗 开始连接信号...")

	# —— 提示强度下拉 ——
	var po: OptionButton = _get_node("MainPanel/VBox/TopBar/PromptOption")
	if po:
		po.item_selected.connect(_on_prompt_selected)
		print("  ✅ PromptOption.item_selected 已连接")
	else:
		push_warning("PromptOption 节点为空，信号未连接")

	# —— 概率控制页 ——
	var so: OptionButton = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/系统选择行/SystemOption")
	if so:
		so.item_selected.connect(_on_system_selected)
		print("  ✅ SystemOption.item_selected 已连接")
	else:
		push_warning("SystemOption 节点为空，信号未连接")

	var rs: SpinBox = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/基础概率行/RateSpin")
	if rs:
		rs.value_changed.connect(_on_rate_changed)
		print("  ✅ RateSpin.value_changed 已连接")
	else:
		push_warning("RateSpin 节点为空，信号未连接")

	var ab: Button = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/按钮行/ApplyButton")
	if ab:
		ab.pressed.connect(_on_apply_pressed)
		print("  ✅ ApplyButton.pressed 已连接")
	else:
		push_warning("ApplyButton 节点为空，信号未连接")

	var rb: Button = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/按钮行/ResetButton")
	if rb:
		rb.pressed.connect(_on_reset_pressed)
		print("  ✅ ResetButton.pressed 已连接")
	else:
		push_warning("ResetButton 节点为空，信号未连接")

	var tb: Button = _get_node("MainPanel/VBox/TabContainer/概率控制/VBox/按钮行/TestButton")
	if tb:
		tb.pressed.connect(_on_test_pressed)
		print("  ✅ TestButton.pressed 已连接")
	else:
		push_warning("TestButton 节点为空，信号未连接")

	# —— 角色控制页 ——
	var ro: OptionButton = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/境界行/RealmOption")
	if ro:
		ro.item_selected.connect(_on_realm_selected)
		print("  ✅ RealmOption.item_selected 已连接")
	else:
		push_warning("RealmOption 节点为空，信号未连接")

	var mlb: Button = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/按钮行/MaxLevelButton")
	if mlb:
		mlb.pressed.connect(_on_max_level_pressed)
		print("  ✅ MaxLevelButton.pressed 已连接")
	else:
		push_warning("MaxLevelButton 节点为空，信号未连接")

	var msb: Button = _get_node("MainPanel/VBox/TabContainer/角色控制/VBox/按钮行/MaxStatButton")
	if msb:
		msb.pressed.connect(_on_max_stat_pressed)
		print("  ✅ MaxStatButton.pressed 已连接")
	else:
		push_warning("MaxStatButton 节点为空，信号未连接")

	# —— 物品控制页 ——
	var se: LineEdit = _get_node("MainPanel/VBox/TabContainer/物品控制/VBox/搜索行/SearchEdit")
	if se:
		se.text_changed.connect(_on_search_changed)
		print("  ✅ SearchEdit.text_changed 已连接")
	else:
		push_warning("SearchEdit 节点为空，信号未连接")

	var ab2: Button = _get_node("MainPanel/VBox/TabContainer/物品控制/VBox/按钮行/AddButton")
	if ab2:
		ab2.pressed.connect(_on_add_item_pressed)
		print("  ✅ AddButton.pressed 已连接")
	else:
		push_warning("AddButton 节点为空，信号未连接")

	var db: Button = _get_node("MainPanel/VBox/TabContainer/物品控制/VBox/按钮行/DeleteButton")
	if db:
		db.pressed.connect(_on_delete_item_pressed)
		print("  ✅ DeleteButton.pressed 已连接")
	else:
		push_warning("DeleteButton 节点为空，信号未连接")

	# —— 战斗控制页（EnemySpin value_changed）——


	# —— 全局设置页 ——
	var ss: HSlider = _get_node("MainPanel/VBox/TabContainer/全局设置/VBox/游戏速度行/SpeedSlider")
	if ss:
		ss.value_changed.connect(_on_speed_changed)
		print("  ✅ SpeedSlider.value_changed 已连接")
	else:
		push_warning("SpeedSlider 节点为空，信号未连接")

	var dc: CheckBox = _get_node("MainPanel/VBox/TabContainer/全局设置/VBox/调试模式行/DebugCheck")
	if dc:
		dc.toggled.connect(_on_debug_toggled)
		print("  ✅ DebugCheck.toggled 已连接")
	else:
		push_warning("DebugCheck 节点为空，信号未连接")

	# —— 配置导出/导入按钮 ——
	var eb: Button = _get_node("MainPanel/VBox/TabContainer/全局设置/VBox/配置按钮行/ExportButton")
	if eb:
		eb.pressed.connect(_on_export_pressed)
		print("  ✅ ExportButton.pressed 已连接")
	else:
		push_warning("ExportButton 节点为空，信号未连接")

	var ib: Button = _get_node("MainPanel/VBox/TabContainer/全局设置/VBox/配置按钮行/ImportButton")
	if ib:
		ib.pressed.connect(_on_import_pressed)
		print("  ✅ ImportButton.pressed 已连接")
	else:
		push_warning("ImportButton 节点为空，信号未连接")

	# —— 文件对话框 ——
	var ed: FileDialog = _get_node("ExportDialog")
	if ed:
		ed.file_selected.connect(_on_export_dialog_confirmed)
		print("  ✅ ExportDialog.file_selected 已连接")
	else:
		push_warning("ExportDialog 节点为空，信号未连接")

	var id: FileDialog = _get_node("ImportDialog")
	if id:
		id.file_selected.connect(_on_import_dialog_confirmed)
		print("  ✅ ImportDialog.file_selected 已连接")
	else:
		push_warning("ImportDialog 节点为空，信号未连接")

	# —— TabContainer 标签页切换 ——
	var tc: TabContainer = _get_node("MainPanel/VBox/TabContainer")
	if tc:
		tc.tab_changed.connect(_on_tab_changed)
		print("  ✅ TabContainer.tab_changed 已连接")
	else:
		push_warning("TabContainer 节点为空，信号未连接")

	print("✅ 信号连接完成")


# =========================================
# 刷新概率 UI 显示
# =========================================
func _refresh_prob_ui() -> void:
	if not Engine.has_singleton("GlobalLuckController"):
		return
	var glc = Engine.get_singleton("GlobalLuckController")
	var key: String = SYSTEM_KEYS[current_system_idx]
	if not glc.luck_config.has(key):
		return

	var cfg: Dictionary = glc.luck_config[key]

	var rs: SpinBox = _nodes.get("rate_spin")
	if rs:
		rs.value = ccfg.base_rate * 100.0

	var ll: Label = _nodes.get("luck_label")
	if ll:
		ll.text = "%.1f%%" % [ccfg.current_luck * 100.0]

	var ml: Label = _nodes.get("max_rate_label")
	if ml:
		ml.text = "%.1f%%" % [ccfg.max_rate * 100.0]


# =========================================
# 信号回调
# =========================================
func _on_prompt_selected(index: int) -> void:
	if Engine.has_singleton("GlobalLuckController"):
		Engine.get_singleton("GlobalLuckController").set_prompt_level(index)
	print("🔔 提示强度 → %s" % ["关闭", "仅核心", "全量"][index])


func _on_system_selected(index: int) -> void:
	current_system_idx = index
	_refresh_prob_ui()
	print("📊 切换概率事件 → %s" % SYSTEM_NAMES[index])


func _on_rate_changed(_value: float) -> void:
	"""基础概率滑块实时刷新（不立即应用，等点击「应用」）"""
	var rs: SpinBox = _nodes.get("rate_spin")
	if rs:
		print("📊 基础概率调整中：%.1f%%" % rs.value)


func _on_apply_pressed() -> void:
	if not Engine.has_singleton("GlobalLuckController"):
		return
	var glc = Engine.get_singleton("GlobalLuckController")
	var key: String = SYSTEM_KEYS[current_system_idx]
	var rate: float = (_nodes.get("rate_spin") as SpinBox).value / 100.0
	glc.set_base_rate(key, rate)
	_refresh_prob_ui()
	print("✅ 应用：%s 基础概率 → %.1f%%" % [SYSTEM_NAMES[current_system_idx], rate * 100.0])


func _on_reset_pressed() -> void:
	if not Engine.has_singleton("GlobalLuckController"):
		return
	var glc = Engine.get_singleton("GlobalLuckController")
	var key: String = SYSTEM_KEYS[current_system_idx]
	glc.reset_luck(key)
	_refresh_prob_ui()
	print("🔄 重置：%s 保底值" % SYSTEM_NAMES[current_system_idx])


func _on_test_pressed() -> void:
	if not Engine.has_singleton("GlobalLuckController"):
		return
	var glc = Engine.get_singleton("GlobalLuckController")
	var key: String = SYSTEM_KEYS[current_system_idx]
	var result: Array = glc.try_luck(key)
	var success: bool = result[0]
	var final_rate: float = result[1]
	var tl: Label = _nodes.get("test_result")
	if tl:
		tl.text = "【%s 测试】%s（最终概率：%.1f%%）" % [
			SYSTEM_NAMES[current_system_idx],
			"✅ 成功" if success else "❌ 失败",
			final_rate * 100.0,
		]
	_refresh_prob_ui()
	print("🎲 %s 测试结果：%s（%.1f%%）" % [
		SYSTEM_NAMES[current_system_idx],
		"成功" if success else "失败",
		final_rate * 100.0,
	])


func _on_realm_selected(index: int) -> void:
	print("📊 境界 → %s" % REALM_LIST[index])


func _on_max_level_pressed() -> void:
	var ls: SpinBox = _nodes.get("level_spin")
	if ls:
		ls.value = 999.0
	print("⚡ 一键满级（等级 → 999）")


func _on_max_stat_pressed() -> void:
	var hs: SpinBox = _nodes.get("hp_spin")
	var ms: SpinBox = _nodes.get("mp_spin")
	if hs:
		hs.value = 999999.0
	if ms:
		ms.value = 999999.0
	print("⚡ 一键满属性（生命/灵力 → 999999）")


func _on_search_changed(_text: String) -> void:
	_filter_items()


func _filter_items() -> void:
	var list: ItemList = _nodes.get("item_list") as ItemList
	var edit: LineEdit = _nodes.get("search_edit") as LineEdit
	if list == null or edit == null:
		return
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
	var list: ItemList = _nodes.get("item_list") as ItemList
	if list == null:
		return
	var selected: Array = list.get_selected_items()
	if selected.size() == 0:
		print("⚠️ 未选中任何物品，无法删除")
		return
	var idx: int = selected[0]
	if idx < item_data.size():
		var item = item_data[idx]
		item_data.remove_at(idx)
		_filter_items()
		print("➖ 删除物品：%s" % item.name)


func _on_speed_changed(value: float) -> void:
	Engine.time_scale = value
	var sl: Label = _nodes.get("speed_label")
	if sl:
		sl.text = "%.1fx" % value
	print("⏩ 游戏速度 → %.1fx" % value)


func _on_debug_toggled(pressed: bool) -> void:
	print("🐛 调试模式 → %s" % ("开启" if pressed else "关闭"))


func _on_tab_changed(_tab: int) -> void:
	"""标签页切换时打印日志（方便调试）"""
	var tc: TabContainer = _nodes.get("tab_container")
	if tc:
		print("📑 切换标签页 → %s" % tc.get_tab_title(_tab))


# =========================================
# 配置导出/导入功能
# =========================================
func _on_export_pressed() -> void:
	"""点击「导出配置」按钮，打开文件保存对话框"""
	var dialog: FileDialog = _nodes.get("export_dialog")
	if dialog:
		dialog.popup_centered(Vector2i(600, 400))
		print("📤 打开导出文件对话框")


func _on_export_dialog_confirmed(path: String) -> void:
	"""确认导出文件路径，生成 CSV 文件"""
	if not Engine.has_singleton("GlobalLuckController"):
		push_warning("GlobalLuckController 单例未找到，无法导出")
		return
	
	var glc = Engine.get_singleton("GlobalLuckController")
	var csv_lines: Array = []
	
	# CSV 表头
	csv_lines.append("事件ID,事件名称,基础概率(%),保底等级(%),最高概率(%),备注")
	
	# 遍历所有概率系统
	for i in range(SYSTEM_KEYS.size()):
		var key: String = SYSTEM_KEYS[i]
		var name: String = SYSTEM_NAMES[i]
		if glc.luck_config.has(key):
			var cfg: Dictionary = glc.luck_config[key]
			var line: String = "%s,%s,%.1f,%.1f,%.1f,%s" % [
				key,
				name,
				ccfg.base_rate * 100.0,
				ccfg.current_luck * 100.0,
				ccfg.max_rate * 100.0,
				"",  # 备注留空
			]
			csv_lines.append(line)
	
	# 写入文件
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		for line in csv_lines:
			file.store_line(line)
		file.close()
		print("✅ 配置导出成功！文件路径：%s" % path)
		print("  📄 共导出 %d 条概率配置" % [csv_lines.size() - 1])
	else:
		push_error("❌ 无法打开文件：%s" % path)


func _on_import_pressed() -> void:
	"""点击「导入配置」按钮，打开文件选择对话框"""
	var dialog: FileDialog = _nodes.get("import_dialog")
	if dialog:
		dialog.popup_centered(Vector2i(600, 400))
		print("📥 打开导入文件对话框")


func _on_import_dialog_confirmed(path: String) -> void:
	"""确认导入文件路径，解析 CSV 文件并更新配置"""
	if not Engine.has_singleton("GlobalLuckController"):
		push_warning("GlobalLuckController 单例未找到，无法导入")
		return
	
	# 读取文件
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("❌ 无法打开文件：%s" % path)
		return
	
	var line_num: int = 0
	var success_count: int = 0
	var error_msgs: Array = []
	
	# 逐行解析
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		line_num += 1
		
		# 跳过空行和表头
		if line.is_empty() or line.begins_with("事件ID"):
			continue
		
		# 解析 CSV 行
		var parts: Array = line.split(",")
		if parts.size() < 3:
			error_msgs.append("第 %d 行：格式错误（至少需要 3 列）" % line_num)
			continue
		
		var key: String = parts[0].strip_edges()
		var base_rate_str: String = parts[2].strip_edges()
		
		# 校验事件 ID
		if not SYSTEM_KEYS.has(key):
			error_msgs.append("第 %d 行：未知事件 ID「%s」" % [line_num, key])
			continue
		
		# 校验基础概率
		var base_rate: float = base_rate_str.to_float() / 100.0
		if base_rate < 0.0 or base_rate > 1.0:
			error_msgs.append("第 %d 行：基础概率超出范围（0-100）" % line_num)
			continue
		
		# 应用配置
		Engine.get_singleton("GlobalLuckController").set_base_rate(key, base_rate)
		success_count += 1
	
	file.close()
	
	# 刷新 UI
	_refresh_prob_ui()
	
	# 打印结果
	print("✅ 配置导入完成！")
	print("  📊 成功：%d 条" % success_count)
	if error_msgs.size() > 0:
		print("  ⚠️ 失败：%d 条" % error_msgs.size())
		for msg in error_msgs:
			print("    - %s" % msg)
	else:
		print("  ✅ 全部成功，无错误")
	
	# 显示结果到 UI（如果有测试结果标签）
	var tl: Label = _nodes.get("test_result")
	if tl:
		var msg: String = "导入完成：成功 %d 条" % success_count
		if error_msgs.size() > 0:
			msg += "，失败 %d 条（详见控制台）" % error_msgs.size()
		tl.text = msg
