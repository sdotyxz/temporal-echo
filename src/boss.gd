class_name Boss
extends CharacterBody2D

const SPEED: float = 80.0
const MAX_HP: int = 10

@export var player: CharacterBody2D

@onready var sprite: Sprite2D
@onready var collision_shape: CollisionShape2D

var hp: int = MAX_HP
var is_dead: bool = false

func _ready():
	print("👹 Boss 已生成")
	print("❤️ Boss HP: ", hp, "/", MAX_HP)
	
	# 如果 player 未设置，尝试查找
	if player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			print("👹 自动找到玩家: ", player)
		else:
			# 尝试通过名称查找
			var root = get_tree().current_scene
			if root:
				player = root.get_node_or_null("Player")
				if player:
					print("👹 通过名称找到玩家: ", player)
				else:
					print("👹 ⚠️ 未找到玩家节点！")
	else:
		print("👹 玩家引用已设置: ", player)
	
	# 创建精灵
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)
	
	# 创建64x64红色方块
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.2, 0.2, 1.0))  # 红色
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	
	# 创建碰撞形状
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(64, 64)
	collision_shape.shape = rect_shape
	add_child(collision_shape)
	
	# 设置碰撞层
	collision_layer = 2  # Enemies 层
	collision_mask = 1   # Player 层

func _physics_process(delta: float) -> void:
	if is_dead or player == null:
		return
	
	# 向玩家移动
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * SPEED
	
	# 面向玩家
	rotation = direction.angle()
	
	# 移动
	move_and_slide()
	
	# 检测与玩家接触
	_check_player_contact()

func _check_player_contact():
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			_damage_player(collider)

func _damage_player(player_node: Node2D):
	# 这里会在玩家脚本中实现受伤逻辑
	print("💥 Boss 接触到玩家!")
	# 给玩家发送伤害信号
	if player_node.has_method("take_damage"):
		player_node.take_damage(1)

func take_damage(amount: int) -> void:
	hp -= amount
	print("💥 Boss 受到 ", amount, " 点伤害! HP: ", hp, "/", MAX_HP)
	
	# 视觉反馈 - 红色闪烁
	_flash_red()
	
	if hp <= 0:
		_die()

func _flash_red():
	# 简单的闪烁效果
	sprite.modulate = Color(1, 0.5, 0.5, 1)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1, 1)

func _die():
	is_dead = true
	print("☠️ Boss 被击败!")
	queue_free()

func get_hp() -> int:
	return hp

func get_max_hp() -> int:
	return MAX_HP
