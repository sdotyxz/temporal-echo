class_name Bullet
extends Area2D

const SPEED: float = 400.0
const MAX_BOUNCES: int = 3

var velocity: Vector2 = Vector2.ZERO
var bounce_count: int = 0
var is_echo: bool = false
var has_dealt_damage: bool = false  # 防止重复伤害

@onready var sprite: Sprite2D

func _ready():
	# 添加到子弹组
	add_to_group("bullets")
	
	# 获取或创建 Sprite2D
	sprite = get_node_or_null("Sprite2D")
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	# 创建 16x16 白色方块纹理
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	
	# 设置初始颜色
	_update_color()
	
	# 连接碰撞信号（检查是否已连接）
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# 创建碰撞形状（用于检测与Boss的碰撞）
	var collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 6.0  # 子弹半径
		collision_shape.shape = circle_shape
		add_child(collision_shape)
	
	# 设置碰撞层 - 检测墙壁(4)和敌人(2)
	collision_layer = 0  # 子弹自己不占据层
	collision_mask = 4 | 2  # 检测墙壁层和敌人层
	
	# 确保 Area2D 监控开启
	monitoring = true
	monitorable = true
	
	print("🎯 子弹已创建，位置: ", global_position)

func _on_body_entered(body: Node2D) -> void:
	if has_dealt_damage:
		return
	
	# 检测是否击中 Boss
	if body.is_in_group("boss") or body.is_in_group("enemies"):
		print("💥 子弹击中 Boss!")
		if body.has_method("take_damage"):
			body.take_damage(1)
		has_dealt_damage = true
		queue_free()  # 击中后销毁

func _physics_process(delta: float) -> void:
	# 射线检测墙壁
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + velocity.normalized() * (SPEED * delta + 8)  # 稍微提前检测
	)
	query.collision_mask = 4  # 墙壁层
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		if collider.is_in_group("walls"):
			print("💥 子弹撞到墙壁! 反弹次数: ", bounce_count)
			_bounce(collider, result.normal)
			# 调整位置到碰撞点
			global_position = result.position + result.normal * 9  # 稍微离开墙壁
	
	position += velocity * delta

func _bounce(wall: Node2D, normal: Vector2) -> void:
	if bounce_count >= MAX_BOUNCES:
		print("💨 子弹销毁（超过最大反弹次数）")
		queue_free()
		return
	
	# 镜面反射
	velocity = velocity.bounce(normal)
	bounce_count += 1
	
	# 速度增加 20%
	velocity *= 1.2
	
	print("🔄 反弹 #", bounce_count, " | 新速度: ", velocity.length(), " | 方向: ", velocity.normalized())
	
	# 播放反弹音效
	var audio_manager = get_node_or_null("/root/Game/AudioManager")
	if audio_manager:
		audio_manager.play_bounce(bounce_count - 1)  # 传入反弹次数用于音调
	
	# 颜色变化
	_update_color()
	
	# 反弹时的缩放脉冲
	_pulse_scale()

func _update_color():
	if not sprite:
		return
	
	var color: Color
	match bounce_count:
		0: color = Color(1, 1, 1)       # 白色
		1: color = Color(1, 1, 0)       # 黄色
		2: color = Color(1, 0.5, 0)     # 橙色
		3: color = Color(1, 0, 0)       # 红色
		_: color = Color(1, 0, 0)
	
	# 如果是回声，调整色调
	if is_echo:
		color = Color(0.3, 0.8, 1, 0.8) if bounce_count == 0 else Color(0.3, 0.9 - bounce_count * 0.1, 1 - bounce_count * 0.15, 0.8)
	
	sprite.modulate = color

func _pulse_scale():
	if sprite:
		var tween = create_tween()
		sprite.scale = Vector2.ONE * 1.5
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.15)

func setup(spawn_pos: Vector2, direction: Vector2, echo: bool = false) -> void:
	global_position = spawn_pos
	velocity = direction.normalized() * SPEED
	is_echo = echo
	_update_color()
