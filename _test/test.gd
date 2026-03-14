extends RigidBody2D

func _physics_process(_delta: float) -> void:
	self.position = get_local_mouse_position()


func _on_body_entered(body: Node) -> void:
	print(body)
