extends Node

# AI 状态枚举
enum State { IDLE, MOVE, AIM }

@export var player: CharacterBody2D
@export var test_duration: float = 20.0

# 状态变量
var current_state: State = State.IDLE
var state_timer: float = 0.0
var game_timer: float = 0.0

# 移动相关
var move_direction: Vector2 = Vector2.ZERO
var last_shot_time: float = -10.0

# 统计（从文件读取）
var round_count: int = 0
var max_rounds: int = 5
var results: Array[String] = []
var _has_recorded: bool = false  # 防止重复记录

# 配置参数
const SAFE_DISTANCE: float = 400.0
const EMERGENCY_DISTANCE: float = 100.0  # 紧急逃离距离
const MIN_AIM_DISTANCE: float = 120.0  # 降低，让AI在逃离边缘也能射击
const SHOOT_COOLDOWN: float = 1.0
const AIM_DURATION: float = 0.3

# 智能移动采样配置
var sample_directions: Array[Vector2] = [
	Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
	Vector2(1, -1).normalized(), Vector2(1, 1).normalized(),
	Vector2(-1, -1).normalized(), Vector2(-1, 1).normalized()
]
const PREDICTION_TIME: float = 1.0

const SAVE_FILE: String = "user://ai_test_data.json"

func _ready():
	# 设置为ALWAYS模式，即使游戏暂停也能运行（用于检测游戏结束）
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 从文件加载之前的数据
	_load_data()
	
	if round_count == 0:
		print("🧪 AI 五局测试启动")
		print("  目标: 连续打5局")
	else:
		print("🧪 AI 测试继续 - 第 %d 局" % (round_count + 1))
		
	_transition_to(State.IDLE)

func _load_data():
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			var json = JSON.new()
			var error = json.parse(file.get_as_text())
			if error == OK:
				var data = json.get_data()
				round_count = data.get("round_count", 0)
				var loaded_results = data.get("results", [])
				results.clear()
				for r in loaded_results:
					results.append(r)
				print("📂 加载之前数据: %d局完成" % round_count)

func _save_data():
	var data = {
		"round_count": round_count,
		"results": results
	}
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	game_timer += delta
	state_timer += delta
	
	# 检查游戏是否结束，自动重启
	if _check_game_over():
		return
	
	var boss = _get_boss()
	if boss == null:
		return
	
	_update_state_machine(delta, boss)

func _update_state_machine(delta: float, boss: Node2D):
	match current_state:
		State.IDLE:
			_update_idle(delta, boss)
		State.MOVE:
			_update_move(delta, boss)
		State.AIM:
			_update_aim(delta, boss)

# ========== IDLE 状态 ==========
func _update_idle(delta: float, boss: Node2D):
	_stop_movement()
	
	var dist = player.global_position.distance_to(boss.global_position)
	
	if dist < SAFE_DISTANCE:
		move_direction = _pick_best_direction(boss)
		_transition_to(State.MOVE)
	elif _can_shoot(dist):
		_transition_to(State.AIM)
	else:
		if state_timer > 0.5:
			move_direction = _pick_best_direction(boss)
			_transition_to(State.MOVE)

# ========== MOVE 状态 ==========
func _update_move(delta: float, boss: Node2D):
	var dist = player.global_position.distance_to(boss.global_position)
	
	# 检查射击机会（在逃离前）
	if _can_shoot(dist) and state_timer > 0.3:
		print("🤖 MOVE → AIM (机会射击) 距离: %.0fpx" % dist)
		_transition_to(State.AIM)
		return
	
	# 紧急逃离模式：Boss太近时直接逃离
	if dist < EMERGENCY_DISTANCE:
		var escape_dir = (player.global_position - boss.global_position).normalized()
		move_direction = escape_dir
		print("🚨 紧急逃离! 距离: %.0fpx" % dist)
		_apply_direction(move_direction)
	elif dist < SAFE_DISTANCE:
		# 安全距离内：正常评分选择方向
		if int(state_timer * 10) % 5 == 0:  # 每0.5秒重新评估
			move_direction = _pick_best_direction(boss)
		_apply_direction(move_direction)
	else:
		# 安全距离外：正常巡逻
		_apply_direction(move_direction)

# ========== AIM 状态 ==========
func _update_aim(delta: float, boss: Node2D):
	_stop_movement()
	
	var aim_dir = (boss.global_position - player.global_position).normalized()
	player.rotation = aim_dir.angle()
	
	if state_timer >= AIM_DURATION:
		_shoot()
		last_shot_time = game_timer
		_transition_to(State.IDLE)

# ========== 智能方向选择 ==========
func _pick_best_direction(boss: Node2D) -> Vector2:
	var best_dir = Vector2.ZERO
	var best_score = -999.0
	
	for dir in sample_directions:
		var score = _evaluate_direction(dir, boss)
		if score > best_score:
			best_score = score
			best_dir = dir
	
	return best_dir

func _evaluate_direction(dir: Vector2, boss: Node2D) -> float:
	var player_pos = player.global_position
	var boss_pos = boss.global_position
	
	var future_pos = player_pos + dir * player.SPEED * PREDICTION_TIME
	
	# Boss距离分
	var future_dist = future_pos.distance_to(boss_pos)
	var dist_score = clamp((future_dist - SAFE_DISTANCE) / SAFE_DISTANCE, 0.0, 1.0)
	if future_dist < SAFE_DISTANCE:
		dist_score = future_dist / SAFE_DISTANCE * 0.5
	
	# 墙壁距离分
	var wall_dist = min(
		min(future_pos.x, 800 - future_pos.x),
		min(future_pos.y, 600 - future_pos.y)
	)
	var wall_score = clamp(wall_dist / 150.0, 0.0, 1.0)
	
	# 中心倾向分
	var center = Vector2(400, 300)
	var to_center = (center - future_pos).normalized()
	var center_score = (dir.dot(to_center) + 1.0) / 2.0
	
	# 切线bonus
	var to_player = (player_pos - boss_pos).normalized()
	var tangent_score = 1.0 - abs(dir.dot(to_player))
	
	var total = dist_score * 0.4 + wall_score * 0.3 + center_score * 0.2 + tangent_score * 0.1
	return total

# ========== 状态转换 ==========
func _transition_to(new_state: State):
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		State.IDLE:
			player.is_aiming = false
			Input.action_release("aim")
		State.MOVE:
			player.is_aiming = false
			Input.action_release("aim")
		State.AIM:
			player.is_aiming = true
			Input.action_press("aim")

# ========== 辅助函数 ==========
func _get_boss() -> Node2D:
	var bosses = get_tree().get_nodes_in_group("boss")
	return bosses[0] if bosses.size() > 0 else null

func _check_game_over() -> bool:
	if _has_recorded:
		return false
	
	# 通过相对路径查找GameManager
	var game_manager = get_node_or_null("../GameManager")
	if game_manager == null:
		# 尝试根节点路径
		var root = get_tree().root
		var game = root.get_node_or_null("Game")
		if game:
			game_manager = game.get_node_or_null("GameManager")
	
	if game_manager == null:
		return false
	
	# 检查游戏状态 (0=PLAYING, 1=VICTORY, 2=GAME_OVER)
	var gm_state = game_manager.state
	if gm_state == 1:  # VICTORY
		_has_recorded = true
		print("🎉 第 %d 局: 胜利!" % (round_count + 1))
		_record_result("VICTORY")
		_restart_game()
		return true
	elif gm_state == 2:  # GAME_OVER
		_has_recorded = true
		print("💀 第 %d 局: 失败" % (round_count + 1))
		_record_result("DEFEAT")
		_restart_game()
		return true
	
	return false

func _record_result(result: String):
	results.append(result)
	round_count += 1
	_save_data()
	print("📊 当前战绩: %s" % ", ".join(results))

func _restart_game():
	if round_count >= max_rounds:
		print("🎮 五局测试完成!")
		print("📈 最终战绩: %d胜 %d负" % [results.count("VICTORY"), results.count("DEFEAT")])
		print("📊 详细: %s" % ", ".join(results))
		# 清理保存文件
		if FileAccess.file_exists(SAVE_FILE):
			DirAccess.remove_absolute(SAVE_FILE)
		
		# 退出游戏
		await get_tree().create_timer(0.5).timeout
		get_tree().quit()
		return
	
	print("🔄 即将开始第 %d 局..." % (round_count + 1))
	await get_tree().create_timer(0.5).timeout
	
	# 直接重载场景（不通过按键）
	get_tree().paused = false
	get_tree().reload_current_scene()

func _can_shoot(dist: float) -> bool:
	return dist >= MIN_AIM_DISTANCE and (game_timer - last_shot_time) >= SHOOT_COOLDOWN

func _apply_direction(dir: Vector2):
	if dir.x > 0.1:
		Input.action_press("move_right")
		Input.action_release("move_left")
	elif dir.x < -0.1:
		Input.action_press("move_left")
		Input.action_release("move_right")
	else:
		Input.action_release("move_right")
		Input.action_release("move_left")
	
	if dir.y > 0.1:
		Input.action_press("move_down")
		Input.action_release("move_up")
	elif dir.y < -0.1:
		Input.action_press("move_up")
		Input.action_release("move_down")
	else:
		Input.action_release("move_up")
		Input.action_release("move_down")

func _stop_movement():
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("move_up")
	Input.action_release("move_down")

func _shoot():
	Input.action_press("fire")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("fire")
