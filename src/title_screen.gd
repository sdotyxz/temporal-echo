extends Control

@onready var title_label: Label
@onready var start_button: Button
@onready var background: TextureRect

func _ready():
	print("🎮 开始游戏界面")
	_create_background()
	_create_ui()

func _create_background():
	# 创建图片背景
	background = TextureRect.new()
	background.name = "Background"
	background.size = Vector2(800, 600)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	# 加载 AI 生成的背景图
	var texture = load("res://assets/promo/title_bg.jpg")
	if texture:
		background.texture = texture
		print("🖼️ 已加载背景图片")
	else:
		print("⚠️ 背景图片加载失败，使用默认颜色")
		background.modulate = Color(0.05, 0.02, 0.08)
	
	add_child(background)
	move_child(background, 0)

func _create_ui():
	# 标题
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "🔥 TEMPORAL ECHO 🔥"
	title_label.add_theme_font_size_override("font_size", 56)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size = Vector2(800, 120)
	title_label.position = Vector2(0, 150)
	
	# 添加发光效果
	title_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	
	add_child(title_label)
	
	# 副标题
	var subtitle = Label.new()
	subtitle.text = "时间回声 - TriJam #358"
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size = Vector2(800, 50)
	subtitle.position = Vector2(0, 280)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(subtitle)
	
	# 开始游戏按钮
	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = "开始游戏"
	start_button.add_theme_font_size_override("font_size", 32)
	start_button.size = Vector2(200, 60)
	start_button.position = Vector2(300, 380)
	
	# 样式化按钮
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.5, 0.8)
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_left = 10
	button_style.corner_radius_bottom_right = 10
	start_button.add_theme_stylebox_override("normal", button_style)
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color(0.3, 0.6, 0.9)
	button_hover.corner_radius_top_left = 10
	button_hover.corner_radius_top_right = 10
	button_hover.corner_radius_bottom_left = 10
	button_hover.corner_radius_bottom_right = 10
	start_button.add_theme_stylebox_override("hover", button_hover)
	
	start_button.pressed.connect(_on_start_pressed)
	add_child(start_button)
	
	# 操作说明
	var controls = Label.new()
	controls.text = "WASD: 移动 | 鼠标: 瞄准 | 右键: 瞄准模式 | 左键: 射击 | R: 重启"
	controls.add_theme_font_size_override("font_size", 16)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.size = Vector2(800, 30)
	controls.position = Vector2(0, 520)
	controls.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	add_child(controls)

func _on_start_pressed():
	print("🎮 开始游戏！")
	
	# 播放开始音效（如果有）
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_fire"):
		audio_manager.play_fire()
	
	# 切换到游戏场景
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("fire"):
		_on_start_pressed()
