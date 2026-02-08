extends Node

@export var player: CharacterBody2D
@export var test_duration: float = 15.0

var timer: float = 0.0
var move_timer: float = 0.0
var shoot_timer: float = 0.0
var aim_timer: float = 0.0
var current_dir: Vector2 = Vector2.ZERO
var is_aiming: bool = false
var aim_target: Vector2 = Vector2.ZERO

func _ready():
	print("🧪 AI玩家测试启动")
	print("⏱️ 测试时长: ", test_duration, " 秒")
	print("🎯 AI将展示瞄准状态 + 轨迹线 + 射击")
	_set_random_direction()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	timer += delta
	move_timer += delta
	
	# 移动控制
	if not is_aiming and move_timer >= 1.2:
		move_timer = 0.0
		_set_random_direction()
	
	# 使用输入系统移动
	if not is_aiming:
		_apply_movement_input()
	else:
		# 瞄准时不移动
		Input.action_release("move_right")
		Input.action_release("move_left")
		Input.action_release("move_up")
		Input.action_release("move_down")
	
	# AI自动瞄准+射击流程
	if not is_aiming and shoot_timer <= 0:
		# 开始新的瞄准射击循环
		_start_aim_sequence()
	elif is_aiming:
		aim_timer += delta
		# 更新玩家朝向瞄准目标
		var direction = (aim_target - player.global_position).normalized()
		player.rotation = direction.angle()
		
		# 瞄准1.5秒后射击
		if aim_timer >= 1.5:
			_perform_shoot()
			is_aiming = false
			player.is_aiming = false
			Input.action_release("aim")
			shoot_timer = 2.0  # 2秒后再下一次射击
	else:
		shoot_timer -= delta
	
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

func _start_aim_sequence():
	print("🎯 AI开始瞄准...")
	is_aiming = true
	aim_timer = 0.0
	
	# 获取Boss位置作为瞄准目标
	var bosses = get_tree().get_nodes_in_group("boss")
	if bosses.size() > 0:
		aim_target = bosses[0].global_position
		print("🎯 瞄准Boss位置: ", aim_target)
	else:
		# 如果没有Boss，使用默认目标
		aim_target = Vector2(400, 150)
	
	# 设置玩家瞄准状态
	player.is_aiming = true
	Input.action_press("aim")

func _perform_shoot():
	print("🔫 AI射击!")
	
	# 第一次射击
	Input.action_press("fire")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("fire")
	
	# 短暂延迟后第二次射击（尝试双重命中）
	await get_tree().create_timer(0.08).timeout  # 总共0.08秒间隔，在0.1秒窗口内
	print("🔫 AI双重射击!")
	Input.action_press("fire")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("fire")
	
	print("⚡ 双重命中尝试完成")

func _update_ui():
	var info = get_node_or_null("../UI/TestInfo")
	if info:
		var status = ""
		var bullets = get_tree().get_nodes_in_group("bullets")
		
		if is_aiming:
			status = "🎯 瞄准中... %.1fs" % (0.8 - aim_timer)
		elif timer < 3.0:
			status = "⏳ 移动中..."
		else:
			status = "🔄 观察反弹 | 活动子弹: " + str(bullets.size())
		
		info.text = "🤖 AI玩家测试 | 时间: %.1f/%ds\n%s\n🎨 白→黄→橙→红 = 反弹次数" % [timer, test_duration, status]

func _end_test():
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("move_up")
	Input.action_release("move_down")
	Input.action_release("fire")
	Input.action_release("aim")
	if player != null:
		player.is_aiming = false
	
	print("✅ AI测试完成")
	queue_free()
