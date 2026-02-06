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

func _physics_process(delta: float) -> void:
	# 获取移动输入
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 设置速度
	velocity = direction * SPEED
	
	# 移动
	move_and_slide()
	
	# 面向鼠标
	_aim_at_mouse()
	
	# 记录历史
	_record_history()

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
