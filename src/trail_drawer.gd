extends Node2D

@export var player: CharacterBody2D

var timer: float = 0.0

# 轨迹线节点
var current_trail: Line2D
var history_trail: Line2D

const MAX_POINTS: int = 180

func _ready():
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	# 创建当前轨迹线（黄色）
	current_trail = Line2D.new()
	current_trail.width = 4
	current_trail.default_color = Color(1, 1, 0, 0.8)  # 黄色
	current_trail.name = "CurrentTrail"
	add_child(current_trail)
	
	# 创建历史轨迹线（青色）
	history_trail = Line2D.new()
	history_trail.width = 4
	history_trail.default_color = Color(0, 1, 1, 0.8)  # 青色
	history_trail.name = "HistoryTrail"
	add_child(history_trail)
	
	print("📊 轨迹绘制系统启动")
	print("🟡 黄色 = 当前轨迹")
	print("🔵 青色 = 3秒前轨迹")

func _process(delta: float) -> void:
	if player == null:
		return
	
	timer += delta
	
	# 记录当前轨迹
	current_trail.add_point(player.global_position)
	if current_trail.get_point_count() > MAX_POINTS:
		current_trail.remove_point(0)
	
	# 显示历史轨迹（3秒后）
	if timer > 3.0:
		if player.position_history.size() > 0:
			var old_pos = player.position_history[0].position
			history_trail.add_point(old_pos)
			if history_trail.get_point_count() > MAX_POINTS:
				history_trail.remove_point(0)
	
	# 更新UI
	_update_ui()

func _update_ui():
	var info = get_node_or_null("../UI/TestInfo")
	if info:
		var has_history = timer > 3.0 and player.position_history.size() > 0
		if has_history:
			info.text = "🧪 轨迹绘制测试\n🟡 当前轨迹\n🔵 3秒前轨迹"
		else:
			info.text = "🧪 轨迹绘制测试\n⏳ 记录中..."
