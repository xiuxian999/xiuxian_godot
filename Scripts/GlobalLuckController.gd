# ==========================================
# 魂穿凡人 - 全局保底概率控制器
# 作用：管理所有几率系统的全局概率
# 挂载方式：Project Settings → Autoload → 添加为全局单例
# ==========================================

extends Node

# ==========================================
# 信号
# ==========================================
signal luck_changed(system_name: String, new_value: float)  # 概率变更信号
signal prompt_triggered(level: int, message: String)        # 提示触发信号

# ==========================================
# 枚举：提示级别
# ==========================================
enum PromptLevel {
	PROMPT_OFF,      # 0 = 关闭所有提示
	PROMPT_SIMPLE,   # 1 = 简洁提示（只显示关键信息）
	PROMPT_DETAILED, # 2 = 详细提示（显示完整几率计算过程）
}

# ==========================================
# 几率系统配置（可在 GM 工具中实时调整）
# ==========================================
var luck_config: Dictionary = {
	# ---------- 炼丹系统 ----------
	"alchemy_crit": {
		"base_rate": 0.15,      # 基础暴击率 15%
		"max_rate": 0.80,        # 最高暴击率 80%
		"luck_bonus": 0.05,      # 每次失败累计的保底加成
		"current_luck": 0.00,    # 当前保底值（累计）
		"enabled": true,
	},
	# ---------- 炼器系统 ----------
	"forging_crit": {
		"base_rate": 0.12,      # 基础暴击率 12%
		"max_rate": 0.75,
		"luck_bonus": 0.04,
		"current_luck": 0.00,
		"enabled": true,
	},
	# ---------- 灵兽初值随机 ----------
	"beast_initial": {
		"base_rate": 0.10,      # 出现高初值的概率 10%
		"max_rate": 0.60,
		"luck_bonus": 0.03,
		"current_luck": 0.00,
		"enabled": true,
	},
	# ---------- 灵兽成长率随机 ----------
	"beast_growth": {
		"base_rate": 0.08,      # 出现高成长率的概率 8%
		"max_rate": 0.50,
		"luck_bonus": 0.02,
		"current_luck": 0.00,
		"enabled": true,
	},
	# ---------- 战斗暴击 ----------
	"combat_crit": {
		"base_rate": 0.20,      # 基础暴击率 20%
		"max_rate": 0.85,
		"luck_bonus": 0.06,
		"current_luck": 0.00,
		"enabled": true,
	},
}

# 当前提示级别（可被 GM 工具修改）
var current_prompt_level: int = PromptLevel.PROMPT_DETAILED
# 配置文件路径
const CONFIG_PATH: String = "user://global_luck_config.cfg"

# ==========================================
# 生命周期
# ==========================================
func _ready():
	print("✅ GlobalLuckController 已加载")
	# 加载配置
	_load_config()
	print("📊 当前几率配置：")
	_print_current_config()


# ==========================================
# 核心方法：尝试暴击/高价值结果
# 返回值：(是否成功: bool, 最终概率: float)
# ==========================================
func try_luck(system_name: String) -> Array:
	if not luck_config.has(system_name):
		push_error("❌ 未知的几率系统：%s" % system_name)
		return [false, 0.0]
	
	var config = luck_config[system_name]
	if not config.enabled:
		_trigger_prompt(1, "【%s】系统已关闭，本次必定失败" % system_name)
		return [false, 0.0]
	
	# 计算最终概率 = 基础概率 + 保底加成
	var final_rate = config.base_rate + config.current_luck
	final_rate = clamp(final_rate, 0.0, config.max_rate)
	
	# 随机数判定
	var rand = randf()
	var is_success = rand < final_rate
	
	# 触发提示
	if current_prompt_level >= PromptLevel.PROMPT_SIMPLE:
		var msg = "【%s】%s（概率：%.1f%%）" % [
			system_name,
			"✅ 成功" if is_success else "❌ 失败",
			final_rate * 100
		]
		_trigger_prompt(1, msg)
	
	if current_prompt_level >= PromptLevel.PROMPT_DETAILED:
		var detail = "详细信息：基础%.1f%% + 保底%.1f%% = 最终%.1f%%，随机值%.3f" % [
			config.base_rate * 100,
			config.current_luck * 100,
			final_rate * 100,
			rand
		]
		_trigger_prompt(2, detail)
	
	# 更新保底值
	if is_success:
		# 成功了，重置保底
		config.current_luck = 0.0
		_trigger_prompt(1, "🎉 保底已重置")
	else:
		# 失败了，增加保底
		config.current_luck += config.luck_bonus
		config.current_luck = min(config.current_luck, config.max_rate - config.base_rate)
		_trigger_prompt(1, "📈 保底增加至 %.1f%%" % (config.current_luck * 100))
	
	luck_changed.emit(system_name, final_rate)
	return [is_success, final_rate]


# ==========================================
# 强制设置某个系统的概率（GM 工具用）
# ==========================================
func set_base_rate(system_name: String, new_rate: float) -> void:
	if not luck_config.has(system_name):
		push_error("❌ 未知的几率系统：%s" % system_name)
		return
	new_rate = clamp(new_rate, 0.0, 1.0)
	luck_config[system_name].base_rate = new_rate
	_trigger_prompt(1, "⚙️ 【%s】基础概率已设为 %.1f%%" % [system_name, new_rate * 100])
	print("⚙️ GM 指令：%s 基础概率 → %.1f%%" % [system_name, new_rate * 100])


func set_luck_bonus(system_name: String, new_bonus: float) -> void:
	if not luck_config.has(system_name):
		push_error("❌ 未知的几率系统：%s" % system_name)
		return
	new_bonus = clamp(new_bonus, 0.0, 1.0)
	luck_config[system_name].luck_bonus = new_bonus
	_trigger_prompt(1, "⚙️ 【%s】保底加成已设为 %.1f%%/次" % [system_name, new_bonus * 100])


func reset_luck(system_name: String = "") -> void:
	"""重置保底值（可指定单个系统，或传空字符串重置全部）"""
	if system_name == "":
		for key in luck_config:
			luck_config[key].current_luck = 0.0
		_trigger_prompt(1, "🔄 全部保底值已重置")
		print("🔄 GM 指令：全部保底值 → 重置")
	else:
		if luck_config.has(system_name):
			luck_config[system_name].current_luck = 0.0
			_trigger_prompt(1, "🔄 【%s】保底值已重置" % system_name)


# ==========================================
# 设置提示级别（GM 工具用）
# ==========================================
func set_prompt_level(level: int) -> void:
	current_prompt_level = clamp(level, 0, 2)
	var level_name = ["关闭", "简洁", "详细"][current_prompt_level]
	_trigger_prompt(0, "🔔 提示级别已设为：【%s】" % level_name)
	print("🔔 提示级别 → %s" % level_name)
	# 保存配置
	_save_config()


# ==========================================
# 内部方法：触发提示
# ==========================================
func _trigger_prompt(min_level: int, message: String) -> void:
	if current_prompt_level >= min_level:
		prompt_triggered.emit(current_prompt_level, message)
		if current_prompt_level >= min_level:
			print("  [提示 Lv.%d] %s" % [current_prompt_level, message])


# ==========================================
# 调试：打印当前配置
# ==========================================
func _print_current_config() -> void:
	for key in luck_config:
		var cfg = luck_config[key]
		print("  - %s：基础%.1f%% | 最高%.1f%% | 保底+%.1f%%/次 | 当前保底%.1f%%" % [
			key,
			cfg.base_rate * 100,
			cfg.max_rate * 100,
			cfg.luck_bonus * 100,
			cfg.current_luck * 100,
		])


# ==========================================
# 获取当前配置（导出用，供 GM 工具读取）
# ==========================================
func get_config() -> Dictionary:
	return luck_config.duplicate(true)


func get_system_names() -> Array:
	return luck_config.keys()


# ==========================================
# 配置保存/加载
# ==========================================
func _save_config() -> void:
	"""保存配置到本地文件"""
	var config = ConfigFile.new()
	
	# 保存提示级别
	config.set_value("settings", "prompt_level", current_prompt_level)
	
	# 保存几率配置
	for key in luck_config:
		var cfg = luck_config[key]
		config.set_value("luck_config", key + "/base_rate", cfg.base_rate)
		config.set_value("luck_config", key + "/max_rate", cfg.max_rate)
		config.set_value("luck_config", key + "/luck_bonus", cfg.luck_bonus)
		config.set_value("luck_config", key + "/current_luck", cfg.current_luck)
		config.set_value("luck_config", key + "/enabled", cfg.enabled)
	
	# 写入文件
	var err = config.save(CONFIG_PATH)
	if err == OK:
		print("💾 配置已保存：%s" % ProjectSettings.globalize_path(CONFIG_PATH))
	else:
		push_error("❌ 配置保存失败：%d" % err)


func _load_config() -> void:
	"""从本地文件加载配置"""
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	
	if err != OK:
		print("📁 配置文件不存在，使用默认配置")
		# 保存默认配置
		_save_config()
		return
	
	# 加载提示级别
	if config.has_section_key("settings", "prompt_level"):
		current_prompt_level = config.get_value("settings", "prompt_level")
		print("🔔 提示级别已加载：%d" % current_prompt_level)
	
	# 加载几率配置
	for key in luck_config:
		if config.has_section_key("luck_config", key + "/base_rate"):
			luck_config[key].base_rate = config.get_value("luck_config", key + "/base_rate")
		if config.has_section_key("luck_config", key + "/max_rate"):
			luck_config[key].max_rate = config.get_value("luck_config", key + "/max_rate")
		if config.has_section_key("luck_config", key + "/luck_bonus"):
			luck_config[key].luck_bonus = config.get_value("luck_config", key + "/luck_bonus")
		if config.has_section_key("luck_config", key + "/current_luck"):
			luck_config[key].current_luck = config.get_value("luck_config", key + "/current_luck")
		if config.has_section_key("luck_config", key + "/enabled"):
			luck_config[key].enabled = config.get_value("luck_config", key + "/enabled")
	
	print("📂 配置已加载：%s" % CONFIG_PATH)
