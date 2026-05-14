extends BaseEnemy

# ============================================
# CRAB - 螃蟹精英 (近战小兵C)
# ============================================

var charge_timer: float = 0.0
var charge_cooldown: float = 4.0
var is_charging: bool = false
var charge_speed: float = 400.0
var charge_duration: float = 0.5

func _ready() -> void:
	max_hp = 50
	damage = 20
	move_speed = 120
	detection_range = 250
	attack_range = 60
	current_hp = max_hp
	charge_timer = charge_cooldown

func update_enemy(delta: float) -> void:
	if not player_ref:
		return
	
	charge_timer -= delta
	
	var dist = global_position.distance_to(player_ref.global_position)
	
	if is_charging:
		move_and_slide()
		return
	
	# 左右横移保持距离
	var dir = get_direction_to_player()
	
	if dist < attack_range:
		animation_player.play("attack")
		attack_player()
	elif dist < detection_range:
		# 准备冲刺
		if charge_timer <= 0 and dist < 200:
			_start_charge(dir)
		else:
			# 左右横移
			velocity.x = -dir.x * move_speed * 0.5
			move_and_slide()
		
		sprite.flip_h = dir.x < 0

func _start_charge(dir: Vector2) -> void:
	charge_timer = charge_cooldown
	is_charging = true
	velocity = dir * charge_speed
	animation_player.play("charge")
	
	await get_tree().create_timer(charge_duration).timeout
	is_charging = false