# Sword.gd
# 说明剑刃在攻击层，剑身在物理层
extends RigidBody2D

@onready var SwordBody : CollisionShape2D = $SwordBody
#@onready var MeshIns : MeshInstance2D = $MeshInstance2D

func _ready() -> void:
	self.contact_monitor = true
	self.max_contacts_reported = 1
	#self.add_to_group("Sword")

func _physics_process(delta: float) -> void:
	pass
