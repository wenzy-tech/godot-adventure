extends Node

# ============================================
# GAME STATE - 全局游戏状态管理
# ============================================

# 游戏状态枚举
enum State {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY,
	LEVEL_COMPLETE
}

enum Difficulty {
	EASY,
	NORMAL,
	HARD
}

# 当前关卡
var current_level: int = 1
var current_checkpoint: Vector2 = Vector2(100, 400)

# 玩家属性
var player_max_hp: int = 100
var player_current_hp: int = 100
var player_attack_multiplier: float = 1.0
var attack_buff_timer: float = 0.0

# 道具状态
var has_shield: bool = false
var shield_timer: float = 0.0

# 游戏进度
var coins: int = 0
var defeated_enemies: Array = []
var collected_items: Array = []

# 当前状态
var state: State = State.MENU
var difficulty: Difficulty = Difficulty.NORMAL

func _process(delta: float) -> void:
	# 更新攻击buff
	if attack_buff_timer > 0:
		attack_buff_timer -= delta
		if attack_buff_timer <= 0:
			player_attack_multiplier = 1.0
	
	# 更新护盾
	if shield_timer > 0:
		shield_timer -= delta
		if shield_timer <= 0:
			has_shield = false

func reset_player_state() -> void:
	player_current_hp = player_max_hp
	player_attack_multiplier = 1.0
	attack_buff_timer = 0.0
	has_shield = false
	shield_timer = 0.0

func apply_attack_buff(duration: float) -> void:
	player_attack_multiplier = 1.5
	attack_buff_timer = duration

func apply_shield(duration: float) -> void:
	has_shield = true
	shield_timer = duration

func take_damage(amount: int) -> bool:
	if has_shield:
		return false
	player_current_hp -= amount
	if player_current_hp <= 0:
		player_current_hp = 0
		state = State.GAME_OVER
		return true
	return false

func heal(amount: int) -> void:
	player_current_hp = mini(player_current_hp + amount, player_max_hp)

func add_coins(amount: int) -> void:
	coins += amount

func get_attack_damage(base_damage: int) -> int:
	return int(base_damage * player_attack_multiplier)

func set_checkpoint(pos: Vector2) -> void:
	current_checkpoint = pos

func next_level() -> void:
	current_level += 1
	if current_level > 4:
		state = State.VICTORY
	else:
		reset_level_state()

func reset_level_state() -> void:
	defeated_enemies.clear()
	collected_items.clear()
	player_current_hp = player_max_hp
	player_attack_multiplier = 1.0
	attack_buff_timer = 0.0
	has_shield = false
	shield_timer = 0.0

func get_save_data() -> Dictionary:
	return {
		"current_level": current_level,
		"checkpoint": current_checkpoint,
		"coins": coins,
		"defeated_enemies": defeated_enemies,
		"collected_items": collected_items,
		"player_hp": player_current_hp
	}

func load_save_data(data: Dictionary) -> void:
	current_level = data.get("current_level", 1)
	current_checkpoint = data.get("checkpoint", Vector2(100, 400))
	coins = data.get("coins", 0)
	defeated_enemies = data.get("defeated_enemies", [])
	collected_items = data.get("collected_items", [])
	player_current_hp = data.get("player_hp", player_max_hp)