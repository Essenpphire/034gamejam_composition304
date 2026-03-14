extends RigidBody2D

# 敌人状态枚举
enum EnemyState {
	IDLE,   # 待机：不移动
	ATTACK, # 进攻：接近玩家
	FLEE    # 逃离：远离玩家
}

# 可调参数（在编辑器中可见）
@export var move_speed: float = 200.0          # 移动速度
@export var attack_range: float = 150.0        # 进攻范围（进入此范围开始攻击）
@export var flee_range: float = 100.0          # 逃离触发距离（玩家过近时逃离）
@export var idle_range: float = 300.0          # 待机范围（超出此距离且未进攻时待机）
@export var rotation_strength: float = 5.0     # 扶正扭矩强度
@export var fall_angle_threshold: float = 60.0 # 摔倒角度阈值（度）
@export var ray_count: int = 5                  # 避障射线数量
@export var ray_length: float = 50.0            # 射线长度
@export var avoidance_weight: float = 1.5       # 避障权重

# 内部变量
var current_state: EnemyState = EnemyState.IDLE
var player: Node2D = null                       # 玩家节点引用
var is_fallen: bool = false                      # 是否处于倒地状态
var previous_state: EnemyState = EnemyState.IDLE # 用于倒地后恢复

# 射线方向缓存
var ray_directions: PackedVector2Array = []

func _ready():
	# 尝试通过组获取玩家（假设玩家节点在"player"组）
	player = get_tree().get_first_node_in_group("Player")
	if player == null:
		push_warning("未找到玩家，请确保玩家节点加入了 'Player' 组")
	
	# 生成射线方向（左右对称，覆盖前方扇形）
	for i in range(ray_count):
		var angle = deg_to_rad(lerp(-45.0, 45.0, float(i) / (ray_count - 1)))
		ray_directions.append(Vector2.RIGHT.rotated(angle))

func _integrate_forces(state: PhysicsDirectBodyState2D):
	if player == null:
		return
	
	# 1. 摔倒检测与扶正
	check_and_handle_fall(state)
	
	# 2. 如果处于摔倒状态，只进行扶正，不移动
	if is_fallen:
		return
	
	# 3. 状态切换逻辑
	var dist = global_position.distance_to(player.global_position)
	update_state_based_on_distance(dist)
	
	# 4. 根据状态计算期望移动方向
	var desired_velocity = Vector2.ZERO
	match current_state:
		EnemyState.ATTACK:
			desired_velocity = seek_player() * move_speed
		EnemyState.FLEE:
			desired_velocity = flee_from_player() * move_speed
		EnemyState.IDLE:
			desired_velocity = Vector2.ZERO
	
	# 5. 直接设置刚体线速度（保留物理碰撞效果）
	state.linear_velocity = desired_velocity

# 根据距离更新状态
func update_state_based_on_distance(dist: float):
	match current_state:
		EnemyState.IDLE:
			if dist <= attack_range:
				change_state(EnemyState.ATTACK)
		EnemyState.ATTACK:
			if dist > attack_range * 1.2:  # 稍微滞后避免频繁切换
				change_state(EnemyState.IDLE)
			elif dist <= flee_range:        # 玩家太近时逃离（模拟恐惧）
				change_state(EnemyState.FLEE)
		EnemyState.FLEE:
			if dist > flee_range * 1.5:
				change_state(EnemyState.IDLE)

func change_state(new_state: EnemyState):
	if current_state != new_state:
		current_state = new_state
		# 可在此添加状态进入/退出效果（如动画、声音）

# 接近玩家（带避障）
func seek_player() -> Vector2:
	var to_player = (player.global_position - global_position).normalized()
	return avoid_obstacles(to_player)

# 远离玩家（带避障）
func flee_from_player() -> Vector2:
	var away = (global_position - player.global_position).normalized()
	return avoid_obstacles(away)

# 简单避障：用多个射线检测前方，避开障碍物
func avoid_obstacles(base_dir: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var total_weight = 0.0
	var avoidance_dir = Vector2.ZERO
	
	# 在 base_dir 周围发射射线
	for direction in ray_directions:
		var rotated_dir = base_dir.rotated(direction.angle())  # 实际应为相对方向，这里简化：射线围绕 base_dir 旋转
		# 更准确的方法：以 base_dir 为基准，使用 ray_directions 作为偏移
		# 但我们简单将 ray_directions 视为世界方向，需要旋转对齐 base_dir
		var world_dir = base_dir.rotated(direction.angle())
		
		var query = PhysicsRayQueryParameters2D.create(global_position, global_position + world_dir * ray_length)
		query.exclude = [self]  # 排除自身
		var result = space_state.intersect_ray(query)
		
		var weight = 1.0
		if result:
			# 有障碍物：根据距离调整权重，越近权重越大
			var dist = global_position.distance_to(result.position)
			weight = 1.0 - clamp(dist / ray_length, 0.0, 1.0)
			# 避开方向为垂直于障碍物方向的侧向（简单处理：向射线垂直方向移动）
			var normal = result.normal
			var avoid = normal.rotated(deg_to_rad(90))  # 沿障碍物切线方向
			avoidance_dir += avoid * weight
		else:
			# 无障碍物：鼓励朝该方向移动
			avoidance_dir += world_dir * 0.2  # 轻微偏向原方向
		total_weight += weight
	
	if total_weight > 0:
		avoidance_dir /= total_weight
		avoidance_dir = avoidance_dir.normalized()
		# 混合原始方向和避障方向
		return (base_dir + avoidance_dir * avoidance_weight).normalized()
	else:
		return base_dir

# 摔倒检测与扶正
func check_and_handle_fall(state: PhysicsDirectBodyState2D):
	var angle_deg = abs(rotation_degrees)  # 取绝对值，不考虑方向
	var fall_threshold = fall_angle_threshold
	
	if not is_fallen and angle_deg > fall_threshold:
		# 刚摔倒，记录之前状态并进入倒地状态
		is_fallen = true
		previous_state = current_state
		# 可选：添加倒地动画/效果
		print("敌人摔倒了！")
	
	if is_fallen:
		# 应用扭矩扶正：向旋转方向的反方向施加扭矩
		# 期望角度为 0（或原始角度），当前角度为 rotation
		var current_angle = rotation
		# 计算最短旋转方向
		var target_angle = 0.0
		var angle_diff = wrapf(target_angle - current_angle, -PI, PI)
		
		# 施加扭矩使其回正
		state.apply_torque_impulse(angle_diff * rotation_strength * state.inverse_inertia)
		
		# 如果已经接近水平（角度小于阈值），认为起身完成
		if abs(rotation_degrees) < fall_threshold * 0.5:
			is_fallen = false
			current_state = previous_state  # 恢复之前状态
			print("敌人站起来了！")
