extends CharacterBody2D
class_name Player

# ============================================
# PLAYER CONTROLLER - 宝藏猎人温子月
# ============================================

# 移动参数
@export var move_speed: float = 300.0
@export var jump_force: float = -500.0
@export var gravity: float = 1200.0
@export var max_fall_speed: float = 800.0

# 攻击参数
@export var normal_attack_damage: int = 20
@export var charged_attack_min_damage: int = 30
@export var charged_attack_max_damage: int = 60
@export var charged_time: float = 1.0
@export var attack_cooldown: float = 0.5
@export var charged_attack_cooldown: float = 2.0

# 闪避参数
@export var dodge_distance: float = 150.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 1.5
@export var dodge_invincibility: float = 0.25

# 组件引用
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_label: Label = $StateLabel
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine: Node = $StateMachine

# 状态变量
var current_state: String = "Idle"
var facing_direction: int = 1  # 1 = 右, -1 = 左
var is_attacking: bool = false
var is_dodging: bool = false
var is_charging: bool = false
var charge_time: float = 0.0

# 冷却计时器
var attack_cooldown_timer: float = 0.0
var charged_attack_cooldown_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0

# 攻击碰撞信息
var attack_hit_history: Array = []

# 特效节点
var dodge_trail: Node2D
var charge_effect: Node2D

func _ready() -> void:
	# 初始化
	attack_hitbox.monitoring = false
	add_to_group("player")

func _process(delta: float) -> void:
	# 更新UI
	update_ui(delta)
	
	# 更新冷却
	update_cooldowns(delta)

func update_ui(delta: float) -> void:
	if state_label:
		state_label.text = current_state

func update_cooldowns(delta: float) -> void:
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	if charged_attack_cooldown_timer > 0:
		charged_attack_cooldown_timer -= delta
	if dodge_cooldown_timer > 0:
		dodge_cooldown_timer -= delta

func _physics_process(delta: float) -> void:
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
	
	# 移动
	move_and_slide()
	
	# 更新朝向
	if velocity.x > 0:
		facing_direction = 1
		sprite.flip_h = false
	elif velocity.x < 0:
		facing_direction = -1
		sprite.flip_h = true

# ================== 攻击系统 ==================

func can_attack() -> bool:
	return attack_cooldown_timer <= 0 and not is_dodging and not is_attacking

func can_charged_attack() -> bool:
	return charged_attack_cooldown_timer <= 0 and not is_dodging and not is_attacking

func attack() -> void:
	if not can_attack():
		return
	
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	
	# 普通攻击伤害
	var damage = GameState.get_attack_damage(normal_attack_damage)
	execute_attack(damage, 0.2)

func start_charging() -> void:
	if not can_charged_attack():
		return
	
	is_charging = true
	charge_time = 0.0

func release_charged_attack() -> void:
	if not is_charging:
		return
	
	is_charging = false
	is_attacking = true
	charged_attack_cooldown_timer = charged_attack_cooldown
	
	# 根据蓄力时间计算伤害
	var charge_ratio = min(charge_time / charged_time, 1.0)
	var damage = int(lerp(float(charged_attack_min_damage), float(charged_attack_max_damage), charge_ratio))
	damage = GameState.get_attack_damage(damage)
	
	execute_attack(damage, 0.5)

func execute_attack(damage: int, duration: float) -> void:
	# 激活碰撞检测
	attack_hitbox.monitoring = true
	attack_hit_history.clear()
	
	# 播放动画
	animation_player.play("attack")
	
	# 定时关闭碰撞检测
	await get_tree().create_timer(duration).timeout
	attack_hitbox.monitoring = false
	is_attacking = false

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body in attack_hit_history:
		return
	attack_hit_history.append(body)
	
	if body.has_method("take_damage"):
		body.take_damage(damage if "damage" in locals() else normal_attack_damage)

# ================== 闪避系统 ==================

func can_dodge() -> bool:
	return dodge_cooldown_timer <= 0 and not is_dodging and not is_on_wall()

func dodge() -> void:
	if not can_dodge():
		return
	
	is_dodging = true
	dodge_cooldown_timer = dodge_cooldown
	
	# 计算闪避方向
	var dodge_dir = facing_direction
	if Input.is_action_pressed("move_left"):
		dodge_dir = -1
	elif Input.is_action_pressed("move_right"):
		dodge_dir = 1
	
	# 执行闪避
	var target_pos = global_position + Vector2(dodge_distance * dodge_dir, 0)
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, dodge_duration)
	tween.set_ease(Tween.EASE_OUT_QUINT)
	tween.set_trans(Tween.TRANS_QUINT)
	
	# 闪烁效果
	modulate.a = 0.5
	await get_tree().create_timer(dodge_duration).timeout
	modulate.a = 1.0
	is_dodging = false

# ================== 受伤系统 ==================

func take_damage(amount: int) -> void:
	if GameState.has_shield:
		AudioManager.play_sfx("shield_hit")
		return
	
	GameState.player_current_hp -= amount
	
	# 受伤动画
	animation_player.play("hurt")
	
	# 击退效果
	velocity = Vector2(-facing_direction * 200, -200)
	
	if GameState.player_current_hp <= 0:
		GameState.player_current_hp = 0
		die()

func die() -> void:
	animation_player.play("death")
	GameState.state = GameState.GAME_OVER
	# 触发 GAME OVER
	
func heal(amount: int) -> void:
	GameState.heal(amount)

# ================== 状态相关 ==================

func get_facing_direction() -> int:
	return facing_direction

func is_on_ground() -> bool:
	return is_on_floor()

func set_state(state_name: String) -> void:
	current_state = state_name
	if state_label:
		state_label.text = state_name