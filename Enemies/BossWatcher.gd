extends BaseEnemy

# ============================================
# ISLAND WATCHER - 岛屿守望者 (BOSS)
# ============================================

enum Phase { PHASE1, PHASE2 }

var current_phase: Phase = Phase.PHASE1
var phase_transition_hp: int = 250  # 50% HP

var attack_patterns: Array = []
var current_pattern: int = 0
var pattern_timer: float = 0.0
var summon_cooldown: float = 30.0
var summon_timer: float = 0.0

# BOSS 特殊参数
var boss_max_hp: int = 500

func _ready() -> void:
	max_hp = boss_max_hp
	damage = 25
	move_speed = 80
	detection_range = 400
	attack_range = 80
	current_hp = max_hp
	add_to_group("boss")

func update_enemy(delta: float) -> void:
	if not player_ref:
		return
	
	# 阶段检查
	if current_hp <= phase_transition_hp and current_phase == Phase.PHASE1:
		_transition_to_phase2()
	
	# 攻击模式循环
	pattern_timer -= delta
	if pattern_timer <= 0:
		_execute_attack_pattern()
	
	# 召唤小怪
	summon_timer -= delta
	if summon_timer <= 0 and current_phase == Phase.PHASE1:
		summon_timer = summon_cooldown
		_summon_minions()

func _transition_to_phase2() -> void:
	current_phase = Phase.PHASE2
	damage = 30  # 伤害增加
	move_speed = 110  # 速度增加
	animation_player.play("enrage")
	
	# 特效
	AudioManager.play_sfx("boss_enrage")

func _execute_attack_pattern() -> void:
	match current_phase:
		Phase.PHASE1:
			_phase1_attacks()
		Phase.PHASE2:
			_phase2_attacks()
	
	current_pattern = (current_pattern + 1) % 3
	pattern_timer = 2.0

func _phase1_attacks() -> void:
	match current_pattern:
		0:
			_single_slash()
		1:
			_shockwave()
		2:
			_wave_slash()

func _phase2_attacks() -> void:
	match current_pattern:
		0:
			_triple_slash()
		1:
			_magic_barrage()
		2:
			_rush_attack()

func _single_slash() -> void:
	# 单手挥砍
	animation_player.play("attack1")
	await get_tree().create_timer(0.3).timeout
	attack_player()

func _shockwave() -> void:
	# 跳跃冲击波
	animation_player.play("jump")
	var target_pos = player_ref.global_position
	velocity = (target_pos - global_position).normalized() * 300
	move_and_slide()
	
	await get_tree().create_timer(0.5).timeout
	# 落地冲击波特效
	animation_player.play("shockwave")

func _wave_slash() -> void:
	animation_player.play("attack2")
	await get_tree().create_timer(0.4).timeout
	attack_player()

func _triple_slash() -> void:
	# 三连击
	for i in range(3):
		animation_player.play("attack_quick")
		await get_tree().create_timer(0.2).timeout
		attack_player()
		await get_tree().create_timer(0.2).timeout

func _magic_barrage() -> void:
	# 放射状弹幕
	animation_player.play("cast")
	var bullet_count = 8
	for i in range(bullet_count):
		var angle = (TAU / bullet_count) * i
		_spawn_magic_ball(Vector2(cos(angle), sin(angle)))

func _rush_attack() -> void:
	# 快速冲刺攻击
	animation_player.play("attack")
	var dir = get_direction_to_player()
	for i in range(5):
		velocity = dir * 500
		move_and_slide()
		attack_player()
		await get_tree().create_timer(0.1).timeout

func _summon_minions() -> void:
	# 召唤2个小岛蟹
	var slime_scene = preload("res://Enemies/Slime.tscn")
	for i in range(2):
		var slime = slime_scene.instantiate()
		slime.global_position = global_position + Vector2(randf_range(-50, 50), 0)
		get_parent().add_child(slime)

func _spawn_magic_ball(dir: Vector2) -> void:
	# 发射魔法弹
	var bullet = preload("res://Enemies/MagicBullet.tscn").instantiate()
	bullet.position = global_position
	bullet.direction = dir
	get_parent().add_child(bullet)

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	current_hp -= amount
	
	
	if animation_player.has_animation("hurt"):
		animation_player.play("hurt")
	
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir * knockback_force * 0.5
		move_and_slide()
	
	if current_hp <= 0:
		die_boss()

func die_boss() -> void:
	is_alive = false
	
	# BOSS 死亡特效
	animation_player.play("death")
	AudioManager.play_sfx("boss_death")
	
	# 延迟移除
	await get_tree().create_timer(2.0).timeout
	queue_free()
	
	# 触发关卡完成
	GameState.state = GameState.LEVEL_COMPLETE