extends BaseEnemy

# ============================================
# ARCHER - 弓手 (远程敌人)
# ============================================

var shoot_cooldown: float = 2.0
var shoot_timer: float = 0.0
var bullet_scene: PackedScene = preload("res://Enemies/Arrow.tscn")
var preferred_distance: float = 200.0

func _ready() -> void:
	max_hp = 15
	damage = 8
	move_speed = 80
	detection_range = 300
	attack_range = 250
	current_hp = max_hp
	shoot_timer = shoot_cooldown

func update_enemy(delta: float) -> void:
	if not player_ref:
		return
	
	shoot_timer -= delta
	
	var dist = global_position.distance_to(player_ref.global_position)
	var dir = get_direction_to_player()
	
	# 保持距离
	if dist < preferred_distance - 50:
		# 太近，后退
		velocity.x = -dir.x * move_speed
	elif dist > preferred_distance + 50:
		# 太远，前进
		velocity.x = dir.x * move_speed * 0.5
	else:
		velocity.x = 0
	
	move_and_slide()
	sprite.flip_h = dir.x < 0
	
	# 射击
	if shoot_timer <= 0 and dist < attack_range:
		shoot_timer = shoot_cooldown
		shoot_arrow(dir)

func shoot_arrow(dir: Vector2) -> void:
	if animation_player.has_animation("shoot"):
		animation_player.play("shoot")
	
	if bullet_scene:
		var arrow = bullet_scene.instantiate()
		arrow.position = global_position
		arrow.direction = dir
		get_parent().add_child(arrow)