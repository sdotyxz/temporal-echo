extends Control

@onready var title_label: Label
@onready var start_button: Button
@onready var background: ColorRect

func _ready():
	print("🎮 开始游戏界面")
	_create_ui()
	_create_background()

func _create_background():
	# 创建反重力背景
	background = ColorRect.new()
	background.name = "Background"
	background.size = Vector2(800, 600)
	
	# 使用反重力着色器 - 粒子向上飘，零重力感
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform float time;
	
	void fragment() {
		vec2 uv = FRAGCOORD.xy / vec2(800.0, 600.0);
		
		// 反重力：粒子向上飘动
		float movement = mod(time * 0.1, 1.0);
		vec2 moving_uv = uv;
		moving_uv.y -= movement; // 向上移动
		
		// 创建漂浮的粒子
		float particle = 0.0;
		for(float i = 0.0; i < 5.0; i++) {
			vec2 p = moving_uv * (3.0 + i) + vec2(i * 1.5);
			p.y -= time * (0.1 + i * 0.02); // 反重力向上
			float n = fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
			if(n > 0.98) {
				particle += 0.3 * (1.0 - fract(p.y));
			}
		}
		
		// 深空背景渐变
		vec3 color1 = vec3(0.02, 0.02, 0.08);
		vec3 color2 = vec3(0.08, 0.02, 0.1);
		vec3 bg = mix(color1, color2, uv.y + sin(uv.x * 3.0) * 0.2);
		
		// 添加反重力流光效果
		float stream = sin(uv.x * 10.0 + time * 2.0) * 0.5 + 0.5;
		stream *= exp(-abs(uv.y - 0.5) * 4.0);
		bg += vec3(0.1, 0.3, 0.5) * stream * 0.15;
		
		// 叠加粒子
		bg += vec3(0.6, 0.8, 1.0) * particle;
		
		COLOR = vec4(bg, 1.0);
	}
	"""
	
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("time", 0.0)
	background.material = material
	
	add_child(background)
	move_child(background, 0)
	
	# 启动时间更新
	set_process(true)

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

func _process(delta):
	# 更新反重力背景时间
	if background and background.material:
		var current_time = background.material.get_shader_parameter("time")
		background.material.set_shader_parameter("time", current_time + delta)

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
