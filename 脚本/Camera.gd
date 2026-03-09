extends Camera2D

func _process(delta: float) -> void:
	self.global_position = self.global_position.lerp(get_parent().global_position, delta * 3)
