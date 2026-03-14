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
	if target != null:
		## 敌人和玩家在同一水平线上
		if abs(self.position.y - target.position.y) < 16:
			var s = (target.global_position - self.global_position).normalized()
			facing = 1 if s.x > 0 else -1
			self.transform.x = Vector2(facing, 0)
			self.velocity.x = facing * SPEED
	else:
		self.transform.x = Vector2(facing, 0)
		self.velocity.x = move_toward(self.velocity.x, 0, 1)
		
## 敌人攻击
func handleAttack() -> void:
	if target and can_attack and target_in_range:
		can_attack = false
		AttackCD.start()
		# 创建补间
		var tween : Tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(Joint, "rotation_degrees", -90, 0.1)
		tween.tween_property(Joint, "rotation_degrees", 180, 0.1)
		tween.tween_property(Joint, "rotation_degrees", 60, 0.1)
		tween.tween_callback(func(): can_attack = false)

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
		print("计时开始")
		HurtCD.start()

## 受伤间隔定时器
func _on_hurt_cd_timeout() -> void:
	#hurtdot_queue.resize(2)
	if not is_dead:
		hurtdot_queue.fill(0)

## 攻击冷却定时器
func _on_attack_cd_timeout() -> void:
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
