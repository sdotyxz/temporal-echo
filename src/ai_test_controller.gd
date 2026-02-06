class_name AIPlayerController
extends Node

@export var player: CharacterBody2D
@export var move_duration: float = 2.0
@export var change_direction_interval: float = 0.5

var timer: float = 0.0
var direction_timer: float = 0.0
var current_direction: Vector2 = Vector2.ZERO
var test_phase: int = 0

func _ready():
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	print("🤖 AI测试控制器启动")
	print("测试阶段: 1.移动 2.瞄准 3.组合")
	
	# 开始测试
	_start_movement_test()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	timer += delta
	direction_timer += delta
	
	# 每0.5秒改变方向
	if direction_timer >= change_direction_interval:
		direction_timer = 0.0
		_change_direction()
	
	# 应用移动输入 (200 px/s)
	player.velocity = current_direction * 200.0
	player.move_and_slide()
	
	# 让玩家面向移动方向
	if current_direction != Vector2.ZERO:
		player.rotation = current_direction.angle()
	
	# 2秒后切换测试阶段
	if timer >= move_duration:
		_timer += delta
		if _timer >= 2.0:
			_timer = 0.0
			_next_test_phase()

var _timer: float = 0.0

func _change_direction():
	match test_phase:
		0: # 四方向测试
			var directions = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1,1).normalized(), Vector2(-1,1).normalized()]
			current_direction = directions[randi() % directions.size()]
		1: # 随机方向
			current_direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()

func _start_movement_test():
	test_phase = 0
	timer = 0.0
	print("🎮 测试阶段 1: 基础移动")

func _next_test_phase():
	test_phase += 1
	match test_phase:
		1:
			print("🎮 测试阶段 2: 随机移动")
		2:
			print("🎮 测试阶段 3: 停止测试")
			current_direction = Vector2.ZERO
		3:
			print("✅ AI测试完成")
			queue_free()
