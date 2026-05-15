extends BaseEnemy

# ============================================
# SKELETON - 守卫骷髅 (近战小兵B)
# ============================================

var dash_timer: float = 0.0
var dash_cooldown: float = 3.0
var is_dashing: bool = false
var dash_speed: float = 300.0

func _ready() -> void:
	max_hp = 30
	damage = 15
	move_speed = 100
	detection_range = 200
	attack_range = 50
	current_hp = max_hp
	dash_timer = dash_cooldown

func update_enemy(delta: float) -> void:
	if not player_ref:
		return
	
	dash_timer -= delta
	
	var dist = global_position.distance_to(player_ref.global_position)
	
	if is_dashing:
		# 冲刺中
		move_and_slide()
		return
	
	if dist < attack_range:
		# 近距离攻击
		animation_player.play("attack")
		attack_player()
	elif dist < detection_range:
		# 追逐
		var dir = get_direction_to_player()
		
		# 定期冲刺
		if dash_timer <= 0 and dist < 150:
			dash_timer = dash_cooldown
			is_dashing = true
			velocity = dir * dash_speed
			animation_player.play("attack")
			await get_tree().create_timer(0.3).timeout
			is_dashing = false
		else:
			velocity.x = dir.x * move_speed
			move_and_slide()
		
		sprite.flip_h = dir.x < 0