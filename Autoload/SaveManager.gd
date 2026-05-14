extends Node

# ============================================
# SAVE MANAGER - 存档管理
# ============================================

const SAVE_FILE_PATH = "user://save_game.dat"
const SETTINGS_FILE_PATH = "user://settings.cfg"

var save_data: Dictionary = {}
var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"difficulty": 1,  # 0=easy, 1=normal, 2=hard
	"fullscreen": false
}

func _ready() -> void:
	load_settings()

func save_game() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var data = GameState.get_save_data()
		var json_str = JSON.stringify(data)
		file.store_line(json_str)
		file.close()
		print("Game saved!")
	else:
		print("Failed to save game")

func load_game() -> bool:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var json_str = file.get_line()
			var data = JSON.parse_string(json_str)
			if data:
				GameState.load_save_data(data)
				file.close()
				print("Game loaded!")
				return true
	return false

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("Save file deleted")

func save_settings() -> void:
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(settings)
		file.store_line(json_str)
		file.close()

func load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_FILE_PATH):
		var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
		if file:
			var json_str = file.get_line()
			var data = JSON.parse_string(json_str)
			if data:
				settings = data
			file.close()

func get_setting(key: String, default = null):
	return settings.get(key, default)

func set_setting(key: String, value) -> void:
	settings[key] = value
	save_settings()

func new_game() -> void:
	GameState.current_level = 1
	GameState.current_checkpoint = Vector2(100, 400)
	GameState.coins = 0
	GameState.defeated_enemies.clear()
	GameState.collected_items.clear()
	GameState.reset_player_state()
	GameState.state = GameState.GameState.PLAYING