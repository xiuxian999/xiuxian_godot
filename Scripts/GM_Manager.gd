# ==========================================
# 魂穿凡人 - GM 工具箱脚本
# 功能：5标签页 GM 管理工具
# 挂载：GM_Manager.tscn 根节点
# ==========================================

extends Control

# ==========================================
# 节点引用（由 _ready 自动获取）
# ==========================================
# Tab 1 - 概率控制
var alchemy_slider: HSlider
var forging_slider: HSlider
var beast_init_slider: HSlider
var beast_growth_slider: HSlider
var combat_crit_slider: HSlider
var alchemy_label: Label
var forging_label: Label
var beast_init_label: Label
var beast_growth_label: Label
var combat_crit_label: Label
var test_result_label: Label

# Tab 2 - 玩家数据
var realm_option: OptionButton
var level_spin: SpinBox
var hp_spin: SpinBox
var mp_spin: SpinBox
var atk_spin: SpinBox
var def_spin: SpinBox
var spd_spin: SpinBox

# Tab 3 - 物品管理
var search_edit: LineEdit
var item_list: ItemList

# Tab 4 - 系统设置
var prompt_option: OptionButton
var speed_slider: HSlider
var speed_label: Label
var debug_check: CheckBox
var god_mode_check: CheckBox

# Tab 5 - 日志导出
var log_text: TextEdit

# ==========================================
# 数据：境界列表
# ==========================================
const REALM_LIST: Array = [
	"炼气一层", "炼气二层", "炼气三层", "炼气四层", "炼气五层", "炼气六层",
	"炼气七层", "炼气八层", "炼气九层", "炼气十层", "炼气十一层", "炼气十二层",
	"筑基初期", "筑基中期", "筑基后期", "筑基圆满",
	"结丹初期", "结丹中期", "结丹后期", "结丹圆满",
	"元婴初期", "元婴中期", "元婴后期", "元婴圆满",
	"化神初期", "化神中期", "化神后期", "化神圆满",
]

# 数据：物品列表（内存中）
var item_data: Array = []


# ==========================================
# 生命周期
# ==========================================
func _ready():
	print("🔧 GM 工具箱已打开")
	_init_node_refs()
	_init_ui_values()
	_init_realm_options()
	_connect_signals()
	_write_log("🔧 GM 工具箱已启动")


# ==========================================
# 初始化：获取节点引用
# ==========================================
func _init_node_refs():
	# Tab 1 - 概率控制
	alchemy_slider = get_node("%概率控制/VBox/概率控制容器/炼丹暴击/RateSlider")
	alchemy_label = get_node("%概率控制/VBox/概率控制容器/炼丹暴击/RateLabel")
	forging_slider = get_node("%概率控制/VBox/概率控制容器/炼器暴击/RateSlider")
	forging_label = get_node("%概率控制/VBox/概率控制容器/炼器暴击/RateLabel")
	beast_init_slider = get_node("%概率控制/VBox/概率控制容器/灵兽初值/RateSlider")
	beast_init_label = get_node("%概率控制/VBox/概率控制容器/灵兽初值/RateLabel")
	beast_growth_slider = get_node("%概率控制/VBox/概率控制容器/灵兽成长/RateSlider")
	beast_growth_label = get_node("%概率控制/VBox/概率控制容器/灵兽成长/RateLabel")
	combat_crit_slider = get_node("%概率控制/VBox/概率控制容器/战斗暴击/RateSlider")
	combat_crit_label = get_node("%概率控制/VBox/概率控制容器/战斗暴击/RateLabel")
	test_result_label = get_node("%概率控制/VBox/测试结果")
	
	# Tab 2 - 玩家数据
	realm_option = get_node("%玩家数据/VBox/属性容器/境界/RealmOption")
	level_spin = get_node("%玩家数据/VBox/属性容器/等级/LevelSpin")
	hp_spin = get_node("%玩家数据/VBox/属性容器/生命/HpSpin")
	mp_spin = get_node("%玩家数据/VBox/属性容器/灵力/MpSpin")
	atk_spin = get_node("%玩家数据/VBox/属性容器/攻击/AtkSpin")
	def_spin = get_node("%玩家数据/VBox/属性容器/防御/DefSpin")
	spd_spin = get_node("%玩家数据/VBox/属性容器/速度/SpdSpin")
	
	# Tab 3 - 物品管理
	search_edit = get_node("%物品管理/VBox/搜索栏/SearchEdit")
	item_list = get_node("%物品管理/VBox/物品列表")
	
	# Tab 4 - 系统设置
	prompt_option = get_node("%系统设置/VBox/提示级别/PromptOption")
	speed_slider = get_node("%系统设置/VBox/游戏速度/SpeedSlider")
	speed_label = get_node("%系统设置/VBox/游戏速度/SpeedLabel")
	debug_check = get_node("%系统设置/VBox/调试模式/DebugCheck")
	god_mode_check = get_node("%系统设置/VBox/无敌模式/GodModeCheck")
	
	# Tab 5 - 日志导出
	log_text = get_node("%日志导出/VBox/日志显示")


# ==========================================
# 初始化：设置 UI 初始值
# ==========================================
func _init_ui_values():
	# 从 GlobalLuckController 读取当前配置
	if not Engine.has_singleton("GlobalLuckController"):
		return
	var glc = Engine.get_singleton("GlobalLuckController")
	if not glc:
		return
	
	# 设置滑块初始值
	if alchemy_slider and glc.luck_config.has("alchemy_crit"):
		alchemy_slider.value = glc.luck_config["alchemy_crit"].base_rate * 100
		alchemy_label.text = "%.0f%%" % alchemy_slider.value
	
	if forging_slider and glc.luck_config.has("forging_crit"):
		forging_slider.value = glc.luck_config["forging_crit"].base_rate * 100
		forging_label.text = "%.0f%%" % forging_slider.value
	
	if beast_init_slider and glc.luck_config.has("beast_initial"):
		beast_init_slider.value = glc.luck_config["beast_initial"].base_rate * 100
		beast_init_label.text = "%.0f%%" % beast_init_slider.value
	
	if beast_growth_slider and glc.luck_config.has("beast_growth"):
		beast_growth_slider.value = glc.luck_config["beast_growth"].base_rate * 100
		beast_growth_label.text = "%.0f%%" % beast_growth_slider.value
	
	if combat_crit_slider and glc.luck_config.has("combat_crit"):
		combat_crit_slider.value = glc.luck_config["combat_crit"].base_rate * 100
		combat_crit_label.text = "%.0f%%" % combat_crit_slider.value
	
	# 设置提示级别下拉
	if prompt_option:
		prompt_option.select(glc.current_prompt_level)


# ==========================================
# 初始化：填充境界下拉列表
# ==========================================
func _init_realm_options():
	if not realm_option:
		return
	realm_option.clear()
	for realm in REALM_LIST:
		realm_option.add_item(realm)


# ==========================================
# 初始化：连接信号
# ==========================================
func _connect_signals():
	# 关闭按钮
	get_node("VBox/TitleBar/CloseButton").pressed.connect(_on_close_button_pressed)
	
	# Tab 1 信号
	if alchemy_slider: alchemy_slider.value_changed.connect(_on_alchemy_rate_changed)
	if forging_slider: forging_slider.value_changed.connect(_on_forging_rate_changed)
	if beast_init_slider: beast_init_slider.value_changed.connect(_on_beast_init_rate_changed)
	if beast_growth_slider: beast_growth_slider.value_changed.connect(_on_beast_growth_rate_changed)
	if combat_crit_slider: combat_crit_slider.value_changed.connect(_on_combat_crit_rate_changed)
	
	get_node("%概率控制/VBox/批量操作/All50Button").pressed.connect(_on_all_50_pressed)
	get_node("%概率控制/VBox/批量操作/All80Button").pressed.connect(_on_all_80_pressed)
	get_node("%概率控制/VBox/批量操作/ResetButton").pressed.connect(_on_reset_luck_pressed)
	
	get_node("%概率控制/VBox/测试按钮容器/TestAlchemyButton").pressed.connect(_on_test_alchemy_pressed)
	get_node("%概率控制/VBox/测试按钮容器/TestForgingButton").pressed.connect(_on_test_forging_pressed)
	get_node("%概率控制/VBox/测试按钮容器/TestCombatButton").pressed.connect(_on_test_combat_pressed)
	
	# Tab 2 信号
	get_node("%玩家数据/VBox/快捷操作/MaxLevelButton").pressed.connect(_on_max_level_pressed)
	get_node("%玩家数据/VBox/快捷操作/MaxStatButton").pressed.connect(_on_max_stat_pressed)
	get_node("%玩家数据/VBox/快捷操作/AddItemButton").pressed.connect(_on_add_item_pressed)
	realm_option.item_selected.connect(_on_realm_selected)
	
	# Tab 3 信号
	get_node("%物品管理/VBox/搜索栏/SearchButton").pressed.connect(_on_search_pressed)
	search_edit.text_changed.connect(_on_search_text_changed)
	get_node("%物品管理/VBox/操作栏/AddButton").pressed.connect(_on_add_item_pressed)
	get_node("%物品管理/VBox/操作栏/DeleteButton").pressed.connect(_on_delete_item_pressed)
	get_node("%物品管理/VBox/操作栏/ClearButton").pressed.connect(_on_clear_items_pressed)
	get_node("%物品管理/VBox/Excel操作/ImportButton").pressed.connect(_on_import_excel_pressed)
	get_node("%物品管理/VBox/Excel操作/ExportButton").pressed.connect(_on_export_excel_pressed)
	
	# Tab 4 信号
	prompt_option.item_selected.connect(_on_prompt_level_selected)
	speed_slider.value_changed.connect(_on_speed_changed)
	debug_check.toggled.connect(_on_debug_toggled)
	god_mode_check.toggled.connect(_on_god_mode_toggled)
	get_node("%系统设置/VBox/保存设置").pressed.connect(_on_save_settings_pressed)
	get_node("%系统设置/VBox/重置设置").pressed.connect(_on_reset_settings_pressed)
	
	# Tab 5 信号
	get_node("%日志导出/VBox/清空日志").pressed.connect(_on_clear_log_pressed)
	get_node("%日志导出/VBox/存档操作/SaveButton").pressed.connect(_on_save_pressed)
	get_node("%日志导出/VBox/存档操作/LoadButton").pressed.connect(_on_load_pressed)
	get_node("%日志导出/VBox/存档操作/ExportSaveButton").pressed.connect(_on_export_save_pressed)
	get_node("%日志导出/VBox/存档操作/ImportSaveButton").pressed.connect(_on_import_save_pressed)


# ==========================================
# Tab 1 回调：概率滑块变化
# ==========================================
func _on_alchemy_rate_changed(value: float):
	alchemy_label.text = "%.0f%%" % value
	if Engine.has_singleton("GlobalLuckController"):
		Engine.get_singleton("GlobalLuckController").set_base_rate("alchemy_crit", value / 100.0)

func _on_forging_rate_changed(value: float):
	forging_label.text = "%.0f%%" % value
	if Engine.has_singleton("GlobalLuckController"):
		Engine.get_singleton("GlobalLuckController").set_base_rate("forging_crit", value / 100.0)

func _on_beast_init_rate_changed(value: float):
	beast_init_label.text = "%.0f%%" % value
	if Engine.has_singleton("GlobalLuckController"):
		Engine.get_singleton("GlobalLuckController").set_base_rate("beast_initial", value / 100.0)

func _on_beast_growth_rate_changed(value: float):
	beast_growth_label.text = "%.0f%%" % value
	if Engine.has_singleton("GlobalLuckController"):
		Engine.get_singleton("GlobalLuckController").set_base_rate("beast_growth", value / 100.0)

func _on_combat_crit_rate_changed(value: float):
	combat_crit_label.text = "%.0f%%" % value
	if Engine.has_singleton("GlobalLuckController"):
		Engine.get_singleton("GlobalLuckController").set_base_rate("combat_crit", value / 100.0)


# ==========================================
# Tab 1 回调：批量操作
# ==========================================
func _on_all_50_pressed():
	_set_all_rates(50.0)
	_write_log("📊 批量设置：全部概率 → 50%")

func _on_all_80_pressed():
	_set_all_rates(80.0)
	_write_log("📊 批量设置：全部概率 → 80%")

func _on_reset_luck_pressed():
	if Engine.has_singleton("GlobalLuckController"):
		Engine.get_singleton("GlobalLuckController").reset_luck("")
	_write_log("🔄 保底值已全部重置")

func _set_all_rates(rate: float):
	if alchemy_slider: alchemy_slider.value = rate
	if forging_slider: forging_slider.value = rate
	if beast_init_slider: beast_init_slider.value = rate
	if beast_growth_slider: beast_growth_slider.value = rate
	if combat_crit_slider: combat_crit_slider.value = rate


# ==========================================
# Tab 1 回调：测试几率
# ==========================================
func _on_test_alchemy_pressed():
	_perform_test("alchemy_crit", "炼丹")

func _on_test_forging_pressed():
	_perform_test("forging_crit", "炼器")

func _on_test_combat_pressed():
	_perform_test("combat_crit", "战斗")

func _perform_test(system: String, name: String):
	if not Engine.has_singleton("GlobalLuckController"):
		test_result_label.text = "❌ GlobalLuckController 未加载"
		return
	var glc = Engine.get_singleton("GlobalLuckController")
	var result = glc.try_luck(system)
	var success = result[0]
	var rate = result[1]
	test_result_label.text = "【%s 测试】%s（概率：%.1f%%）" % [name, "✅ 暴击！" if success else "❌ 未暴击", rate * 100]
	_write_log("🧪 测试 %s：%s（%.1f%%）" % [name, "成功" if success else "失败", rate * 100])


# ==========================================
# Tab 2 回调：玩家数据
# ==========================================
func _on_realm_selected(index: int):
	_write_log("📊 境界已选择：%s" % REALM_LIST[index])

func _on_max_level_pressed():
	level_spin.value = 999
	_write_log("⚡ 一键满级：等级 → 999")

func _on_max_stat_pressed():
	hp_spin.value = 999999
	mp_spin.value = 999999
	atk_spin.value = 99999
	def_spin.value = 99999
	spd_spin.value = 9999
	_write_log("⚡ 一键满属性：生命/灵力/攻击/防御/速度 → 最大值")

func _on_add_item_pressed():
	_write_log("🎁 添加物品功能：请切换到【物品管理】标签页操作")


# ==========================================
# Tab 3 回调：物品管理
# ==========================================
func _on_search_pressed():
	_filter_items()

func _on_search_text_changed(_text: String):
	_filter_items()

func _filter_items():
	if not item_list:
		return
	item_list.clear()
	var keyword = search_edit.text.to_lower()
	for item in item_data:
		if keyword == "" or keyword in item.name.to_lower() or keyword in item.id.to_lower():
			item_list.add_item("%s (ID: %s)" % [item.name, item.id])

func _on_add_item_pressed():
	# 简单示例：添加一个测试物品
	var new_item = {
		"id": "item_%d" % (item_data.size() + 1),
		"name": "测试物品%d" % (item_data.size() + 1),
		"quality": "绿",
		"count": 1,
	}
	item_data.append(new_item)
	_filter_items()
	_write_log("➕ 添加物品：%s (ID: %s)" % [new_item.name, new_item.id])

func _on_delete_item_pressed():
	if not item_list or item_list.get_selected_items().size() == 0:
		return
	var idx = item_list.get_selected_items()[0]
	if idx < item_data.size():
		var item = item_data[idx]
		item_data.remove_at(idx)
		_filter_items()
		_write_log("➖ 删除物品：%s" % item.name)

func _on_clear_items_pressed():
	item_data.clear()
	_filter_items()
	_write_log("🗑️ 物品列表已清空")


# ==========================================
# Tab 3 回调：Excel 导入导出
# ==========================================
func _on_import_excel_pressed():
	_write_log("📥 Excel 导入：功能开发中（需要 Godot 4.3+ 的 Excel 解析库）")
	# 实际实现需要：
	# 1. 使用 FileDialog 选择 .xlsx 文件
	# 2. 使用第三方库（如 godot-xlsx-parser）解析
	# 3. 将解析结果写入 item_data

func _on_export_excel_pressed():
	_write_log("📤 Excel 导出：功能开发中（需要 Godot 4.3+ 的 Excel 写入库）")
	# 实际实现需要：
	# 1. 使用 FileDialog 选择保存路径
	# 2. 使用第三方库将 item_data 写入 .xlsx
	# 3. 提示用户导出成功


# ==========================================
# Tab 4 回调：系统设置
# ==========================================
func _on_prompt_level_selected(index: int):
	if Engine.has_singleton("GlobalLuckController"):
		Engine.get_singleton("GlobalLuckController").set_prompt_level(index)
	_write_log("🔔 提示级别已设为：%s" % ["关闭", "简洁", "详细"][index])

func _on_speed_changed(value: float):
	speed_label.text = "%.1fx" % value
	Engine.time_scale = value
	_write_log("⏩ 游戏速度已设为：%.1fx" % value)

func _on_debug_toggled(pressed: bool):
	_write_log("🐛 调试模式：%s" % ("✅ 开启" if pressed else "❌ 关闭"))

func _on_god_mode_toggled(pressed: bool):
	_write_log("🛡️ 无敌模式：%s" % ("✅ 开启" if pressed else "❌ 关闭"))

func _on_save_settings_pressed():
	_write_log("💾 设置已保存（功能开发中）")

func _on_reset_settings_pressed():
	if prompt_option: prompt_option.select(2)
	if speed_slider: speed_slider.value = 1.0
	if debug_check: debug_check.button_pressed = true
	if god_mode_check: god_mode_check.button_pressed = false
	_write_log("🔄 设置已重置为默认值")


# ==========================================
# Tab 5 回调：日志/存档
# ==========================================
func _on_clear_log_pressed():
	if log_text: log_text.text = ""
	_write_log("🗑️ 日志已清空")

func _on_save_pressed():
	_write_log("📁 手动存档：功能开发中")

func _on_load_pressed():
	_write_log("📂 读取存档：功能开发中")

func _on_export_save_pressed():
	_write_log("📤 导出存档：功能开发中")

func _on_import_save_pressed():
	_write_log("📥 导入存档：功能开发中")


# ==========================================
# 通用：写入日志
# ==========================================
func _write_log(message: String):
	if not log_text:
		return
	var timestamp = Time.get_datetime_string_from_system()
	log_text.text += "[%s] %s\n" % [timestamp, message]
	# 自动滚动到底部
	log_text.scroll_vertical = log_text.get_line_count()


# ==========================================
# 关闭按钮
# ==========================================
func _on_close_button_pressed():
	visible = false
	_write_log("🔧 GM 工具箱已关闭（按 F12 重新打开）")


# ==========================================
# 快捷键：F12 打开/关闭 GM 工具
# ==========================================
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F12:
			visible = not visible
			if visible:
				_write_log("🔧 GM 工具箱已打开")
