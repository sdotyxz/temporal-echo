class_name TrajectoryPreview
extends Node2D

const MAX_BOUNCES: int = 3
const RAY_LENGTH: float = 2000.0
const DASH_LENGTH: float = 20.0
const GAP_LENGTH: float = 40.0

@export var player: CharacterBody2D
@export var enabled: bool = true

@onready var bounce_markers: Node2D

var last_calc_time: float = 0.0
var path_points: PackedVector2Array = []
var is_preview_visible: bool = false

func _ready():
	# 创建反弹点标记容器
	bounce_markers = Node2D.new()
	bounce_markers.name = "BounceMarkers"
	add_child(bounce_markers)
	
	print("📊 轨迹预览系统启动")

func _process(_delta):
	if not enabled or player == null:
		if is_preview_visible:
			is_preview_visible = false
			path_points.clear()
			queue_redraw()
		return
	
	# 检测玩家是否处于瞄准状态
	if player.is_aiming:
		var start_time = Time.get_ticks_usec()
		_update_preview()
		last_calc_time = (Time.get_ticks_usec() - start_time) / 1000.0
		if not is_preview_visible:
			is_preview_visible = true
			queue_redraw()
	else:
		if is_preview_visible:
			is_preview_visible = false
			path_points.clear()
			queue_redraw()

func _update_preview():
	# 计算发射方向
	var aim_direction = (get_global_mouse_position() - player.global_position).normalized()
	
	# 计算预测路径
	path_points = _calculate_trajectory(player.global_position, aim_direction)
	
	# 触发重绘
	queue_redraw()

func _draw():
	if not is_preview_visible or path_points.size() < 2:
		return
	
	# 绘制虚线轨迹
	var drawing = true
	var current_dist = 0.0
	var segment_length = DASH_LENGTH if drawing else GAP_LENGTH
	
	for i in range(path_points.size() - 1):
		var seg_start = to_local(path_points[i])
		var seg_end = to_local(path_points[i + 1])
		var dir = (seg_end - seg_start).normalized()
		var seg_length = seg_start.distance_to(seg_end)
		var traveled = 0.0
		
		while traveled < seg_length:
			var remaining = seg_length - traveled
			var needed = segment_length - current_dist
			var step = min(needed, remaining)
			
			if drawing:
				var dash_start = seg_start + dir * traveled
				var dash_end = seg_start + dir * (traveled + step)
				draw_line(dash_start, dash_end, Color(1, 1, 1, 0.8), 3.0, true)
			
			traveled += step
			current_dist += step
			
			if current_dist >= segment_length - 0.001:
				drawing = !drawing
				current_dist = 0.0
				segment_length = DASH_LENGTH if drawing else GAP_LENGTH

func _calculate_trajectory(start_pos: Vector2, direction: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = []
	var current_pos = start_pos
	var current_dir = direction
	var bounce_count = 0
	
	points.append(current_pos)
	
	while bounce_count <= MAX_BOUNCES:
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			current_pos,
			current_pos + current_dir * RAY_LENGTH
		)
		query.collision_mask = 4
		
		var result = space_state.intersect_ray(query)
		
		if result:
			points.append(result.position)
			current_dir = current_dir.bounce(result.normal)
			current_pos = result.position + result.normal * 2.0
			bounce_count += 1
		else:
			points.append(current_pos + current_dir * RAY_LENGTH)
			break
	
	return points

func get_last_calc_time_ms() -> float:
	return last_calc_time
