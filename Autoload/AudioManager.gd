extends Node

# ============================================
# AUDIO MANAGER - 音频管理
# ============================================

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var current_music: AudioStream = null
var sfx_bus_index: int = 1
var music_bus_index: int = 0

func _ready() -> void:
	# 创建音频播放器
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)
	
	load_audio_settings()

func play_music(stream: AudioStream, fade_in: bool = true) -> void:
	if stream == current_music and music_player.playing:
		return
	
	current_music = stream
	music_player.stream = stream
	music_player.volume_db = -80 if fade_in else 0
	music_player.play()
	
	if fade_in:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", 0, 1.0)

func stop_music(fade_out: bool = true) -> void:
	if not music_player.playing:
		return
	
	if fade_out:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, 0.5)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()
	
	current_music = null

func play_sfx(sfx_name: String, volume_override: float = 0.0) -> void:
	var stream = load("res://Resources/audio/" + sfx_name + ".wav")
	if stream:
		var player = AudioStreamPlayer.new()
		player.stream = stream
		player.bus = "Master"
		if volume_override != 0.0:
			player.volume_db = volume_override
		add_child(player)
		player.play()
		player.tree_exited.connect(func(): player.queue_free())

func set_music_volume(volume: float) -> void:
	if music_player:
		music_player.volume_db = linear_to_db(volume)

func set_sfx_volume(volume: float) -> void:
	if sfx_player:
		sfx_player.volume_db = linear_to_db(volume)

func load_audio_settings() -> void:
	var master_vol = 1.0
	var music_vol = 0.8
	var sfx_vol = 1.0
	
	if has_node("/root/SaveManager"):
		master_vol = SaveManager.get_setting("master_volume", 1.0)
		music_vol = SaveManager.get_setting("music_volume", 0.8)
		sfx_vol = SaveManager.get_setting("sfx_volume", 1.0)
	
	if music_player:
		music_player.volume_db = linear_to_db(music_vol)