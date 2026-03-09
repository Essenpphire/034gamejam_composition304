# Sword.gd
# 说明剑刃在攻击层，剑身在物理层
extends RigidBody2D

#@onready var MeshIns : MeshInstance2D = $MeshInstance2D

func _ready() -> void:
	self.add_to_group("Sword")
