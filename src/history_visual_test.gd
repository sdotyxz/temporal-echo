extends Node

@export var player: CharacterBody2D

var timer: float = 0.0
var phase: int = 0

var history_trail: Line2D
var current_trail: Line2D

func _ready():
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	# 创建轨迹线
	history_trail = Line2D.new()
	history_trail.width = 4
	history_trail.default_color = Color(0, 1, 1, 0.5)  # 青色半透明
	history_trail.name = "HistoryTrail"
	get_parent().add_child(history_trail)
	
	current_trail = Line2D.new()
	current_trail.width = 4
	current_trail.default_color = Color(1, 1, 0, 0.8)  # 黄色
	current_trail.name = "CurrentTrail"
	get_parent().add_child(current_trail)
	
	print("🧪 历史记录系统测试")
	print("📊 青色线 = 3秒前的位置")
	print("📊 黄色线 = 当前位置")

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
	player.position = Vector2(400 + x, 300 + y)
	player.rotation = angle + PI / 2
	
	# 记录当前轨迹
	current_trail.add_point(player.position)
	if current_trail.get_point_count() > 180:
		current_trail.remove_point(0)
	
	# 显示历史轨迹（延迟3秒）
	if timer > 3.0:
		if player.position_history.size() > 0:
			var old_pos = player.position_history[0].position
			history_trail.add_point(old_pos)
			if history_trail.get_point_count() > 180:
				history_trail.remove_point(0)
	
	# 更新UI
	_update_ui()

func _update_ui():
	var info = get_node_or_null("../UI/TestInfo")
	if info:
		var has_history = timer > 3.0 and player.position_history.size() > 0
		if has_history:
			info.text = "🧪 历史记录测试\n✅ 青色=3秒前 黄色=现在"
		else:
			info.text = "🧪 历史记录测试\n⏳ 记录中..."
