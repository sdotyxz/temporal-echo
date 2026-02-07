extends Node

@export var player: CharacterBody2D

var timer: float = 0.0

# 存储轨迹点
var current_points: Array[Vector2] = []
var history_points: Array[Vector2] = []
const MAX_POINTS: int = 180  # 3秒 @ 60fps

# 3秒前的位置标记
var echo_marker: Node2D

func _ready():
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	# 创建3秒前位置的标记
	echo_marker = Node2D.new()
	echo_marker.name = "EchoMarker"
	add_child(echo_marker)
	
	# 设置节点绘制
	set_notify_transform(true)
	
	print("🧪 历史记录系统测试")
	print("📊 黄色 = 当前位置")
	print("📊 青色 = 3秒前的位置")

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	timer += delta
	
	# 圆周运动
	var angle = timer * 1.5
	var radius = 150.0
	var x = cos(angle) * radius
	var y = sin(angle) * radius
	
	# 设置玩家位置
	var new_pos = Vector2(400 + x, 300 + y)
	player.position = new_pos
	player.rotation = angle + PI / 2
	
	# 记录当前轨迹
	current_points.append(new_pos)
	if current_points.size() > MAX_POINTS:
		current_points.pop_front()
	
	# 显示3秒前的位置
	if timer > 3.0:
		if player.position_history.size() > 0:
			var old_pos = player.position_history[0].position
			history_points.append(old_pos)
			if history_points.size() > MAX_POINTS:
				history_points.pop_front()
			
			# 更新标记位置
			echo_marker.position = old_pos
	
	# 触发重绘
	queue_redraw()
	
	# 更新UI
	_update_ui()

func _draw():
	# 绘制当前轨迹（黄色）
	if current_points.size() >= 2:
		for i in range(current_points.size() - 1):
			draw_line(current_points[i], current_points[i + 1], Color.YELLOW, 3.0)
	
	# 绘制历史轨迹（青色）
	if history_points.size() >= 2:
		for i in range(history_points.size() - 1):
			draw_line(history_points[i], history_points[i + 1], Color.CYAN, 3.0)
	
	# 绘制当前位置标记（黄色方块）
	if player:
		draw_rect(Rect2(player.position - Vector2(8, 8), Vector2(16, 16)), Color.YELLOW, true)
		draw_rect(Rect2(player.position - Vector2(5, 5), Vector2(10, 10)), Color.WHITE, true)
	
	# 绘制3秒前位置标记（青色方块）
	if echo_marker and timer > 3.0:
		draw_rect(Rect2(echo_marker.position - Vector2(8, 8), Vector2(16, 16)), Color.CYAN, true)
		draw_rect(Rect2(echo_marker.position - Vector2(5, 5), Vector2(10, 10)), Color.WHITE, true)

func _update_ui():
	var info = get_node_or_null("../UI/TestInfo")
	if info:
		var has_history = timer > 3.0 and player.position_history.size() > 0
		if has_history:
			var dist = 0.0
			if player.position_history.size() > 0:
				dist = player.position.distance_to(player.position_history[0].position)
			info.text = "🧪 历史记录测试\n✅ 黄=现在 青=3秒前\n📏 距离: %.0f px" % dist
		else:
			info.text = "🧪 历史记录测试\n⏳ 记录中... %d/%d" % [current_points.size(), MAX_POINTS]
