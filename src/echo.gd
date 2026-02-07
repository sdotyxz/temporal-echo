class_name Echo
extends Node2D

var aim_direction: Vector2 = Vector2.RIGHT
var spawn_position: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	print("👻 回声生成!")
	
	# 设置位置
	global_position = spawn_position
	
	# 延迟 0.1 秒后发射
	await get_tree().create_timer(0.1).timeout
	_fire()

func _fire():
	print("👻 回声发射子弹!")
	
	# 创建子弹
	var bullet_scene = load("res://scenes/bullet.tscn")
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.velocity = aim_direction * bullet.SPEED
	bullet.is_echo = true
	
	# 添加到场景
	get_tree().current_scene.add_child(bullet)
	
	# 2秒后自动销毁回声
	await get_tree().create_timer(2.0).timeout
	queue_free()
