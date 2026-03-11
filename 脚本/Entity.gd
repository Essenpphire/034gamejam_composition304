extends CharacterBody2D
class_name Entity

@onready var MeshIns : MeshInstance2D = $MeshInstance2D
@onready var Collision : CollisionPolygon2D = $Collision
@onready var HurtDot0 : Area2D = $HurtDot0
@onready var HurtDot1 : Area2D = $HurtDot1

var SPEED : float = 300.0
var JUMP_VELOCITY = -400.0
var STYLE : Dictionary = {
	hurtdot_normal = Color.ORANGE_RED,
	hurtdot_hurt = Color.GRAY
}
var hurtdot_queue : Array = [0, 0]
var is_dead : bool = false

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

## 就绪
func _ready() -> void:
	MeshIns.z_index = -1
	HurtDot0.position = getRandomPoint()
	HurtDot1.position = getRandomPoint()

## 绘图虚函数
func _draw() -> void:
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


## 物理帧更新函数
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if not is_dead:
		handleMove()
		handleAttack()
		move_and_slide()
	queue_redraw()

## 实体移动虚函数
func handleMove() -> void:
	pass	

## 实体攻击虚函数
func handleAttack() -> void:
	pass

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		#print(event)
