class_name Player
extends CharacterBody2D

const SPEED: float = 200.0
const HISTORY_SIZE: int = 180  # 3秒 @ 60fps

@onready var sprite: Sprite2D = $Sprite2D

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

func _ready():
	print("🎯 玩家准备就绪")
	print("📝 历史记录系统初始化 (", HISTORY_SIZE, " 帧)")

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
	
	# 限制在屏幕内
	position.x = clamp(position.x, 50, 750)
	position.y = clamp(position.y, 50, 550)
	
	# 面向鼠标
	_aim_at_mouse()
	
	# 记录历史（带射击状态）
	var did_shoot := Input.is_action_just_pressed("fire")
	_record_history_with_shoot(did_shoot)
	
	# 处理射击
	if did_shoot:
		_shoot()
	
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
			shoot_history[0] = false  # 标记为已处理

func _spawn_echo() -> void:
	print("👻 生成回声!")
	var old_frame = position_history[0]
	
	var echo_scene = load("res://scenes/echo.tscn")
	var echo = echo_scene.instantiate()
	echo.spawn_position = old_frame.position
	echo.aim_direction = old_frame.aim_direction
	
	get_tree().current_scene.add_child(echo)
