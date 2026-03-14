#extends Node2D

#@onready var Player : CharacterBody2D = $Player
#@onready var Ball : PhysicsBody2D = $Ball
#@onready var Spring : DampedSpringJoint2D = $DampedSpringJoint2D
#
### 弹簧失效阈值
#@export var spring_muda_thres : float = 64.0
#
### 弹簧场景
##const SPRING_SCENE : PackedScene = preload("res://场景/Spring.tscn")
#
#var spring_dist : float = 0.0
#
#func _ready() -> void:
	#pass
#
#func _draw() -> void:
	#if Player and Ball:
		#if spring_dist > spring_muda_thres:
			#draw_line(Player.position, Ball.position, Color.WHITE, 0.5, true)
		#else:
			#draw_line(Player.position, Ball.position, Color.RED, 0.5, true)
#
#func _physics_process(delta: float) -> void:
	#if Player and Ball:
		#spring_dist = (Player.position - Ball.position).length()
		#if spring_dist <= spring_muda_thres:
			#Spring.node_b = ""
		#else:
			#Spring.node_b = "../Ball"
	#
	#queue_redraw()
