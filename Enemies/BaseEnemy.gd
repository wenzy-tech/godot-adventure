extends CharacterBody2D
class_name BaseEnemy

# ============================================
# BASE ENEMY - 敌人基类
# ============================================

@export var max_hp: int = 30
@export var damage: int = 10
@export var move_speed: float = 100.0
@export var detection_range: float = 200.0
@export var attack_range: float = 50.0
@export var knockback_force: float = 200.0

var current_hp: int
var is_alive: bool = true
var is_hurt: bool = false
var player_ref: Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	# 查找玩家
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("player")
	
	update_enemy(delta)

func update_enemy(delta: float) -> void:
	# 重写实现具体敌人行为
	pass

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if not is_alive:
		return
	
	current_hp -= amount
	is_hurt = true
	
	# 更新血条
	if has_node("HealthBar"):
		var ratio = float(current_hp) / float(max_hp)
		var bar = $"HealthBar"
		var max_width = 36.0
		bar.size.x = max_width * ratio
	
	if has_node("Label"):
		$"Label".text = str(current_hp)
	
	# 受伤动画
	if animation_player.has_animation("hurt"):
		animation_player.play("hurt")
	
	# 击退
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir * knockback_force
		move_and_slide()
	
	# 死亡检查
	if current_hp <= 0:
		die()

func die() -> void:
	is_alive = false
	queue_free()

func attack_player() -> void:
	if not player_ref:
		return
	
	if player_ref.has_method("take_damage"):
		player_ref.take_damage(damage)

func can_see_player() -> bool:
	if not player_ref:
		return false
	var dist = global_position.distance_to(player_ref.global_position)
	return dist < detection_range

func can_attack_player() -> bool:
	if not player_ref:
		return false
	var dist = global_position.distance_to(player_ref.global_position)
	return dist < attack_range

func get_direction_to_player() -> Vector2:
	if not player_ref:
		return Vector2.ZERO
	return (player_ref.global_position - global_position).normalized()