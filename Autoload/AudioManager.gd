extends Node

# ============================================
# AUDIO MANAGER - 音频管理
# ============================================

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

var current_music: AudioStream = null
var sfx_bus_index: int = 1  # SFX bus
var music_bus_index: int = 0  # Master bus

func _ready() -> void:
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
	# Placeholder - will load actual sfx files later
	var stream = load("res://Resources/audio/" + sfx_name + ".wav")
	if stream:
		var player = AudioStreamPlayer.new()
		player.stream = stream
		player.bus = AudioServer.get_bus_name(sfx_bus_index)
		if volume_override != 0.0:
			player.volume_db = volume_override
		add_child(player)
		player.play()
		player.tree_exited.connect(func(): player.queue_free())

func set_music_volume(volume: float) -> void:
	# volume: 0.0 to 1.0
	music_player.volume_db = linear_to_db(volume)

func set_sfx_volume(volume: float) -> void:
	# volume: 0.0 to 1.0
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(volume))

func load_audio_settings() -> void:
	var master_vol = SaveManager.get_setting("master_volume", 1.0)
	var music_vol = SaveManager.get_setting("music_volume", 0.8)
	var sfx_vol = SaveManager.get_setting("sfx_volume", 1.0)
	
	AudioServer.set_bus_volume_db(0, linear_to_db(master_vol))
	music_player.volume_db = linear_to_db(music_vol)
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_vol))