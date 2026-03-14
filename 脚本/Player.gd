# Player.gd
extends Entity

@onready var HurtCD : Timer = $HurtCD

## 玩家朝向
var facing : float = 1.0
var FULL_HP : float = 3
var HP : float
var is_hurting : bool = false
		
## 玩家复活
func handleRespawn() -> void:
	if not is_dead:
		return
	if not GameManager.is_tutor_death_played:
		get_parent().add_child(GameManager.UI_RESPAWN_SCENE.instantiate())
		
	else:
		if Input.is_action_just_pressed("跳跃"):
			print("复活吧我的爱人！")
			is_dead = false
			GameManager.is_game_start = false
			GameManager.changeScene("res://场景/StartScene.tscn")

## 玩家受伤
func receiveDamage(damage : float) -> void:
	if not is_hurting or is_dead:
		return
	self.HP -= damage
	Body.modulate.a = HP / FULL_HP
	is_hurting = false

## @override 玩家移动
func handleMove() -> void:
	super.handleMove()
	if Input.is_action_just_pressed("紫砂（调试用）"):
		print("浪费了……")
		commitDie()
		return
	
	var direction = Input.get_axis("向左移动", "向右移动")
	if direction:
		facing = direction
		# 这就解决朝向问题了
		self.transform.x = Vector2(direction, 0)
		create_tween().tween_property(Body, "transform:x", Vector2(direction, 0), 0.2)
		velocity.x = direction * SPEED
		if direction == 1.0:
			Joint.angular_limit_upper = deg_to_rad(60)
			Joint.angular_limit_lower = deg_to_rad(20)
		elif direction == -1.0:
			Joint.angular_limit_upper = deg_to_rad(-30)
			Joint.angular_limit_lower = deg_to_rad(-60)
		Sword.apply_torque(facing * 10000)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if self.is_on_floor():
		if Input.is_action_just_pressed("跳跃"):
			velocity.y = JUMP_VELOCITY

## @override 玩家攻击
# 我写的什么狗屎判断
#var _prev_col_bodies : Array = []
#var _b1 = null
#var _b2 = null

func handleAttack() -> void:
	if not Sword.get_colliding_bodies().is_empty():
		if not Sword.get_colliding_bodies()[0].is_in_group("Platform"):
			GameManager.cameraShake(10)
	#if _prev_col_bodies.is_empty():
		#_b1 = null
	#else:
		#_b1 = _prev_col_bodies[0].name
	#
	#if Sword.get_colliding_bodies().is_empty():
		#_b2 = null
	#else:
		#_b2 = Sword.get_colliding_bodies()[0].name
	#
	#if _b1 != _b2:
		#GameManager.cameraShake(10)
	#_prev_col_bodies = Sword.get_colliding_bodies()
	
	if Input.is_action_pressed("攻击"):
		#can_attack = false
		Joint.angular_limit_enabled = false
		Sword.freeze = false
		## 调小转动惯量，方便斩击
		Sword.inertia = 10.0
		"""
			# 创建补间
			var tween : Tween = create_tween()
			# 阶段1：向前刺出 (0.1秒)
			tween.set_ease(Tween.EASE_IN_OUT)
			# tween.set_trans(Tween.TRANS_SPRING)
			tween.tween_property(Joint, "rotation_degrees", -90, 0.1)
			tween.tween_property(Joint, "rotation_degrees", 180, 0.1)
			tween.tween_property(Joint, "rotation_degrees", 60, 0.1)
			#tween.tween_callback(func(): can_attack = true)
		"""
	else:
		Joint.angular_limit_enabled = true
		Sword.inertia = 100.0

## @override 落地回调函数
func handleHitFloor() -> void:
	if not GameManager.is_game_start:
		GameManager.gameStart()
		get_parent().add_child(GameManager.UI_TUTORIAL_SCENE.instantiate())
	Sword.apply_torque(facing * 5000)

## 物理模拟
func handleRigidCol() -> void:
	# 遍历本次移动产生的所有碰撞
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# 检查碰撞对象是否是一个刚体
		if collider is RigidBody2D:
			# 计算推力方向（从碰撞点指向角色，或者用碰撞法线）
			var push_direction = -collision.get_normal()
			# 对刚体施加一个中心冲量，把它推开
			collider.apply_central_impulse(push_direction * 10)

## 判定点回调 - 剑砍入
func _on_hitdot_body_entered(body : Node2D, idx : int) -> void:
	if body.is_in_group("EnemySword"):
		hurtdot_queue[idx] = 1
		if hurtdot_queue[0] && hurtdot_queue[1]:
			receiveDamage(1.0)
			if HP <= 0:
				commitDie()
				# 防止敌人鞭尸
				self.remove_from_group("Player")
		
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
	# 转动惯量
	Sword.inertia = 100.0
	Sword.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC

## @override 重绘
#func _draw() -> void:
	#super._draw()

## @override 物理帧更新
func _physics_process(delta: float) -> void:
	if is_dead:
		handleRespawn()
		return
	super._physics_process(delta)
	handleRigidCol()

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		#print(event)

func _on_hurt_cd_timeout() -> void:
	if not is_dead:
		is_hurting = true
		hurtdot_queue.fill(0)
