extends Control

var time_elapsed: float = 0.0

func _ready() -> void:
	# 检查存档
	var load_btn = $MainVBox/LoadBtn
	if SaveManager.has_save_file():
		load_btn.disabled = false
		load_btn.modulate = Color(1, 1, 1, 1)
	else:
		load_btn.disabled = true
		load_btn.modulate = Color(0.5, 0.5, 0.5, 0.5)

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# 标题呼吸效果
	var title = $MainVBox/Title
	var glow = 0.7 + sin(time_elapsed * 2.0) * 0.3
	title.modulate = Color(0.0, glow, glow * 0.9, 1.0)

func _on_start_pressed() -> void:
	print("Start button pressed!")
	SaveManager.new_game()
	print("New game initialized, changing scene...")
	get_tree().change_scene_to_file("res://Levels/Level1.tscn")
	print("Scene changed!")
	GameState.state = GameState.State.PLAYING

func _on_load_pressed() -> void:
	if SaveManager.load_game():
		get_tree().change_scene_to_file("res://Levels/Level1.tscn")

func _on_settings_pressed() -> void:
	# TODO: 设置界面
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()