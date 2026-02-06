class_name Player
extends CharacterBody2D

const SPEED: float = 200.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	print("🎯 玩家准备就绪")

func _physics_process(delta: float) -> void:
	# 获取移动输入
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 设置速度
	velocity = direction * SPEED
	
	# 移动
	move_and_slide()
	
	# 面向鼠标
	_aim_at_mouse()

func _aim_at_mouse() -> void:
	var mouse_pos := get_global_mouse_position()
	var angle := (mouse_pos - global_position).angle()
	rotation = angle
