extends Node

# 音频播放器
@onready var fire_sound: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var echo_spawn_sound: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var bounce_sound: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var hit_boss_sound: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var hit_player_sound: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var bgm_player: AudioStreamPlayer = AudioStreamPlayer.new()

# 反弹音调递增
var bounce_pitch: float = 1.0
const BOUNCE_PITCH_INCREMENT: float = 0.1
const MAX_BOUNCE_PITCH: float = 2.0

func _ready():
	print("🎵 音频管理器启动")
	
	# 添加播放器到场景
	add_child(fire_sound)
	add_child(echo_spawn_sound)
	add_child(bounce_sound)
	add_child(hit_boss_sound)
	add_child(hit_player_sound)
	add_child(bgm_player)
	
	# 设置音量
	fire_sound.volume_db = -10.0
	echo_spawn_sound.volume_db = -5.0
	bounce_sound.volume_db = -8.0
	hit_boss_sound.volume_db = -5.0
	hit_player_sound.volume_db = -5.0
	hit_player_sound.pitch_scale = 0.8
	bgm_player.volume_db = -15.0
	
	# 尝试加载音频（如果存在）
	_load_audio_if_exists(fire_sound, "res://assets/audio/fire.ogg")
	_load_audio_if_exists(echo_spawn_sound, "res://assets/audio/echo_spawn.ogg")
	_load_audio_if_exists(bounce_sound, "res://assets/audio/bounce.ogg")
	_load_audio_if_exists(hit_boss_sound, "res://assets/audio/hit_boss.ogg")

func _load_audio_if_exists(player: AudioStreamPlayer, path: String):
	if FileAccess.file_exists(path):
		var stream = load(path)
		if stream:
			player.stream = stream
			print("🎵 加载音频: ", path)
		else:
			print("⚠️ 无法加载音频: ", path)
	else:
		print("⚠️ 音频文件不存在: ", path)

func play_fire():
	if fire_sound and fire_sound.stream:
		fire_sound.play()

func play_echo_spawn():
	if echo_spawn_sound and echo_spawn_sound.stream:
		echo_spawn_sound.play()

func play_bounce(bounce_count: int):
	if bounce_sound and bounce_sound.stream:
		# 根据反弹次数增加音调
		var pitch = 1.0 + (bounce_count * BOUNCE_PITCH_INCREMENT)
		pitch = min(pitch, MAX_BOUNCE_PITCH)
		bounce_sound.pitch_scale = pitch
		bounce_sound.play()

func play_hit_boss():
	if hit_boss_sound and hit_boss_sound.stream:
		hit_boss_sound.play()

func play_hit_player():
	if hit_player_sound and hit_player_sound.stream:
		hit_player_sound.play()

func play_bgm():
	if bgm_player and bgm_player.stream:
		bgm_player.play()

func stop_bgm():
	if bgm_player:
		bgm_player.stop()
