# Enemy.gd
extends Entity

@onready var MeshIns : MeshInstance2D = $MeshInstance2D
@onready var Collison : CollisionPolygon2D = $CollisionPolygon2D
@onready var HurtDot0 : Area2D = $HurtDot0
@onready var HurtDot1 : Area2D = $HurtDot1

# var Mdt = MeshDataTool.new()
var target : Node2D = null
var hitdot_queue : Array = [0, 0]

## @override 自动索敌
func handleMove() -> void:
	if target != null:
		var target_pos : Vector2 = target.position

## 基于三角网格的随机采样
## @todo 添加距离阈值
func getRandomPoint() -> Vector2:
	var tr_vertex : PackedVector2Array = Collison.polygon
	var n : int = tr_vertex.size() / 3
	var x : int = randi() % n * 3
	var p0 = tr_vertex[x]
	var p1 = tr_vertex[x + 1]
	var p2 = tr_vertex[x + 2]
	# 使用重心坐标方法（均匀分布）
	var r1 : float = sqrt(randf_range(0, 1))
	var r2 : float = randf_range(0, 1)
	
	var point : Vector2 = (1 - r1) * p0 + \
				r1 * (1 - r2) * p1 + \
				r1 * r2 * p2
	return point

func _ready() -> void:
	HurtDot0.position = getRandomPoint()
	HurtDot0.body_entered.connect(_on_hitdot_body_entered.bind(0))
	HurtDot0.body_exited.connect(_on_hitdot_body_exited.bind(0))
	
	HurtDot1.position = getRandomPoint()
	HurtDot1.body_entered.connect(_on_hitdot_body_entered.bind(1))
	HurtDot1.body_exited.connect(_on_hitdot_body_exited.bind(1))

## 判定点回调 - 剑砍入
func _on_hitdot_body_entered(body : Node2D, idx : int) -> void:
	if body.is_in_group("Sword"):
		print(hitdot_queue)
		hitdot_queue[idx] = 1
		if hitdot_queue[0] && hitdot_queue[1]:
			print("awsl")
			self.queue_free()
		
## 判定点回调 - 剑离开
func _on_hitdot_body_exited(body : Node2D, idx : int) -> void:
	if body.is_in_group("Sword"):
		hitdot_queue[idx] = 0

func _draw() -> void:
	draw_circle(HurtDot0.position, 1, Color.RED)
	draw_circle(HurtDot1.position, 1, Color.RED)

## @override
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	queue_redraw()

func _on_area_2d_body_entered(body: Node2D) -> void:
	target = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	target = null
