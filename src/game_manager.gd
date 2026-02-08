extends Node

enum GameState { PLAYING, VICTORY, GAME_OVER }

var state: GameState = GameState.PLAYING
var game_timer: float = 0.0

@onready var victory_screen: Control
@onready var game_over_screen: Control
@onready var game_timer_label: Label

func _ready():
	print("🎮 游戏管理器启动")
	_create_ui()

func _process(delta: float) -> void:
	if state == GameState.PLAYING:
		game_timer += delta
		_update_timer_display()

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

func _update_timer_display():
	if game_timer_label:
		game_timer_label.text = "Time: %.1fs" % game_timer

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
