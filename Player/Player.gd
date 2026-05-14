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
const STATE_IDLE = 0
const STATE_WALK = 1
const STATE_JUMP = 2
const STATE_FALL = 3
const STATE_ATTACK = 4
const STATE_CHARGE = 5
const STATE_DODGE = 6
const STATE_HURT = 7
const STATE_DEAD = 8

var current_state: int = STATE_IDLE
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

# 按键状态
var keys_pressed := {
	"left": false,
	"right": false,
	"jump": false,
	"attack": false,
	"dodge": false
}

func _ready() -> void:
	print("Player ready!")
	print("Player position: ", global_position)
	attack_hitbox.monitoring = false
	add_to_group("player")
	global_position = GameState.current_checkpoint

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_A: keys_pressed["left"] = true
			KEY_D: keys_pressed["right"] = true
			KEY_W: keys_pressed["jump"] = true
			KEY_J: keys_pressed["attack"] = true
			KEY_SHIFT: keys_pressed["dodge"] = true
	elif event is InputEventKey and not event.pressed:
		match event.keycode:
			KEY_A: keys_pressed["left"] = false
			KEY_D: keys_pressed["right"] = false
			KEY_W: keys_pressed["jump"] = false
			KEY_J: keys_pressed["attack"] = false
			KEY_SHIFT: keys_pressed["dodge"] = false

func _physics_process(delta: float) -> void:
	if current_state == STATE_DEAD:
		return
	
	was_on_floor = is_on_floor()
	
	# 基于按键状态计算输入
	var input_dir = 0.0
	if keys_pressed["left"]:
		input_dir -= 1.0
	if keys_pressed["right"]:
		input_dir += 1.0
	
	if current_state == STATE_IDLE or current_state == STATE_WALK:
		handle_movement_input(input_dir, delta)
		handle_jump_input()
		handle_attack_input()
		handle_dodge_input()
	elif current_state == STATE_JUMP or current_state == STATE_FALL:
		handle_movement_input(input_dir, delta)
		handle_attack_input()
		handle_dodge_input()
		handle_landing()
	elif current_state == STATE_CHARGE:
		pass
	elif current_state == STATE_DODGE:
		pass
	elif current_state == STATE_HURT:
		if hurt_timer <= 0:
			current_state = STATE_IDLE
	
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = mini(velocity.y, max_fall_speed)
	
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

func handle_movement_input(input_dir: float, delta: float) -> void:
	if is_attacking or is_dodging:
		return
	
	if input_dir != 0:
		velocity.x = input_dir * move_speed
		if is_on_floor() and current_state != STATE_JUMP:
			current_state = STATE_WALK
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		if is_on_floor() and current_state == STATE_WALK:
			current_state = STATE_IDLE

func handle_jump_input() -> void:
	if is_attacking or is_dodging:
		return
	
	if keys_pressed["jump"] and is_on_floor():
		velocity.y = jump_force
		current_state = STATE_JUMP
		anim_player.play("jump")
		keys_pressed["jump"] = false

func handle_attack_input() -> void:
	if is_attacking or is_dodging:
		return
	
	if keys_pressed["dodge"] and dodge_cooldown_timer <= 0 and is_on_floor():
		start_dodge()
		keys_pressed["dodge"] = false
		return
	
	if keys_pressed["attack"] and attack_cooldown_timer <= 0:
		execute_normal_attack()
		keys_pressed["attack"] = false

func handle_dodge_input() -> void:
	pass

func handle_charge_input(delta: float) -> void:
	if is_charging:
		charge_time += delta

func handle_landing() -> void:
	if is_on_floor() and velocity.y >= 0:
		current_state = STATE_IDLE if velocity.x == 0 else STATE_WALK

func start_dodge() -> void:
	is_dodging = true
	dodge_cooldown_timer = dodge_cooldown
	current_state = STATE_DODGE
	
	var dodge_dir = facing_direction
	if keys_pressed["left"]:
		dodge_dir = -1
	elif keys_pressed["right"]:
		dodge_dir = 1
	
	var target_pos = global_position + Vector2(dodge_distance * dodge_dir, 0)
	var tween = create_tween()
	tween.tween_property(self, "global_position:x", target_pos.x, dodge_duration)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	
	modulate.a = 0.5
	
	await get_tree().create_timer(dodge_duration).timeout
	modulate.a = 1.0
	is_dodging = false
	
	if is_on_floor():
		current_state = STATE_IDLE
	else:
		current_state = STATE_FALL

func execute_normal_attack() -> void:
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	current_state = STATE_ATTACK
	
	attack_hitbox.monitoring = true
	attack_hit_history.clear()
	
	anim_player.play("attack")
	
	await get_tree().create_timer(0.3).timeout
	attack_hitbox.monitoring = false
	is_attacking = false
	
	if is_on_floor():
		current_state = STATE_IDLE
	else:
		current_state = STATE_FALL

func start_charge() -> void:
	is_charging = true
	charge_time = 0.0
	current_state = STATE_CHARGE
	anim_player.play("charge")

func release_charged_attack() -> void:
	is_charging = false
	is_attacking = true
	charged_attack_cooldown_timer = charged_attack_cooldown
	
	var charge_ratio = mini(charge_time / charged_time, 1.0)
	var damage = int(lerp(float(charged_attack_min_damage), float(charged_attack_max_damage), charge_ratio))
	damage = GameState.get_attack_damage(damage)
	
	attack_hitbox.monitoring = true
	attack_hit_history.clear()
	
	anim_player.play("charged_attack")
	
	await get_tree().create_timer(0.4).timeout
	attack_hitbox.monitoring = false
	is_attacking = false
	
	if is_on_floor():
		current_state = STATE_IDLE
	else:
		current_state = STATE_FALL

func update_animation() -> void:
	if is_attacking or is_charging or is_dodging:
		return
	
	match current_state:
		STATE_IDLE:
			anim_player.play("idle")
		STATE_WALK:
			anim_player.play("walk")
		STATE_JUMP:
			anim_player.play("jump_up")
		STATE_FALL:
			anim_player.play("fall")
		STATE_HURT:
			anim_player.play("hurt")

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

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if GameState.has_shield or current_state == STATE_DODGE:
		return
	
	GameState.player_current_hp -= amount
	current_state = STATE_HURT
	hurt_timer = 0.3
	
	velocity = knockback
	move_and_slide()
	
	anim_player.play("hurt")
	
	if GameState.player_current_hp <= 0:
		GameState.player_current_hp = 0
		die()

func die() -> void:
	current_state = STATE_DEAD
	anim_player.play("death")
	GameState.state = GameState.GAME_OVER

func heal(amount: int) -> void:
	GameState.heal(amount)

func get_facing_direction() -> int:
	return facing_direction

func is_on_ground() -> bool:
	return is_on_floor()