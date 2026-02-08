class_name Bullet
extends Area2D

const SPEED: float = 400.0
const MAX_BOUNCES: int = 3

var velocity: Vector2 = Vector2.ZERO
var bounce_count: int = 0
var is_echo: bool = false

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
	
	print("🎯 子弹已创建，位置: ", global_position)

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
