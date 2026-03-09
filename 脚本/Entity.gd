extends CharacterBody2D
class_name Entity

const SPEED : float = 300.0
const JUMP_VELOCITY = -400.0

## 实体移动函数
func handleMove() -> void:
	pass

## 物理帧更新函数
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	handleMove()
	move_and_slide()

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		#print(event)
