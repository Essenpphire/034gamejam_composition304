# Player.gd
extends Entity

@onready var Sword : RigidBody2D = $PinJoint2D/Sword
@onready var Joint : PinJoint2D = $PinJoint2D
@onready var HurtCD : Timer = $HurtCD
@onready var AttackCD : Timer = $AttackCD

var FULL_HP : float = 3
var HP : float
var is_hurting : bool = false
var can_attack : bool = true

## @override 玩家移动
func handleMove() -> void:
	var direction := Input.get_axis("向左移动", "向右移动")
	if direction:
		# 这就解决朝向问题了
		self.transform.x = Vector2(direction, 0)
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if self.is_on_floor():
		if Input.is_action_just_pressed("跳跃"):
			velocity.y = JUMP_VELOCITY
		#Sword.freeze = false
	#else:
		#Sword.freeze = true

## @override 玩家攻击
func handleAttack() -> void:
	if Input.is_action_just_pressed("攻击") and can_attack:
		can_attack = false
		print("攻击！")
		# 创建补间
		var tween : Tween = create_tween()
		# 阶段1：向前刺出 (0.1秒)
		tween.set_ease(Tween.EASE_IN_OUT)
		# tween.set_trans(Tween.TRANS_SPRING)
		tween.tween_property(Joint, "rotation_degrees", -90, 0.1)
		tween.tween_property(Joint, "rotation_degrees", 180, 0.1)
		tween.tween_property(Joint, "rotation_degrees", 60, 0.1)
		tween.tween_callback(func(): can_attack = true)

## 判定点回调 - 剑砍入
func _on_hitdot_body_entered(body : Node2D, idx : int) -> void:
	if body.is_in_group("EnemySword"):
		hurtdot_queue[idx] = 1
		if hurtdot_queue[0] && hurtdot_queue[1] and is_hurting:
			HP -= 1
			is_hurting = false
			
		if HP <= 0:
			is_dead = true
			self.transform.x = Vector2(1, 0)
			Sword.freeze = false
			await get_tree().create_timer(1.0).timeout
			self.queue_free()
		
## 判定点回调 - 剑离开
func _on_hitdot_body_exited(body : Node2D, idx : int) -> void:
	if body.is_in_group("EnemySword"):
		HurtCD.start()

## 节点就绪
func _ready() -> void:
	super._ready()
	HP = FULL_HP
	HurtDot0.body_entered.connect(_on_hitdot_body_entered.bind(0))
	HurtDot0.body_exited.connect(_on_hitdot_body_exited.bind(0))
	HurtDot1.body_entered.connect(_on_hitdot_body_entered.bind(1))
	HurtDot1.body_exited.connect(_on_hitdot_body_exited.bind(1))
	self.add_to_group("Player")
	Sword.add_to_group("PlayerSword")

## @override 物理帧更新
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	MeshIns.modulate.a = HP / FULL_HP

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		#print(event)

func _on_attack_cd_timeout() -> void:
	pass
	#can_attack = true

func _on_hurt_cd_timeout() -> void:
	if not is_dead:
		is_hurting = true
		hurtdot_queue.fill(0)
