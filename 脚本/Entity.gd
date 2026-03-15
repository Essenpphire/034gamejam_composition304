extends CharacterBody2D
class_name Entity

@onready var Body : Node2D = $Body
@onready var Collision : CollisionPolygon2D = $Collision
@onready var MeshIns : MeshInstance2D = $Body/MeshInstance2D
@onready var HurtDot0 : Area2D = $Body/HurtDot0
@onready var HurtDot1 : Area2D = $Body/HurtDot1
@onready var Sword : RigidBody2D = $PinJoint2D/Sword
## 关节角度限制是核心，朝右-20 30 朝左-130 20
@onready var Joint : PinJoint2D = $PinJoint2D

var SPEED : float = 300.0
var JUMP_VELOCITY = -400.0
var STYLE : Dictionary = {
	hurtdot_normal = Color.ORANGE_RED,
	hurtdot_hurt = Color.GRAY
}
var hurtdot_queue : Array = [0, 0]
## 不要显示修改is_dead，改用commitDie
var is_dead : bool = false
var prev_on_floor : bool = true

## 基于三角网格的随机采样
## @todo 添加距离阈值
func getRandomPoint() -> Vector2:
	var vertex : PackedVector2Array = Collision.polygon
	var n : int = vertex.size() / 3
	var x : int = randi() % n * 3
	var p0 = vertex[x]
	var p1 = vertex[x + 1]
	var p2 = vertex[x + 2]
	# 使用重心坐标方法（均匀分布）
	var r1 : float = sqrt(randf_range(0, 1))
	var r2 : float = randf_range(0, 1)
	
	var point : Vector2 = (1 - r1) * p0 + \
				r1 * (1 - r2) * p1 + \
				r1 * r2 * p2
	return point

## 触发死亡函数
func commitDie() -> void:
	if is_dead:
		return
	is_dead = true
	# 关节解绑
	Joint.node_a = "" 
	# 剑落地
	Sword.set_deferred("freeze", false)
	Sword.gravity_scale = 1.0
	Sword.apply_force(get_gravity())
	# 拜拜碰撞
	Collision.queue_free()
	# 死亡特效，Particle和慢动作是对的
	Engine.time_scale = 0.1
	$DeathParticle.emitting = true
	# 清点
	queue_redraw()
	var _dead_tween = create_tween()
	_dead_tween.tween_property(Body, "modulate:a", 0, 0.1)
	Engine.time_scale = 1.0

## 落地回调函数
func handleHitFloor() -> void:
	pass

## 就绪
func _ready() -> void:
	$DeathParticle.emitting = false
	MeshIns.z_index = -1
	HurtDot0.position = getRandomPoint()
	HurtDot1.position = getRandomPoint()

## 绘图虚函数
func _draw() -> void:
	if is_dead:
		return
	if hurtdot_queue[0]:
		draw_circle(HurtDot0.position, 1, STYLE.hurtdot_hurt)
	else:
		draw_circle(HurtDot0.position, 1, STYLE.hurtdot_normal)
	if hurtdot_queue[1]:
		draw_circle(HurtDot1.position, 1, STYLE.hurtdot_hurt)
	else:
		draw_circle(HurtDot1.position, 1, STYLE.hurtdot_normal)
	if hurtdot_queue[0] && hurtdot_queue[1]:
		draw_line(HurtDot0.position, HurtDot1.position, STYLE.hurtdot_hurt, 2.0)


## 物理帧更新
func _physics_process(delta: float) -> void:
	if prev_on_floor != is_on_floor() and is_on_floor():
		print(self.name + "落地！") # do sth...
		handleHitFloor()
	prev_on_floor = is_on_floor()
	if not is_on_floor():
		velocity += get_gravity() * delta
	if not is_dead:
		handleMove()
		handleAttack()
		move_and_slide()
		queue_redraw()

## 实体移动函数
func handleMove() -> void:
	if self.position.y > 800:
		commitDie()
		return	

## 实体攻击虚函数
func handleAttack() -> void:
	pass

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		#print(event)
