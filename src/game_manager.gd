extends Node

enum GameState { PLAYING, VICTORY, GAME_OVER }

var state: GameState = GameState.PLAYING
var game_timer: float = 0.0
const GAME_DURATION: float = 120.0  # 2分钟倒计时

@onready var victory_screen: Control
@onready var game_over_screen: Control
@onready var game_timer_label: Label
@onready var boss_health_bar: ProgressBar
@onready var player_health_bar: ProgressBar
@onready var boss_hp_label: Label
@onready var player_hp_label: Label

# 屏幕效果
var shake_timer: float = 0.0
var shake_intensity: float = 0.0
var original_camera_pos: Vector2 = Vector2.ZERO

func _ready():
	print("🎮 游戏管理器启动")
	_create_ui()
	_create_hud()

func _process(delta: float) -> void:
	if state == GameState.PLAYING:
		game_timer += delta
		_update_timer_display()
		_update_hud()
		_update_screen_effects(delta)

func _update_screen_effects(delta: float):
	# 屏幕震动
	if shake_timer > 0:
		shake_timer -= delta
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		# 获取相机并应用震动
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var camera = player.get_node_or_null("Camera2D")
			if camera:
				if shake_timer <= 0:
					# 震动结束，恢复位置
					camera.offset = Vector2.ZERO
				else:
					camera.offset = shake_offset

func trigger_screen_shake(duration: float = 0.2, intensity: float = 2.0):
	shake_timer = duration
	shake_intensity = intensity
	print("📳 屏幕震动: ", duration, "秒, 强度: ", intensity)

func trigger_double_hit_effect():
	trigger_screen_shake(0.2, 2.0)

func trigger_player_damage_flash():
	var hud_layer = get_node_or_null("HUDLayer")
	if hud_layer:
		var flash = hud_layer.get_node_or_null("DamageFlash")
		if flash:
			print("🔴 玩家受伤屏幕闪烁")
			# 闪烁效果：半透明红色 -> 透明
			flash.color = Color(1, 0, 0, 0.3)
			var tween = create_tween()
			tween.tween_property(flash, "color", Color(1, 0, 0, 0), 0.3)

func _create_ui():
	# 创建 UI CanvasLayer
	var ui_canvas = CanvasLayer.new()
	ui_canvas.name = "GameOverUILayer"
	add_child(ui_canvas)
	
	# 胜利画面
	victory_screen = _create_screen("VictoryScreen", Color(0, 0.5, 0, 0.8))
	ui_canvas.add_child(victory_screen)
	
	var victory_text = Label.new()
	victory_text.text = "🎉 VICTORY! 🎉"
	victory_text.add_theme_font_size_override("font_size", 48)
	victory_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_text.size = Vector2(800, 200)
	victory_text.position = Vector2(0, 150)
	victory_screen.add_child(victory_text)
	
	var victory_subtext = Label.new()
	victory_subtext.name = "VictorySubtext"
	victory_subtext.text = "Boss Defeated!"
	victory_subtext.add_theme_font_size_override("font_size", 24)
	victory_subtext.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_subtext.size = Vector2(800, 50)
	victory_subtext.position = Vector2(0, 280)
	victory_screen.add_child(victory_subtext)
	
	var restart_text_v = Label.new()
	restart_text_v.text = "Press R to Restart"
	restart_text_v.add_theme_font_size_override("font_size", 20)
	restart_text_v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_text_v.size = Vector2(800, 50)
	restart_text_v.position = Vector2(0, 350)
	victory_screen.add_child(restart_text_v)
	
	# 游戏结束画面
	game_over_screen = _create_screen("GameOverScreen", Color(0.5, 0, 0, 0.8))
	ui_canvas.add_child(game_over_screen)
	
	var game_over_text = Label.new()
	game_over_text.text = "💀 GAME OVER 💀"
	game_over_text.add_theme_font_size_override("font_size", 48)
	game_over_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_text.size = Vector2(800, 200)
	game_over_text.position = Vector2(0, 150)
	game_over_screen.add_child(game_over_text)
	
	var game_over_subtext = Label.new()
	game_over_subtext.text = "You Died"
	game_over_subtext.add_theme_font_size_override("font_size", 24)
	game_over_subtext.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_subtext.size = Vector2(800, 50)
	game_over_subtext.position = Vector2(0, 280)
	game_over_screen.add_child(game_over_subtext)
	
	var restart_text_g = Label.new()
	restart_text_g.text = "Press R to Restart"
	restart_text_g.add_theme_font_size_override("font_size", 20)
	restart_text_g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_text_g.size = Vector2(800, 50)
	restart_text_g.position = Vector2(0, 350)
	game_over_screen.add_child(restart_text_g)
	
	# 计时器
	var canvas = CanvasLayer.new()
	canvas.name = "GameTimerLayer"
	add_child(canvas)
	
	game_timer_label = Label.new()
	game_timer_label.name = "GameTimer"
	game_timer_label.text = "Time: 0.0s"
	game_timer_label.add_theme_font_size_override("font_size", 20)
	game_timer_label.position = Vector2(650, 20)
	canvas.add_child(game_timer_label)

func _create_screen(name: String, color: Color) -> Control:
	var screen = Control.new()
	screen.name = name
	screen.visible = false
	screen.size = Vector2(800, 600)
	
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = color
	bg.size = Vector2(800, 600)
	screen.add_child(bg)
	
	return screen

func _create_hud():
	# HUD CanvasLayer
	var hud_canvas = CanvasLayer.new()
	hud_canvas.name = "HUDLayer"
	add_child(hud_canvas)
	
	# 屏幕受伤闪烁效果（全屏红色覆盖）
	var damage_flash = ColorRect.new()
	damage_flash.name = "DamageFlash"
	damage_flash.color = Color(1, 0, 0, 0)
	damage_flash.size = Vector2(800, 600)
	damage_flash.position = Vector2(0, 0)
	damage_flash.z_index = 100  # 确保在最上层
	hud_canvas.add_child(damage_flash)
	
	# Boss血条背景
	var boss_bar_bg = ColorRect.new()
	boss_bar_bg.name = "BossBarBg"
	boss_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	boss_bar_bg.position = Vector2(250, 20)
	boss_bar_bg.size = Vector2(300, 25)
	hud_canvas.add_child(boss_bar_bg)
	
	# Boss血条
	boss_health_bar = ProgressBar.new()
	boss_health_bar.name = "BossHealthBar"
	boss_health_bar.position = Vector2(250, 20)
	boss_health_bar.size = Vector2(300, 25)
	boss_health_bar.max_value = 10
	boss_health_bar.value = 10
	boss_health_bar.show_percentage = false
	# 样式化
	var boss_style = StyleBoxFlat.new()
	boss_style.bg_color = Color(0.8, 0.2, 0.2)
	boss_health_bar.add_theme_stylebox_override("fill", boss_style)
	var boss_bg_style = StyleBoxFlat.new()
	boss_bg_style.bg_color = Color(0.2, 0.2, 0.2)
	boss_health_bar.add_theme_stylebox_override("background", boss_bg_style)
	hud_canvas.add_child(boss_health_bar)
	
	# Boss HP标签
	boss_hp_label = Label.new()
	boss_hp_label.name = "BossHPLabel"
	boss_hp_label.text = "Boss HP: 10/10"
	boss_hp_label.add_theme_font_size_override("font_size", 16)
	boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_label.position = Vector2(250, 22)
	boss_hp_label.size = Vector2(300, 20)
	hud_canvas.add_child(boss_hp_label)
	
	# 玩家血条背景
	var player_bar_bg = ColorRect.new()
	player_bar_bg.name = "PlayerBarBg"
	player_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	player_bar_bg.position = Vector2(20, 550)
	player_bar_bg.size = Vector2(200, 20)
	hud_canvas.add_child(player_bar_bg)
	
	# 玩家血条
	player_health_bar = ProgressBar.new()
	player_health_bar.name = "PlayerHealthBar"
	player_health_bar.position = Vector2(20, 550)
	player_health_bar.size = Vector2(200, 20)
	player_health_bar.max_value = 3
	player_health_bar.value = 3
	player_health_bar.show_percentage = false
	# 样式化
	var player_style = StyleBoxFlat.new()
	player_style.bg_color = Color(0.2, 0.6, 0.9)
	player_health_bar.add_theme_stylebox_override("fill", player_style)
	var player_bg_style = StyleBoxFlat.new()
	player_bg_style.bg_color = Color(0.2, 0.2, 0.2)
	player_health_bar.add_theme_stylebox_override("background", player_bg_style)
	hud_canvas.add_child(player_health_bar)
	
	# 玩家HP标签
	player_hp_label = Label.new()
	player_hp_label.name = "PlayerHPLabel"
	player_hp_label.text = "HP: 3/3"
	player_hp_label.add_theme_font_size_override("font_size", 14)
	player_hp_label.position = Vector2(20, 525)
	player_hp_label.size = Vector2(200, 20)
	hud_canvas.add_child(player_hp_label)

func _update_timer_display():
	if game_timer_label:
		var remaining = max(0, GAME_DURATION - game_timer)
		var minutes = int(remaining) / 60
		var seconds = int(remaining) % 60
		game_timer_label.text = "Time: %d:%02d" % [minutes, seconds]

func _update_hud():
	# 更新Boss血条
	var boss = get_tree().get_first_node_in_group("boss")
	if boss and boss_health_bar:
		boss_health_bar.value = boss.hp
		boss_hp_label.text = "Boss HP: %d/%d" % [boss.hp, boss.MAX_HP]
	
	# 更新玩家血条
	var player = get_tree().get_first_node_in_group("player")
	if player and player_health_bar:
		player_health_bar.value = player.hp
		player_hp_label.text = "HP: %d/%d" % [player.hp, player.MAX_HP]

func trigger_victory() -> void:
	if state != GameState.PLAYING:
		return
	
	state = GameState.VICTORY
	print("🎉 胜利！游戏时间: %.2f秒" % game_timer)
	
	# 更新胜利画面上的时间
	var subtext = victory_screen.get_node_or_null("VictorySubtext")
	if subtext:
		subtext.text = "Boss Defeated in %.2f seconds!" % game_timer
	
	victory_screen.visible = true
	
	# 停止游戏
	get_tree().paused = true

func trigger_game_over() -> void:
	if state != GameState.PLAYING:
		return
	
	state = GameState.GAME_OVER
	print("💀 游戏结束！存活时间: %.2f秒" % game_timer)
	
	game_over_screen.visible = true
	
	# 停止游戏
	get_tree().paused = true

func restart_game() -> void:
	print("🔄 重新开始游戏")
	
	# 重置状态
	state = GameState.PLAYING
	game_timer = 0.0
	
	# 隐藏画面
	victory_screen.visible = false
	game_over_screen.visible = false
	
	# 恢复游戏
	get_tree().paused = false
	
	# 重新加载当前场景
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_game()
