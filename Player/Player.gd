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

# 组件引用
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_label: Label = $StateLabel

# 状态
enum State { IDLE, WALK, JUMP, FALL, ATTACK, CHARGE, DODGE, HURT, DEAD }
var current_state: State = State.IDLE
var facing_direction: int = 1

# 状态变量
var is_attacking: bool = false
var is_dodging: bool = false
var is_charging: bool = false
var charge_time: float = 0.0
var was_on_floor: bool = false

# 冷却计时器
var attack_cooldown_timer: float = 0.0
var charged_attack_cooldown_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var hurt_timer: float = 0.0

# 攻击碰撞信息
var attack_hit_history: Array = []

# 蓄力特效节点
var charge_effect: Node2D

func _ready() -> void:
	attack_hitbox.monitoring = false
	add_to_group("player")
	
	# 初始化位置
	global_position = GameState.current_checkpoint

func _process(delta: float) -> void:
	update_ui(delta)
	update_cooldowns(delta)
	handle_charge_input(delta)

func update_ui(delta: float) -> void:
	if state_label:
		state_label.text = State.keys()[current_state]

func update_cooldowns(delta: float) -> void:
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	if charged_attack_cooldown_timer > 0:
		charged_attack_cooldown_timer -= delta
	if dodge_cooldown_timer > 0:
		dodge_cooldown_timer -= delta
	if hurt_timer > 0:
		hurt_timer -= delta

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	was_on_floor = is_on_floor()
	
	# 输入处理
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	
	match current_state:
		case State.IDLE, State.WALK:
			handle_movement_input(input_dir, delta)
			handle_jump_input()
			handle_attack_input()
			handle_dodge_input()
		
		case State.JUMP, State.FALL:
			handle_movement_input(input_dir, delta)
			handle_attack_input()
			handle_dodge_input()
			handle_landing()
		
		case State.CHARGE:
			# 蓄力时不移动
			pass
		
		case State.DODGE:
			pass
		
		case State.HURT:
			if hurt_timer <= 0:
				current_state = State.IDLE
	
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
	
	# 更新动画
	update_animation()

func handle_movement_input(input_dir: Vector2, delta: float) -> void:
	if is_attacking or is_dodging:
		return
	
	if input_dir.x != 0:
		velocity.x = input_dir.x * move_speed
		if is_on_floor() and current_state != State.JUMP:
			current_state = State.WALK
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		if is_on_floor() and current_state == State.WALK:
			current_state = State.IDLE

func handle_jump_input() -> void:
	if is_attacking or is_dodging:
		return
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		current_state = State.JUMP
		anim_player.play("jump")

func handle_attack_input() -> void:
	if is_attacking or is_dodging:
		return
	
	# 闪避优先
	if Input.is_action_just_pressed("dodge"):
		start_dodge()
		return
	
	# 普通攻击
	if Input.is_action_just_pressed("attack") and attack_cooldown_timer <= 0:
		execute_normal_attack()
		return
	
	# 蓄力攻击
	if Input.is_action_pressed("attack") and charged_attack_cooldown_timer <= 0 and not is_charging:
		start_charge()
	
	if Input.is_action_just_released("attack") and is_charging:
		release_charged_attack()

func handle_dodge_input() -> void:
	if Input.is_action_just_pressed("dodge") and dodge_cooldown_timer <= 0 and is_on_floor():
		start_dodge()

func handle_charge_input(delta: float) -> void:
	if is_charging:
		charge_time += delta
		# 蓄力特效可以在这里更新

func handle_landing() -> void:
	if is_on_floor() and velocity.y >= 0:
		current_state = State.IDLE if velocity.x == 0 else State.WALK

func start_dodge() -> void:
	is_dodging = true
	dodge_cooldown_timer = dodge_cooldown
	current_state = State.DODGE
	
	# 计算闪避方向
	var dodge_dir = facing_direction
	if Input.is_action_pressed("move_left"):
		dodge_dir = -1
	elif Input.is_action_pressed("move_right"):
		dodge_dir = 1
	
	# 执行闪避位移
	var target_pos = global_position + Vector2(dodge_distance * dodge_dir, 0)
	var tween = create_tween()
	tween.tween_property(self, "global_position:x", target_pos.x, dodge_duration)
	tween.set_ease(Tween.EASE_OUT_QUINT)
	tween.set_trans(Tween.TRANS_QUINT)
	
	# 无敌帧效果
	modulate.a = 0.5
	
	await get_tree().create_timer(dodge_duration).timeout
	modulate.a = 1.0
	is_dodging = false
	
	if is_on_floor():
		current_state = State.IDLE
	else:
		current_state = State.FALL

func execute_normal_attack() -> void:
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	current_state = State.ATTACK
	
	attack_hitbox.monitoring = true
	attack_hit_history.clear()
	
	anim_player.play("attack")
	
	await get_tree().create_timer(0.3).timeout
	attack_hitbox.monitoring = false
	is_attacking = false
	
	if is_on_floor():
		current_state = State.IDLE
	else:
		current_state = State.FALL

func start_charge() -> void:
	is_charging = true
	charge_time = 0.0
	current_state = State.CHARGE
	anim_player.play("charge")

func release_charged_attack() -> void:
	is_charging = false
	is_attacking = true
	charged_attack_cooldown_timer = charged_attack_cooldown
	
	# 根据蓄力时间计算伤害
	var charge_ratio = min(charge_time / charged_time, 1.0)
	var damage = int(lerp(float(charged_attack_min_damage), float(charged_attack_max_damage), charge_ratio))
	damage = GameState.get_attack_damage(damage)
	
	attack_hitbox.monitoring = true
	attack_hit_history.clear()
	
	anim_player.play("charged_attack")
	
	await get_tree().create_timer(0.4).timeout
	attack_hitbox.monitoring = false
	is_attacking = false
	
	if is_on_floor():
		current_state = State.IDLE
	else:
		current_state = State.FALL

func update_animation() -> void:
	if is_attacking or is_charging or is_dodging:
		return
	
	match current_state:
		State.IDLE:
			anim_player.play("idle")
		State.WALK:
			anim_player.play("walk")
		State.JUMP:
			if velocity.y < 0:
				anim_player.play("jump_up")
			else:
				anim_player.play("jump_down")
		State.FALL:
			anim_player.play("fall")
		State.HURT:
			anim_player.play("hurt")

# ================== 碰撞系统 ==================

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body in attack_hit_history:
		return
	if not is_attacking:
		return
	
	attack_hit_history.append(body)
	
	if body.has_method("take_damage"):
		var damage = GameState.get_attack_damage(normal_attack_damage)
		var knockback = Vector2(facing_direction * 300, -100)
		body.take_damage(damage, knockback)

# ================== 受伤系统 ==================

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if GameState.has_shield or current_state == State.DODGE:
		return
	
	GameState.player_current_hp -= amount
	current_state = State.HURT
	hurt_timer = 0.3
	
	# 击退
	velocity = knockback
	move_and_slide()
	
	anim_player.play("hurt")
	
	if GameState.player_current_hp <= 0:
		GameState.player_current_hp = 0
		die()

func die() -> void:
	current_state = State.DEAD
	anim_player.play("death")
	GameState.state = GameState.GAME_OVER

func heal(amount: int) -> void:
	GameState.heal(amount)

# ================== 状态查询 ==================

func get_facing_direction() -> int:
	return facing_direction

func is_on_ground() -> bool:
	return is_on_floor()