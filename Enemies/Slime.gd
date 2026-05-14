extends BaseEnemy

# ============================================
# SLIME - 小岛蟹 (近战小兵A)
# ============================================

func _ready() -> void:
	max_hp = 20
	damage = 10
	move_speed = 60
	detection_range = 150
	attack_range = 40
	current_hp = max_hp

func update_enemy(delta: float) -> void:
	if not player_ref:
		return
	
	var dist = global_position.distance_to(player_ref.global_position)
	
	if dist < attack_range:
		# 攻击
		if animation_player.current_animation != "attack":
			animation_player.play("attack")
		attack_player()
	elif dist < detection_range:
		# 追逐
		var dir = get_direction_to_player()
		velocity.x = dir.x * move_speed
		move_and_slide()
		
		if dir.x < 0:
			sprite.flip_h = true
		elif dir.x > 0:
			sprite.flip_h = false