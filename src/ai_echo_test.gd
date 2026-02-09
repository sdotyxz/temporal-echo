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
var _fire_pressed: bool = false  # 跟踪射击按键状态
var _fire_press_frame: int = 0   # 按下时的帧数
var _shooting: bool = false      # 是否正在射击（等待玩家完成）

# 统计（从文件读取）
var round_count: int = 0
var max_rounds: int = 5
var results: Array[String] = []
var _has_recorded: bool = false  # 防止重复记录

# 配置参数
const SAFE_DISTANCE: float = 400.0
const EMERGENCY_DISTANCE: float = 100.0  # 紧急逃离距离
const MIN_AIM_DISTANCE: float = 150.0  # 降低，让AI更容易射击
const SHOOT_COOLDOWN: float = 0.5  # 基础冷却时间
const AIM_DURATION: float = 0.2  # 基础瞄准时间

# 随机噪声配置
const DIRECTION_NOISE: float = 0.3  # 方向随机噪声 (0-1)
const COOLDOWN_VARIATION: float = 0.2  # 冷却时间变化 ±0.2秒
const AIM_VARIATION: float = 0.1  # 瞄准时间变化 ±0.1秒
const SAFE_DIST_VARIATION: float = 50.0  # 安全距离变化 ±50px

# 随机种子（每局不同）
var rng: RandomNumberGenerator

# 智能移动采样配置
var sample_directions: Array[Vector2] = [
	Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
	Vector2(1, -1).normalized(), Vector2(1, 1).normalized(),
	Vector2(-1, -1).normalized(), Vector2(-1, 1).normalized()
]
const PREDICTION_TIME: float = 1.0

const SAVE_FILE: String = "user://ai_test_data.json"

func _ready():
	# 初始化随机数生成器（每局不同）
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# 检查启动参数，如果没有--ai-test参数则禁用AI
	var args = OS.get_cmdline_args()
	if not args.has("--ai-test"):
		print("🎮 人工模式 - 使用键盘/鼠标控制 (添加 --ai-test 启用AI)")
		set_process(false)
		set_physics_process(false)
		return
	
	print("🤖 AI测试模式已启动 (使用 --ai-test 参数)")
	print("🎲 随机噪声已启用: 方向=%.1f, 冷却±%.1fs, 瞄准±%.1fs" % [DIRECTION_NOISE, COOLDOWN_VARIATION, AIM_VARIATION])
	
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
				results = data.get("results", [])
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
	# 处理射击按键释放（延迟一帧，让玩家能检测到is_action_just_pressed）
	if _fire_pressed and Engine.get_process_frames() > _fire_press_frame + 1:
		Input.action_release("fire")
		_fire_pressed = false
	
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
	_release_aim()
	
	var dist = player.global_position.distance_to(boss.global_position)
	
	print("🤖 IDLE状态 | 距离Boss: %.0fpx | 计时: %.1f" % [dist, state_timer])
	
	# 优先检查射击机会
	if _can_shoot(dist):
		print("🤖 IDLE → AIM (可以射击)")
		_transition_to(State.AIM)
	elif dist < SAFE_DISTANCE:
		print("🤖 IDLE → MOVE (逃离Boss)")
		move_direction = _pick_best_direction(boss)
		_transition_to(State.MOVE)
	else:
		if state_timer > 0.5:
			print("🤖 IDLE → MOVE (巡逻)")
			move_direction = _pick_best_direction(boss)
			_transition_to(State.MOVE)

# ========== MOVE 状态 ==========
func _update_move(delta: float, boss: Node2D):
	var dist = player.global_position.distance_to(boss.global_position)
	
	print("🤖 MOVE状态 | 距离Boss: %.0fpx | 计时: %.2f" % [dist, state_timer])
	
	# 检查射击机会（优先于移动）
	if _can_shoot(dist):
		print("🤖 MOVE → AIM (可以射击) 距离: %.0fpx" % dist)
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
			print("🤖 重新评估方向: %s" % move_direction)
		_apply_direction(move_direction)
	else:
		# 安全距离外：正常巡逻
		_apply_direction(move_direction)

# ========== AIM 状态 ==========
func _update_aim(delta: float, boss: Node2D):
	_stop_movement()
	
	# 如果正在等待玩家完成射击，保持aim并返回
	if _shooting:
		Input.action_press("aim")
		# 给玩家一帧时间后，完成射击流程
		if Engine.get_process_frames() > _fire_press_frame + 1:
			_shooting = false
			_release_aim()
			_transition_to(State.IDLE)
		return
	
	# 持续按下瞄准键
	Input.action_press("aim")
	
	# 持续朝向Boss
	var aim_dir = (boss.global_position - player.global_position).normalized()
	player.rotation = aim_dir.angle()
	
	# 添加随机瞄准时间
	var actual_aim_duration = AIM_DURATION + rng.randf_range(-AIM_VARIATION, AIM_VARIATION)
	
	print("🤖 AIM状态 | 计时: %.2f/%.2f" % [state_timer, actual_aim_duration])
	
	# 瞄准时间到，射击
	if state_timer >= actual_aim_duration:
		print("🤖 AIM时间到，射击!")
		_shoot()
		last_shot_time = game_timer
		_shooting = true  # 标记正在射击，等待玩家完成

# ========== 智能方向选择（带噪声）==========
func _pick_best_direction(boss: Node2D) -> Vector2:
	var best_dir = Vector2.ZERO
	var best_score = -999.0
	
	for dir in sample_directions:
		var score = _evaluate_direction(dir, boss)
		# 添加随机噪声
		score += rng.randf() * DIRECTION_NOISE
		if score > best_score:
			best_score = score
			best_dir = dir
	
	# 额外添加方向扰动
	var angle_noise = rng.randf_range(-PI/8, PI/8)  # ±22.5度
	best_dir = best_dir.rotated(angle_noise)
	
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
	var old_state = current_state
	current_state = new_state
	state_timer = 0.0
	
	print("🤖 AI状态: %s → %s" % [old_state, new_state])
	
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
	# 添加随机冷却时间变化
	var actual_cooldown = SHOOT_COOLDOWN + rng.randf_range(-COOLDOWN_VARIATION, COOLDOWN_VARIATION)
	var actual_min_dist = MIN_AIM_DISTANCE + rng.randf_range(-SAFE_DIST_VARIATION, SAFE_DIST_VARIATION)
	
	var can = dist >= actual_min_dist and (game_timer - last_shot_time) >= actual_cooldown
	if not can:
		print("🤖 _can_shoot=false | dist=%.0f (need>=%.0f) | cooldown=%.1f/%.1f" % [dist, actual_min_dist, game_timer - last_shot_time, actual_cooldown])
	return can

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

func _release_aim():
	Input.action_release("aim")

func _shoot():
	var current_frame = Engine.get_process_frames()
	print("🔫 AI射击! (Input方式) 当前帧: %d" % current_frame)
	# 使用Input模拟玩家按键，延迟一帧释放
	Input.action_press("fire")
	_fire_pressed = true
	_fire_press_frame = current_frame
	print("🔫 fire已按下，将在帧 %d 后释放" % (_fire_press_frame + 1))
