# Player.gd
extends Entity

@onready var Sword : RigidBody2D = $PinJoint2D/Sword
@onready var Joint : PinJoint2D = $PinJoint2D
@onready var AttackCD : Timer = $AttackCD

var can_attack : bool = true
## 1.0朝向右边
var facing : int = 1

## @override 玩家移动
func handleMove() -> void:
	var direction := Input.get_axis("向左移动", "向右移动")
	if direction:
		facing = 1 if direction < 0 else -1
		self.transform.x = Vector2(direction, 0)
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if Input.is_action_just_pressed("跳跃") and self.is_on_floor():
		velocity.y = JUMP_VELOCITY

## 玩家攻击
func handleAttack() -> void:
	if Input.is_action_just_pressed("攻击") and can_attack:
		can_attack = false
		print("攻击！")
		# 创建补间
		var tween : Tween = create_tween()
		# 阶段1：向前刺出 (0.1秒)
		tween.tween_property(Joint, "rotation_degrees", 90 * facing, 0.1)
		tween.tween_property(Joint, "rotation_degrees", 24 * facing, 0.1)
		tween.tween_callback(func(): can_attack = true)
		
		#Sword.rotate(PI / 6)
		#AttackCD.start()
		#can_attack = false
		#await get_tree().create_timer(0.1).timeout
		#Sword.rotate(-PI / 6)

## 节点就绪
func _ready() -> void:
	self.add_to_group("Player")

## @override 物理帧更新
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	handleAttack()

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		#print(event)

func _on_attack_cd_timeout() -> void:
	pass
	#can_attack = true
