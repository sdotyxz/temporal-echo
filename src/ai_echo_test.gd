extends Node

@export var player: CharacterBody2D
@export var test_duration: float = 8.0

var timer: float = 0.0
var move_timer: float = 0.0
var shoot_timer: float = 0.0
var current_dir: Vector2 = Vector2.ZERO

func _ready():
	print("🧪 回声生成测试启动")
	print("⏱️ 测试时长: ", test_duration, " 秒")
	print("🔫 2秒后自动射击，等待3秒后看回声生成")
	_set_random_direction()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	timer += delta
	move_timer += delta
	shoot_timer += delta
	
	# 移动控制
	if move_timer >= 0.8:
		move_timer = 0.0
		_set_random_direction()
	
	# 使用输入系统移动
	_apply_movement_input()
	
	# 2秒后自动射击
	if shoot_timer >= 2.0 and shoot_timer < 2.1:
		print("🔫 AI自动射击!")
		Input.action_press("fire")
	else:
		Input.action_release("fire")
	
	# 更新UI
	_update_ui()
	
	# 测试结束
	if timer >= test_duration:
		_end_test()

func _set_random_direction():
	var dirs = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, 
				Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
				Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()]
	current_dir = dirs[randi() % dirs.size()]

func _apply_movement_input():
	Input.action_press("move_right" if current_dir.x > 0 else "move_left")
	Input.action_press("move_down" if current_dir.y > 0 else "move_up")
	
	if current_dir.x > 0:
		Input.action_release("move_left")
	else:
		Input.action_release("move_right")
	
	if current_dir.y > 0:
		Input.action_release("move_up")
	else:
		Input.action_release("move_down")

func _update_ui():
	var info = get_node_or_null("../UI/TestInfo")
	if info:
		var status = ""
		if timer < 2.0:
			status = "⏳ 移动中... %.1fs" % (2.0 - timer)
		elif timer < 5.0:
			status = "🔫 已射击! 等待回声... %.1fs" % (5.0 - timer)
		else:
			status = "✅ 检查回声生成!"
		
		info.text = "🧪 回声生成测试\n" + status + "\n⏱️ 总时间: %.1fs" % timer

func _end_test():
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("move_down")
	Input.action_release("move_up")
	Input.action_release("fire")
	
	print("✅ 回声生成测试完成")
	queue_free()
