extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _ready() -> void:
	# 开启斜坡滑动
	self.floor_stop_on_slope = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	#if not is_on_floor():
	velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
 
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if self.position.y > 1000.0:
		self.position.y = -200.9
		self.velocity.y = 0.9

	move_and_slide()
	# 遍历本次移动产生的所有碰撞
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# 检查碰撞对象是否是一个刚体
		if collider is RigidBody2D:
			# 计算推力方向（从碰撞点指向角色，或者用碰撞法线）
			var push_direction = -collision.get_normal()
			# 对刚体施加一个中心冲量，把它推开
			collider.apply_central_impulse(push_direction * 10)
