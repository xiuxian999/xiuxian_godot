# =========================================
# 魂穿凡人 - 主世界脚本
# 挂载：MainWorld.tscn 根节点
# 功能：主世界界面控制、GM 工具调用、角色信息显示
# =========================================

extends Control

# =========================================
# 节点缓存
# =========================================
var _nodes: Dictionary = {}


# =========================================
# 节点安全获取
# =========================================
func _get_node(path: String) -> Node:
	var n: Node = get_node_or_null(path)
	if n == null:
		push_warning("MainWorld：找不到节点 [%s]" % path)
	return n


func _cache_nodes() -> void:
	"""将所有子节点缓存到 _nodes 字典"""
	_nodes["level_label"] = _get_node("TopBar/CharacterInfo/LevelLabel")
	_nodes["realm_label"] = _get_node("TopBar/CharacterInfo/RealmLabel")
	_nodes["hp_bar"] = _get_node("TopBar/HPBar")
	_nodes["hp_label"] = _get_node("TopBar/HPBar/HPLabel")
	_nodes["mp_bar"] = _get_node("TopBar/MPBar")
	_nodes["mp_label"] = _get_node("TopBar/MPBar/MPLabel")
	_nodes["bag_button"] = _get_node("BottomBar/ButtonContainer/BagButton")
	_nodes["skill_button"] = _get_node("BottomBar/ButtonContainer/SkillButton")
	_nodes["task_button"] = _get_node("BottomBar/ButtonContainer/TaskButton")
	_nodes["map_button"] = _get_node("BottomBar/ButtonContainer/MapButton")
	_nodes["gm_button"] = _get_node("BottomBar/ButtonContainer/GMButton")
	_nodes["task_list"] = _get_node("LeftPanel/TaskList")
	print("✅ 主世界节点缓存完成，共缓存 %d 个节点" % _nodes.size())


# =========================================
# 生命周期
# =========================================
func _ready() -> void:
	print("🌍 主世界界面 初始化...")
	_cache_nodes()
	_connect_signals()
	_update_character_info()
	# 确保面板可见
	visible = true
	print("✅ 主世界界面 初始化完成")


# =========================================
# 信号连接
# =========================================
func _connect_signals() -> void:
	print("🔗 开始连接主世界信号...")
	
	# GM 按钮
	var gm_btn: Button = _nodes.get("gm_button")
	if gm_btn:
		gm_btn.pressed.connect(_on_gm_button_pressed)
		print("  ✅ GMButton.pressed 已连接")
	
	# 其他按钮（占位）
	var bag_btn: Button = _nodes.get("bag_button")
	if bag_btn:
		bag_btn.pressed.connect(_on_bag_button_pressed)
		print("  ✅ BagButton.pressed 已连接")
	
	var skill_btn: Button = _nodes.get("skill_button")
	if skill_btn:
		skill_btn.pressed.connect(_on_skill_button_pressed)
		print("  ✅ SkillButton.pressed 已连接")
	
	var task_btn: Button = _nodes.get("task_button")
	if task_btn:
		task_btn.pressed.connect(_on_task_button_pressed)
		print("  ✅ TaskButton.pressed 已连接")
	
	var map_btn: Button = _nodes.get("map_button")
	if map_btn:
		map_btn.pressed.connect(_on_map_button_pressed)
		print("  ✅ MapButton.pressed 已连接")
	
	print("✅ 主世界信号连接完成")


# =========================================
# 更新角色信息显示
# =========================================
func _update_character_info() -> void:
	"""更新顶部角色信息栏"""
	# TODO: 从玩家数据读取真实值
	var level: int = 1
	var realm: String = "炼气一层"
	var hp: float = 100.0
	var max_hp: float = 100.0
	var mp: float = 50.0
	var max_mp: float = 50.0
	
	# 更新标签
	var level_label: Label = _nodes.get("level_label")
	if level_label:
		level_label.text = "等级：%d" % level
	
	var realm_label: Label = _nodes.get("realm_label")
	if realm_label:
		realm_label.text = "境界：%s" % realm
	
	# 更新 HP 条
	var hp_bar: ProgressBar = _nodes.get("hp_bar")
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
	
	var hp_label: Label = _nodes.get("hp_label")
	if hp_label:
		hp_label.text = "HP: %.0f/%.0f" % [hp, max_hp]
	
	# 更新 MP 条
	var mp_bar: ProgressBar = _nodes.get("mp_bar")
	if mp_bar:
		mp_bar.max_value = max_mp
		mp_bar.value = mp
	
	var mp_label: Label = _nodes.get("mp_label")
	if mp_label:
		mp_label.text = "MP: %.0f/%.0f" % [mp, max_mp]
	
	print("📊 角色信息已更新")


# =========================================
# 信号回调
# =========================================
func _on_gm_button_pressed() -> void:
	"""点击 GM 按钮，打开/关闭 GM 工具箱"""
	print("🔧 切换 GM 工具箱")
	
	# 查找 GM_Manager 节点
	var gm = get_tree().get_root().find_child("GM_Manager", true, false)
	
	if gm == null:
		# GM_Manager 不存在，动态加载
		print("  ⚙️ 动态加载 GM_Manager 场景")
		var gm_scene = load("res://Scenes/GM_Manager.tscn")
		if gm_scene:
			gm = gm_scene.instantiate()
			gm.name = "GM_Manager"
			get_tree().get_root().add_child(gm)
			print("  ✅ GM_Manager 场景已加载")
		else:
			push_error("❌ 无法加载 GM_Manager 场景")
			return
	
	# 切换可见性
	gm.visible = not gm.visible
	print("  ✅ GM 工具箱 → %s" % ("显示" if gm.visible else "隐藏"))


func _on_bag_button_pressed() -> void:
	print("🎒 打开背包（待实现）")


func _on_skill_button_pressed() -> void:
	print("⚡ 打开技能（待实现）")


func _on_task_button_pressed() -> void:
	print("📋 打开任务（待实现）")


func _on_map_button_pressed() -> void:
	print("🗺️ 打开地图（待实现）")


# =========================================
# 公共方法：更新角色数据
# =========================================
func update_hp(hp: float, max_hp: float) -> void:
	"""更新 HP 显示"""
	var hp_bar: ProgressBar = _nodes.get("hp_bar")
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
	
	var hp_label: Label = _nodes.get("hp_label")
	if hp_label:
		hp_label.text = "HP: %.0f/%.0f" % [hp, max_hp]


func update_mp(mp: float, max_mp: float) -> void:
	"""更新 MP 显示"""
	var mp_bar: ProgressBar = _nodes.get("mp_bar")
	if mp_bar:
		mp_bar.max_value = max_mp
		mp_bar.value = mp
	
	var mp_label: Label = _nodes.get("mp_label")
	if mp_label:
		mp_label.text = "MP: %.0f/%.0f" % [mp, max_mp]


func update_level(level: int) -> void:
	"""更新等级显示"""
	var level_label: Label = _nodes.get("level_label")
	if level_label:
		level_label.text = "等级：%d" % level


func update_realm(realm: String) -> void:
	"""更新境界显示"""
	var realm_label: Label = _nodes.get("realm_label")
	if realm_label:
		realm_label.text = "境界：%s" % realm
