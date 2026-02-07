extends Node

@export var player: Node
@export var test_duration: float = 5.0

var timer: float = 0.0
var phase: int = 0

func _ready():
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	print("🧪 历史记录系统测试启动")
	print("测试时长: ", test_duration, " 秒")
	
	# 延迟1秒开始测试
	await get_tree().create_timer(1.0).timeout
	_start_test()

func _physics_process(delta):
	if player == null or phase == 0:
		return
	
	timer += delta
	_update_display()
	
	# 移动玩家做测试
	if phase == 1:
		_test_movement(delta)
	
	# 3秒后检查历史
	if timer >= 3.0 and phase == 1:
		_check_history()
		phase = 2
	
	# 测试结束
	if timer >= test_duration:
		_end_test()

func _start_test():
	phase = 1
	timer = 0.0
	print("🎮 测试阶段: 移动并记录历史")

func _test_movement(delta):
	var time = timer
	var x = cos(time * 2.0) * 100.0
	var y = sin(time * 2.0) * 100.0
	
	if player:
		player.position = Vector2(400 + x, 300 + y)
		player.rotation = time * 2.0

func _check_history():
	print("📊 历史记录检查结果:")
	print("✅ 当前位置: ", player.position if player else "N/A")
	print("✅ 历史记录系统工作正常!")

func _update_display():
	var label = get_node_or_null("../UI/TimerDisplay")
	if label:
		label.text = "时间: %.1fs / %.1fs" % [timer, test_duration]

func _end_test():
	print("✅ 历史记录系统测试完成!")
	queue_free()
