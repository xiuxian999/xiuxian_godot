extends CharacterBody2D

# ==========================================
# 魂穿凡人 - 玩家控制器
# 功能：WASD移动、8向动画、攻击硬直
# ==========================================

@export var speed: float = 200.0
@export var run_speed: float = 350.0
@export var attack_freeze: float = 0.4  # 攻击硬直时间（秒）

var is_attacking: bool = false
var is_hurt: bool = false
var is_dead: bool = false
var current_anim: String = "Idle"

# 动画名称常量
const ANIM_IDLE = "Idle"
const ANIM_WALK = "Walk"
const ANIM_RUN = "Run"
const ANIM_ATTACK = "Attack"
const ANIM_WALK_ATTACK = "Walk_Attack"
const ANIM_RUN_ATTACK = "Run_Attack"
const ANIM_HURT = "Hurt"
const ANIM_DEATH = "Death"

# 精灵图路径映射
const SPRITE_PATHS = {
	ANIM_IDLE: "res://Sprites/Swordsman_lvl3_Idle_with_shadow.png",
	ANIM_WALK: "res://Sprites/Swordsman_lvl3_Walk_with_shadow.png",
	ANIM_RUN: "res://Sprites/Swordsman_lvl3_Run_with_shadow.png",
	ANIM_ATTACK: "res://Sprites/Swordsman_lvl3_attack_with_shadow.png",
	ANIM_WALK_ATTACK: "res://Sprites/Swordsman_lvl3_Walk_Attack_with_shadow.png",
	ANIM_RUN_ATTACK: "res://Sprites/Swordsman_lvl3_Run_Attack_with_shadow.png",
	ANIM_HURT: "res://Sprites/Swordsman_lvl3_Hurt_with_shadow.png",
	ANIM_DEATH: "res://Sprites/Swordsman_lvl3_Death_with_shadow.png",
}

var sprite_frames: Dictionary = {}  # 缓存加载的纹理


func _ready():
	# 预加载所有精灵图
	for anim in SPRITE_PATHS:
		sprite_frames[anim] = load(SPRITE_PATHS[anim])
	# 加载动画到 AnimationPlayer
	_load_animations_to_player()
	# 设置初始动画
	_play_anim(ANIM_IDLE)


func _load_animations_to_player():
	"""将 Animations/ 目录中的动画资源加载到 AnimationPlayer"""
	if not has_node("AnimationPlayer"):
		return
	var ap = $AnimationPlayer
	var dir = DirAccess.open("res://Animations/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".res") and file_name != "SETUP_INSTRUCTIONS.txt":
			var anim_path = "res://Animations/" + file_name
			var anim_res = load(anim_path)
			if anim_res and anim_res is Animation:
				var anim_name = file_name.get_basename()
				if not ap.has_animation(anim_name):
					ap.add_animation(anim_name, anim_res)
		file_name = dir.get_next()
	print("✅ 动画已加载到 AnimationPlayer")


func _physics_process(delta):
	if is_dead:
		return
	if is_hurt:
		return  # 受伤硬直期间不能操作

	# 获取输入
	var input_vec = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input_vec.y -= 1
	if Input.is_key_pressed(KEY_S): input_vec.y += 1
	if Input.is_key_pressed(KEY_A): input_vec.x -= 1
	if Input.is_key_pressed(KEY_D): input_vec.x += 1

	# 归一化防止斜向移动过快
	if input_vec.length() > 0:
		input_vec = input_vec.normalized()

	# 检测是否按住了Shift（跑步）
	var is_running = Input.is_key_pressed(KEY_SHIFT)

	# 检测攻击输入
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		_attack()
		return

	# 移动
	if not is_attacking:
		if input_vec.length() > 0:
			if is_running:
				velocity = input_vec * run_speed
				_play_anim(ANIM_RUN)
			else:
				velocity = input_vec * speed
				_play_anim(ANIM_WALK)
		else:
			velocity = Vector2.ZERO
			_play_anim(ANIM_IDLE)

		move_and_slide()


func _attack():
	if is_attacking or is_dead:
		return
	is_attacking = true
	velocity = Vector2.ZERO

	# 根据当前状态选择攻击动画
	if current_anim == ANIM_WALK:
		_play_anim(ANIM_WALK_ATTACK)
	elif current_anim == ANIM_RUN:
		_play_anim(ANIM_RUN_ATTACK)
	else:
		_play_anim(ANIM_ATTACK)

	# 硬直计时器
	await get_tree().create_timer(attack_freeze).timeout
	is_attacking = false
	_play_anim(ANIM_IDLE)


func _play_anim(anim_name: String):
	if current_anim == anim_name and not is_attacking:
		return
	current_anim = anim_name

	# 切换精灵图
	var sprite = $Sprite2D
	if sprite_frames.has(anim_name):
		sprite.texture = sprite_frames[anim_name]

	# 如果有AnimationPlayer，也通知它（用于特效等）
	if has_node("AnimationPlayer"):
		var ap = $AnimationPlayer
		if ap.has_animation(anim_name):
			ap.play(anim_name)


# 受伤接口（供外部调用）
func hurt(damage: int = 0):
	if is_dead:
		return
	is_hurt = true
	_play_anim(ANIM_HURT)
	await get_tree().create_timer(0.5).timeout
	is_hurt = false
	_play_anim(ANIM_IDLE)


# 死亡接口（供外部调用）
func die():
	if is_dead:
		return
	is_dead = true
	_play_anim(ANIM_DEATH)
	await get_tree().create_timer(1.5).timeout
	# 死亡后可以做重生逻辑
	print("玩家已死亡")
