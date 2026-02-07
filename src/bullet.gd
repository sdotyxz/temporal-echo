class_name Bullet
extends Area2D

const SPEED: float = 400.0
const MAX_BOUNCES: int = 3

var velocity: Vector2 = Vector2.ZERO
var bounce_count: int = 0
var is_echo: bool = false

func _ready():
	# 设置视觉
	if is_echo:
		modulate = Color(0.3, 0.8, 1, 0.8)  # 青色半透明
	else:
		modulate = Color(1, 1, 0, 1)  # 黄色

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("walls"):
		_bounce(body)

func _bounce(wall: Node2D) -> void:
	if bounce_count >= MAX_BOUNCES:
		queue_free()
		return
	
	# 计算反弹
	var to_wall: Vector2 = wall.global_position - global_position
	if abs(to_wall.x) > abs(to_wall.y):
		velocity.x *= -1
	else:
		velocity.y *= -1
	
	bounce_count += 1
	
	# 速度增加 20%
	velocity *= 1.2
	
	# 颜色变化
	_update_color()

func _update_color():
	match bounce_count:
		0: modulate = Color(1, 1, 0) if not is_echo else Color(0.3, 0.8, 1)
		1: modulate = Color(1, 0.8, 0) if not is_echo else Color(0.3, 0.9, 0.9)
		2: modulate = Color(1, 0.5, 0) if not is_echo else Color(0.3, 1, 0.8)
		3: modulate = Color(1, 0, 0) if not is_echo else Color(0.3, 1, 0.5)
