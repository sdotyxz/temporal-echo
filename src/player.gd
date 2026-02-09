class_name Player
extends CharacterBody2D

const SPEED: float = 200.0
const HISTORY_SIZE: int = 180  # 3秒 @ 60fps
const MAX_HP: int = 3

# 玩家状态枚举
enum State { IDLE, MOVE, AIM, SHOOT }

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar_bg: ColorRect
@onready var health_bar_fg: ColorRect

# 状态变量
var current_state: State = State.IDLE
var state_timer: float = 0.0

# 历史帧数据结构
class HistoryFrame:
	var position: Vector2
	var aim_direction: Vector2
	var did_shoot: bool
	
	func _init(pos: Vector2, aim: Vector2, shoot: bool = false):
		position = pos
		aim_direction = aim
		did_shoot = shoot

# 历史记录数组
var position_history: Array[HistoryFrame] = []

# 瞄准状态
var is_aiming: bool = false

# 玩家生命值
var hp: int = MAX_HP
var is_dead: bool = false
var invulnerable: bool = false

func _ready():
	print("🎯 玩家准备就绪")
	print("📝 历史记录系统初始化 (", HISTORY_SIZE, " 帧)")
	print("❤️ 玩家 HP: ", hp, "/", MAX_HP)
	
	# 添加发光效果
	_add_glow_effect()
	
	# 创建玩家血条
	_create_health_bar()

func _add_glow_effect():
	# 为精灵添加发光材质
	if sprite:
		var shader = Shader.new()
		shader.code = """
		shader_type canvas_item;
		
		void fragment() {
			vec4 color = texture(TEXTURE, UV);
			// 添加边缘发光
			float glow = smoothstep(0.3, 0.5, color.a) * 0.5;
			COLOR = vec4(color.rgb + vec3(0.2, 0.5, 0.8) * glow, color.a);
		}
		"""
		var material = ShaderMaterial.new()
		material.shader = shader
		sprite.material = material
		print("✨ 玩家发光效果已添加")

func _create_health_bar():
	# 创建 CanvasLayer 作为UI容器
	var canvas = CanvasLayer.new()
	canvas.name = "PlayerHealthUI"
	add_child(canvas)
	
	# 血条背景
	health_bar_bg = ColorRect.new()
	health_bar_bg.name = "HealthBarBg"
	health_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	health_bar_bg.size = Vector2(120, 12)
	health_bar_bg.position = Vector2(20, 560)  # 左下角
	canvas.add_child(health_bar_bg)
	
	# 血条前景
	health_bar_fg = ColorRect.new()
	health_bar_fg.name = "HealthBarFg"
	health_bar_fg.color = Color(0.2, 0.8, 0.2, 1.0)  # 绿色
	health_bar_fg.size = Vector2(120, 12)
	health_bar_fg.position = Vector2(20, 560)
	canvas.add_child(health_bar_fg)
	
	# 血条标签
	var label = Label.new()
	label.name = "HealthLabel"
	label.text = "HP: 3/3"
	label.position = Vector2(150, 558)
	label.add_theme_font_size_override("font_size", 14)
	canvas.add_child(label)

var test_mode: bool = false
var test_target_position: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if test_mode:
		_aim_at_mouse()
		_record_history()
		return
	
	state_timer += delta
	
	# 状态机更新
	_update_state_machine(delta)
	
	# 检查回声生成
	_process_echo_spawn()

func _update_state_machine(delta: float):
	match current_state:
		State.IDLE:
			_update_idle(delta)
		State.MOVE:
			_update_move(delta)
		State.AIM:
			_update_aim(delta)
		State.SHOOT:
			_update_shoot(delta)

# ========== IDLE 状态 ==========
func _update_idle(delta: float):
	# 面向鼠标
	_aim_at_mouse()
	
	# 检查移动输入
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction.length() > 0.1:
		# 开始移动
		_transition_to(State.MOVE)
		return
	
	# 检查瞄准输入
	if Input.is_action_pressed("aim"):
		_transition_to(State.AIM)
		return
	
	# 记录历史
	_record_history_with_shoot(false)

# ========== MOVE 状态 ==========
func _update_move(delta: float):
	# 面向鼠标
	_aim_at_mouse()
	
	# 获取移动输入
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 设置速度
	velocity = direction * SPEED
	move_and_slide()
	
	# 停止移动时回到IDLE
	if direction.length() < 0.1:
		_transition_to(State.IDLE)
		return
	
	# 移动时不能射击，但可以进入瞄准状态
	if Input.is_action_just_pressed("aim"):
		_transition_to(State.AIM)
		return
	
	# 记录历史
	_record_history_with_shoot(false)

# ========== AIM 状态 ==========
func _update_aim(delta: float):
	# 持续面向鼠标
	_aim_at_mouse()
	
	print("🎯 AIM状态 | fire按下: %s | just_pressed: %s" % [Input.is_action_pressed("fire"), Input.is_action_just_pressed("fire")])
	
	# 检查是否还在瞄准
	if not Input.is_action_pressed("aim"):
		# 退出瞄准，检查是否在移动
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction.length() > 0.1:
			_transition_to(State.MOVE)
		else:
			_transition_to(State.IDLE)
		return
	
	# 瞄准时可以射击（检测just_pressed或当前被按下，用于AI输入）
	if Input.is_action_just_pressed("fire") or Input.is_action_pressed("fire"):
		print("🎯 fire触发! 进入SHOOT状态")
		_transition_to(State.SHOOT)
		return
	
	# 记录历史
	_record_history_with_shoot(false)

# ========== SHOOT 状态 ==========
func _update_shoot(delta: float):
	print("🔫 SHOOT状态 - 执行射击!")
	
	# 执行射击
	_shoot()
	
	# 记录历史（带射击）
	_record_history_with_shoot(true)
	
	# 射击后检查状态
	if Input.is_action_pressed("aim"):
		_transition_to(State.AIM)
	else:
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction.length() > 0.1:
			_transition_to(State.MOVE)
		else:
			_transition_to(State.IDLE)
	
	# 射击后回到瞄准状态（如果还在按住瞄准键）
	if Input.is_action_pressed("aim"):
		_transition_to(State.AIM)
	else:
		# 检查是否在移动
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction.length() > 0.1:
			_transition_to(State.MOVE)
		else:
			_transition_to(State.IDLE)

# ========== 状态转换 ==========
func _transition_to(new_state: State):
	var old_state_name = _get_state_name(current_state)
	var new_state_name = _get_state_name(new_state)
	
	if current_state != new_state:
		print("🎯 玩家状态: ", old_state_name, " → ", new_state_name)
	
	current_state = new_state
	state_timer = 0.0

func _get_state_name(state: State) -> String:
	match state:
		State.IDLE: return "待机"
		State.MOVE: return "移动"
		State.AIM: return "瞄准"
		State.SHOOT: return "射击"
		_: return "未知"

func _aim_at_mouse() -> void:
	var mouse_pos := get_global_mouse_position()
	var angle := (mouse_pos - global_position).angle()
	rotation = angle

# 记录历史帧
func _record_history() -> void:
	var aim_dir := Vector2.RIGHT.rotated(rotation)
	var frame := HistoryFrame.new(position, aim_dir, false)
	position_history.append(frame)
	
	# 循环缓冲区：超过最大大小时移除最旧的帧
	if position_history.size() > HISTORY_SIZE:
		position_history.pop_front()

# 获取3秒前的历史帧
func get_frame_from_3s_ago() -> HistoryFrame:
	if position_history.size() < HISTORY_SIZE:
		# 历史不足3秒，返回第一帧
		return position_history[0] if position_history.size() > 0 else HistoryFrame.new(Vector2.ZERO, Vector2.RIGHT)
	
	# 返回3秒前的帧（数组最前面）
	return position_history[0]

# 记录历史（带射击状态）
var shoot_history: Array[bool] = []

func _record_history_with_shoot(did_shoot: bool) -> void:
	var aim_dir := Vector2.RIGHT.rotated(rotation)
	var frame := HistoryFrame.new(position, aim_dir, did_shoot)
	position_history.append(frame)
	shoot_history.append(did_shoot)
	
	# 循环缓冲区
	if position_history.size() > HISTORY_SIZE:
		position_history.pop_front()
		shoot_history.pop_front()

# 发射子弹
func _shoot() -> void:
	print("🔫 玩家发射!")
	# 播放开火音效
	var audio_manager = get_node_or_null("/root/Game/AudioManager")
	if audio_manager:
		audio_manager.play_fire()
	
	var bullet_scene = load("res://scenes/bullet.tscn")
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.velocity = Vector2.RIGHT.rotated(rotation) * bullet.SPEED
	bullet.is_echo = false
	get_tree().current_scene.add_child(bullet)

# 处理回声生成
var echo_spawn_index: int = 0

func _process_echo_spawn() -> void:
	# 检查3秒前的射击记录
	if shoot_history.size() >= HISTORY_SIZE:
		if shoot_history[0] and echo_spawn_index < position_history.size():
			_spawn_echo()
			# 不要立即标记为false，让AI有机会读取
			# 使用一个单独的数组来跟踪已处理的回声
			_process_echo_at_index(0)

# 获取即将生成的回声信息（供AI查询）
func get_pending_echo_info() -> Dictionary:
	if shoot_history.size() >= HISTORY_SIZE and shoot_history[0]:
		var old_frame = position_history[0]
		return {
			"will_spawn": true,
			"position": old_frame.position,
			"aim_direction": old_frame.aim_direction
		}
	return {"will_spawn": false}

var processed_echo_indices: Array[int] = []

func _process_echo_at_index(index: int) -> void:
	if index not in processed_echo_indices:
		processed_echo_indices.append(index)
		# 延迟标记为已处理，给AI时间读取
		_mark_processed_delayed(index)

func _mark_processed_delayed(index: int) -> void:
	await get_tree().create_timer(0.1).timeout
	if index < shoot_history.size():
		shoot_history[index] = false

func _spawn_echo() -> void:
	print("👻 生成回声!")
	# 播放回声生成音效
	var audio_manager = get_node_or_null("/root/Game/AudioManager")
	if audio_manager:
		audio_manager.play_echo_spawn()
	
	var old_frame = position_history[0]
	
	var echo_scene = load("res://scenes/echo.tscn")
	var echo = echo_scene.instantiate()
	echo.spawn_position = old_frame.position
	echo.aim_direction = old_frame.aim_direction
	
	get_tree().current_scene.add_child(echo)

func take_damage(amount: int) -> void:
	if is_dead or invulnerable:
		return
	
	hp -= amount
	print("💔 玩家受到 ", amount, " 点伤害! HP: ", hp, "/", MAX_HP)
	
	# 播放受伤音效
	var audio_manager = get_node_or_null("/root/Game/AudioManager")
	if audio_manager:
		audio_manager.play_hit_player()
	
	# 触发屏幕受伤闪烁效果
	var game_manager = get_node_or_null("/root/Game/GameManager")
	if game_manager and game_manager.has_method("trigger_player_damage_flash"):
		game_manager.trigger_player_damage_flash()
	
	# 更新血条
	_update_health_bar()
	
	# 视觉反馈 - 红色闪烁
	_flash_red()
	
	# 无敌时间
	invulnerable = true
	await get_tree().create_timer(1.0).timeout
	invulnerable = false
	
	if hp <= 0:
		_die()

func _update_health_bar():
	if health_bar_fg:
		var health_percent = float(hp) / MAX_HP
		health_bar_fg.size.x = 120 * health_percent
		
		# 根据血量改变颜色
		if health_percent > 0.6:
			health_bar_fg.color = Color(0.2, 0.8, 0.2, 1.0)  # 绿色
		elif health_percent > 0.3:
			health_bar_fg.color = Color(0.9, 0.9, 0.2, 1.0)  # 黄色
		else:
			health_bar_fg.color = Color(0.9, 0.2, 0.2, 1.0)  # 红色
	
	# 更新标签
	var canvas = get_node_or_null("PlayerHealthUI")
	if canvas:
		var label = canvas.get_node_or_null("HealthLabel")
		if label:
			label.text = "HP: %d/%d" % [hp, MAX_HP]

func _flash_red():
	sprite.modulate = Color(1, 0.3, 0.3, 1)
	await get_tree().create_timer(0.2).timeout
	if sprite:
		sprite.modulate = Color(1, 1, 1, 1)

func _die():
	is_dead = true
	print("☠️ 玩家死亡!")
	
	# 触发游戏结束
	var game_manager = get_node_or_null("/root/Game/GameManager")
	if game_manager:
		game_manager.trigger_game_over()
	else:
		print("⚠️ 未找到游戏管理器")
	# 可以在这里添加游戏结束逻辑
	# queue_free()

func get_hp() -> int:
	return hp

func get_max_hp() -> int:
	return MAX_HP
