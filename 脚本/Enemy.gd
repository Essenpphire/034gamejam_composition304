# Enemy.gd
extends Entity

@onready var HurtCD : Timer = $HurtCD
@onready var AttackCD : Timer = $AttackCD

# var Mdt = MeshDataTool.new()
var target : Node2D = null
var target_in_range : bool = false
var can_attack : bool = true
## 1朝右
var facing : int = 1

## @override 重定义数值
func _init() -> void:
	SPEED = 100.0
	STYLE.hurtdot_normal = Color.GOLD

## @override 就绪
func _ready() -> void:
	Sword = $PinJoint2D/Sword
	## 关节角度限制是核心，朝右-20 30 朝左-130 20
	Joint = $PinJoint2D
	super._ready()
	HurtDot0.body_entered.connect(_on_hitdot_body_entered.bind(0))
	HurtDot0.body_exited.connect(_on_hitdot_body_exited.bind(0))
	HurtDot1.body_entered.connect(_on_hitdot_body_entered.bind(1))
	HurtDot1.body_exited.connect(_on_hitdot_body_exited.bind(1))
	Sword.add_to_group("EnemySword")
	
## @override
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
## @override 自动索敌
func handleMove() -> void:
	# 敌人直接摔死
	if self.position.y > 800:
		queue_free()
		return	
		
	if not self.is_on_floor():
		return
		
	if target == null:
		self.transform.x = Vector2(facing, 0)
		self.velocity.x = move_toward(self.velocity.x, 0, 1)
		return
		
	# 发现目标
	var s = (target.global_position - self.global_position).normalized()
	facing = 1 if s.x > 0 else -1
	
	# 这就解决朝向问题了
	self.transform.x = Vector2(facing, 0)
	create_tween().tween_property(Body, "transform:x", Vector2(facing, 0), 0.2)
	$Body/RayCast2D.position.x = facing * 30
	
	print($Body/RayCast2D.is_colliding())
	
	if $Body/RayCast2D.is_colliding():
		## 看到人才能追逐，16为垂直阈值
			if abs(self.position.y - target.position.y) < 16:
				self.velocity.x = facing * SPEED
	else:
		# 急停
		print("停下！！！")
		self.velocity.x = move_toward(self.velocity.x, 0, 30)
		print(velocity)

	if facing == 1.0:
		Joint.angular_limit_upper = deg_to_rad(60)
		Joint.angular_limit_lower = deg_to_rad(-60)
	elif facing == -1.0:
		Joint.angular_limit_upper = deg_to_rad(60)
		Joint.angular_limit_lower = deg_to_rad(-60)
	Sword.apply_torque(facing * 5000)
		
		
## 敌人攻击
func handleAttack() -> void:
	if target and can_attack and target_in_range:
		can_attack = false
		AttackCD.start()
		# 调小转动惯量，方便斩击
		Sword.inertia = 10.0
		Joint.angular_limit_enabled = false
		# 1. 蓄力感
		Sword.apply_torque(-facing * 100000)
		await GameManager.wait(0.3)
		
		# 2. 主打击 + 停顿
		Sword.apply_torque(facing * 30000)
		Sword.linear_velocity.x += facing * 30

## 判定点回调 - 剑砍入
func _on_hitdot_body_entered(body : Node2D, idx : int) -> void:
	if body.is_in_group("PlayerSword"):
		print("我被砍了")
		print(hurtdot_queue)
		hurtdot_queue[idx] = 1
		if hurtdot_queue[0] && hurtdot_queue[1]:
			commitDie()
		
## 判定点回调 - 剑离开
func _on_hitdot_body_exited(body : Node2D, idx : int) -> void:
	if body.is_in_group("PlayerSword"):
		HurtCD.start()

## 受伤间隔定时器
func _on_hurt_cd_timeout() -> void:
	#hurtdot_queue.resize(2)
	if not is_dead:
		hurtdot_queue.fill(0)

## 攻击冷却定时器
func _on_attack_cd_timeout() -> void:
	Joint.angular_limit_enabled = true
	can_attack = true

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body
		
func _on_detection_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = null

func _on_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_in_range = true

func _on_attack_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_in_range = false

func _on_death_particle_finished() -> void:
	self.queue_free()
