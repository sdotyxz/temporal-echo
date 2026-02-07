extends Node

@export var player: CharacterBody2D
@export var test_duration: float = 10.0

var timer: float = 0.0
var move_timer: float = 0.0
var current_dir: Vector2 = Vector2.ZERO

func _ready():
	print("🤖 AI玩家测试启动")
	print("⏱️ 测试时长: ", test_duration, " 秒")
	_set_random_direction()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	timer += delta
	move_timer += delta
	
	# 每0.8秒改变方向
	if move_timer >= 0.8:
		move_timer = 0.0
		_set_random_direction()
	
	# 使用输入系统移动（模拟WASD）
	Input.action_press("move_right" if current_dir.x > 0 else "move_left")
	Input.action_press("move_down" if current_dir.y > 0 else "move_up")
	
	# 清除相反方向的输入
	if current_dir.x > 0:
		Input.action_release("move_left")
	else:
		Input.action_release("move_right")
	
	if current_dir.y > 0:
		Input.action_release("move_up")
	else:
		Input.action_release("move_down")
	
	# 测试结束
	if timer >= test_duration:
		_end_test()

func _set_random_direction():
	var dirs = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, 
				Vector2(1,1).normalized(), Vector2(-1,1).normalized(),
				Vector2(1,-1).normalized(), Vector2(-1,-1).normalized()]
	current_dir = dirs[randi() % dirs.size()]

func _end_test():
	# 释放所有输入
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("move_down")
	Input.action_release("move_up")
	
	print("✅ AI玩家测试完成")
	queue_free()
