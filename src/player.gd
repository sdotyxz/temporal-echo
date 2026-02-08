class_name Player
extends CharacterBody2D

const SPEED: float = 200.0
const HISTORY_SIZE: int = 180  # 3秒 @ 60fps
const MAX_HP: int = 3

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar_bg: ColorRect
@onready var health_bar_fg: ColorRect

# 历史帧数据结构
class HistoryFrame:
	var position: Vector2
	var aim_direction: Vector2
	var did_shoot: bool
	
	func _init(pos: Vector2, aim: Vector2, shoot: bool = false):
		position = pos
		aim_direction = aim
		did_shoot = shoot

# 历史记录数组
var position_history: Array[HistoryFrame] = []

# 瞄准状态
var is_aiming: bool = false

# 玩家生命值
var hp: int = MAX_HP
var is_dead: bool = false
var invulnerable: bool = false

func _ready():
	print("🎯 玩家准备就绪")
	print("📝 历史记录系统初始化 (", HISTORY_SIZE, " 帧)")
	print("❤️ 玩家 HP: ", hp, "/", MAX_HP)
	
	# 创建玩家血条
	_create_health_bar()

func _create_health_bar():
	# 创建 CanvasLayer 作为UI容器
	var canvas = CanvasLayer.new()
	canvas.name = "PlayerHealthUI"
	add_child(canvas)
	
	# 血条背景
	health_bar_bg = ColorRect.new()
	health_bar_bg.name = "HealthBarBg"
	health_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	health_bar_bg.size = Vector2(120, 12)
	health_bar_bg.position = Vector2(20, 560)  # 左下角
	canvas.add_child(health_bar_bg)
	
	# 血条前景
	health_bar_fg = ColorRect.new()
	health_bar_fg.name = "HealthBarFg"
	health_bar_fg.color = Color(0.2, 0.8, 0.2, 1.0)  # 绿色
	health_bar_fg.size = Vector2(120, 12)
	health_bar_fg.position = Vector2(20, 560)
	canvas.add_child(health_bar_fg)
	
	# 血条标签
	var label = Label.new()
	label.name = "HealthLabel"
	label.text = "HP: 3/3"
	label.position = Vector2(150, 558)
	label.add_theme_font_size_override("font_size", 14)
	canvas.add_child(label)

var test_mode: bool = false
var test_target_position: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if test_mode:
		# 测试模式：不处理输入，只记录历史
		_aim_at_mouse()
		_record_history()
		return
	
	# 获取移动输入
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 设置速度
	velocity = direction * SPEED
	
	# 移动
	move_and_slide()
	
	# 面向鼠标
	_aim_at_mouse()
	
	# 处理瞄准状态
	if Input.is_action_just_pressed("aim"):
		is_aiming = true
		print("🎯 进入瞄准状态")
	
	if Input.is_action_just_released("aim"):
		is_aiming = false
		print("🎯 退出瞄准状态")
	
	# 记录历史（带射击状态）
	var did_shoot := Input.is_action_just_pressed("fire")
	_record_history_with_shoot(did_shoot)
	
	# 处理射击
	if did_shoot:
		_shoot()
		# 射击后退出瞄准状态
		if is_aiming:
			is_aiming = false
			print("🎯 射击后退出瞄准状态")
	
	# 检查回声生成
	_process_echo_spawn()

func _aim_at_mouse() -> void:
	var mouse_pos := get_global_mouse_position()
	var angle := (mouse_pos - global_position).angle()
	rotation = angle

# 记录历史帧
func _record_history() -> void:
	var aim_dir := Vector2.RIGHT.rotated(rotation)
	var frame := HistoryFrame.new(position, aim_dir, false)
	position_history.append(frame)
	
	# 循环缓冲区：超过最大大小时移除最旧的帧
	if position_history.size() > HISTORY_SIZE:
		position_history.pop_front()

# 获取3秒前的历史帧
func get_frame_from_3s_ago() -> HistoryFrame:
	if position_history.size() < HISTORY_SIZE:
		# 历史不足3秒，返回第一帧
		return position_history[0] if position_history.size() > 0 else HistoryFrame.new(Vector2.ZERO, Vector2.RIGHT)
	
	# 返回3秒前的帧（数组最前面）
	return position_history[0]

# 记录历史（带射击状态）
var shoot_history: Array[bool] = []

func _record_history_with_shoot(did_shoot: bool) -> void:
	var aim_dir := Vector2.RIGHT.rotated(rotation)
	var frame := HistoryFrame.new(position, aim_dir, did_shoot)
	position_history.append(frame)
	shoot_history.append(did_shoot)
	
	# 循环缓冲区
	if position_history.size() > HISTORY_SIZE:
		position_history.pop_front()
		shoot_history.pop_front()

# 发射子弹
func _shoot() -> void:
	print("🔫 玩家发射!")
	var bullet_scene = load("res://scenes/bullet.tscn")
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.velocity = Vector2.RIGHT.rotated(rotation) * bullet.SPEED
	bullet.is_echo = false
	get_tree().current_scene.add_child(bullet)

# 处理回声生成
var echo_spawn_index: int = 0

func _process_echo_spawn() -> void:
	# 检查3秒前的射击记录
	if shoot_history.size() >= HISTORY_SIZE:
		if shoot_history[0] and echo_spawn_index < position_history.size():
			_spawn_echo()
			# 不要立即标记为false，让AI有机会读取
			# 使用一个单独的数组来跟踪已处理的回声
			_process_echo_at_index(0)

# 获取即将生成的回声信息（供AI查询）
func get_pending_echo_info() -> Dictionary:
	if shoot_history.size() >= HISTORY_SIZE and shoot_history[0]:
		var old_frame = position_history[0]
		return {
			"will_spawn": true,
			"position": old_frame.position,
			"aim_direction": old_frame.aim_direction
		}
	return {"will_spawn": false}

var processed_echo_indices: Array[int] = []

func _process_echo_at_index(index: int) -> void:
	if index not in processed_echo_indices:
		processed_echo_indices.append(index)
		# 延迟标记为已处理，给AI时间读取
		_mark_processed_delayed(index)

func _mark_processed_delayed(index: int) -> void:
	await get_tree().create_timer(0.1).timeout
	if index < shoot_history.size():
		shoot_history[index] = false

func _spawn_echo() -> void:
	print("👻 生成回声!")
	var old_frame = position_history[0]
	
	var echo_scene = load("res://scenes/echo.tscn")
	var echo = echo_scene.instantiate()
	echo.spawn_position = old_frame.position
	echo.aim_direction = old_frame.aim_direction
	
	get_tree().current_scene.add_child(echo)

func take_damage(amount: int) -> void:
	if is_dead or invulnerable:
		return
	
	hp -= amount
	print("💔 玩家受到 ", amount, " 点伤害! HP: ", hp, "/", MAX_HP)
	
	# 更新血条
	_update_health_bar()
	
	# 视觉反馈 - 红色闪烁
	_flash_red()
	
	# 无敌时间
	invulnerable = true
	await get_tree().create_timer(1.0).timeout
	invulnerable = false
	
	if hp <= 0:
		_die()

func _update_health_bar():
	if health_bar_fg:
		var health_percent = float(hp) / MAX_HP
		health_bar_fg.size.x = 120 * health_percent
		
		# 根据血量改变颜色
		if health_percent > 0.6:
			health_bar_fg.color = Color(0.2, 0.8, 0.2, 1.0)  # 绿色
		elif health_percent > 0.3:
			health_bar_fg.color = Color(0.9, 0.9, 0.2, 1.0)  # 黄色
		else:
			health_bar_fg.color = Color(0.9, 0.2, 0.2, 1.0)  # 红色
	
	# 更新标签
	var canvas = get_node_or_null("PlayerHealthUI")
	if canvas:
		var label = canvas.get_node_or_null("HealthLabel")
		if label:
			label.text = "HP: %d/%d" % [hp, MAX_HP]

func _flash_red():
	sprite.modulate = Color(1, 0.3, 0.3, 1)
	await get_tree().create_timer(0.2).timeout
	if sprite:
		sprite.modulate = Color(1, 1, 1, 1)

func _die():
	is_dead = true
	print("☠️ 玩家死亡!")
	
	# 触发游戏结束
	var game_manager = get_node_or_null("/root/Game/GameManager")
	if game_manager:
		game_manager.trigger_game_over()
	else:
		print("⚠️ 未找到游戏管理器")
	# 可以在这里添加游戏结束逻辑
	# queue_free()

func get_hp() -> int:
	return hp

func get_max_hp() -> int:
	return MAX_HP
