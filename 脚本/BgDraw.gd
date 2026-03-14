# AIGC by deepseek.
extends Node2D

# ---------- 可调节参数（支持自定义绘制区域）----------
@export var custom_area: Rect2 = Rect2(0, 0, 2000, 3000)  # 自定义绘制区域（坐标和尺寸）

# 聚集参数
@export var cluster_center: Vector2 = Vector2(600, 600) : set = _request_redraw   # 聚集中心点
@export var cluster_radius: float = 500.0                 : set = _request_redraw   # 聚集半径

# 漂移动画参数
@export var drift_speed: float = 0.2                      # 漂移速度
@export var drift_amplitude: float = 100.0                 # 最大漂移幅度

@export var shape_count: int = 30  : set = _request_redraw
@export var line_count: int = 20   : set = _request_redraw
@export var dot_count: int = 30    : set = _request_redraw
@export var color_palette: Array[Color] = [
	Color(0.7216, 0.2392, 0.1686),  # 康定斯基红
	Color(0.8980, 0.6471, 0.1412),  # 金黄色 
	Color(0.1804, 0.3529, 0.5490),  # 钴蓝色
	Color(0.9020, 0.5412, 0.2392),  # 橙色
	Color(0.1020, 0.2471, 0.4314),  # 康定斯基蓝
	Color(0.9490, 0.7804, 0.2667),  # 明黄色
	Color(0.9020, 0.5412, 0.7098),  # 玫瑰绯红
	Color(0.7725, 0.7608, 0.7098),  # 浅灰
	Color(0.1686, 0.5490, 0.4196),  # 翡翠绿
	Color(0.0392, 0.1608, 0.2471),  # 深普鲁士蓝
	Color(0.3529, 0.2431, 0.4196),  # 紫色
] : set = _request_redraw
@export var background_color: Color = Color(0.95, 0.95, 0.9)  # 米白底

# 内部缓存
var _shapes: Array[Dictionary] = []
var _lines: Array[Dictionary] = []
var _dots: Array[Dictionary] = []

# 漂移相关变量
var _drift_offset: Vector2 = Vector2.ZERO
var _drift_time: float = 0.0
var _noise: FastNoiseLite

func _init():
	# 初始化噪声（OpenSimplex 风格）
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 0.1  # 控制噪声变化频率

func _request_redraw(_val):
	queue_redraw()

func _ready():
	self.modulate.a = 0.5
	self.z_index = -1
	# 等待一帧，确保节点准备好
	await get_tree().process_frame
	regenerate()

func regenerate():
	"""重新生成所有随机元素"""
	_generate_shapes()
	_generate_lines()
	_generate_dots()
	queue_redraw()

# ---------- 位置生成函数 ----------
func _uniform_random_position(margin: float = 20) -> Vector2:
	"""均匀随机位置（用于线条）"""
	var area = custom_area
	var x = randf_range(area.position.x + margin, area.position.x + area.size.x - margin)
	var y = randf_range(area.position.y + margin, area.position.y + area.size.y - margin)
	return Vector2(x, y)

func _clustered_random_position() -> Vector2:
	"""聚集随机位置（用于形状和点）"""
	var angle = randf_range(0, 2 * PI)
	var r = randf_range(0, cluster_radius)
	return cluster_center + Vector2(cos(angle), sin(angle)) * r

# ---------- 元素生成函数 ----------
func _generate_shapes():
	_shapes.clear()
	for i in shape_count:
		var type = randi() % 3
		var pos = _clustered_random_position()   # 聚集分布
		var size_random = Vector2(randf_range(15, 100), randf_range(15, 100))
		var rotation = randf_range(0, 2 * PI)
		var color = color_palette[randi() % color_palette.size()]
		var points: PackedVector2Array = []
		if type == 1:  # 三角形
			points = _random_triangle_points(pos, size_random.length() * 0.6, rotation)
		_shapes.append({
			"type": type,
			"pos": pos,
			"size": size_random,
			"rotation": rotation,
			"color": color,
			"filled": true,
			"points": points
		})

func _random_triangle_points(center: Vector2, radius: float, rot: float) -> PackedVector2Array:
	var angles = [0, 2*PI/3, 4*PI/3]
	for i in range(3):
		angles[i] += rot + randf_range(-0.3, 0.3)
	var pts = PackedVector2Array()
	for a in angles:
		var r = radius * randf_range(0.8, 1.2)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts

func _generate_lines():
	_lines.clear()
	for i in line_count:
		var start = _uniform_random_position()   # 线条保持均匀分布
		var end = _uniform_random_position()
		var color = color_palette[randi() % color_palette.size()]
		var width = randf_range(1.0, 2.0)
		_lines.append({
			"start": start,
			"end": end,
			"color": color,
			"width": width
		})

func _generate_dots():
	_dots.clear()
	for i in dot_count:
		var pos = _clustered_random_position()   # 聚集分布
		var radius = randf_range(0.1, 1.0)
		var color = color_palette[randi() % color_palette.size()]
		_dots.append({
			"pos": pos,
			"radius": radius,
			"color": color
		})

# ---------- 漂移动画 ----------
func _process(delta):
	_drift_time += delta * drift_speed
	# 使用两个噪声通道分别控制 x 和 y 偏移（避免完全同步）
	var dx = _noise.get_noise_1d(_drift_time) * drift_amplitude
	var dy = _noise.get_noise_1d(_drift_time + 1000.0) * drift_amplitude
	_drift_offset = Vector2(dx, dy)
	queue_redraw()

# ---------- 绘制 ----------
func _draw():
	# 绘制背景（填充整个视口）
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), background_color, true)
	
	# 绘制所有元素，坐标加上漂移偏移
	for dot in _dots:
		draw_circle(dot.pos + _drift_offset, dot.radius, dot.color)
	
	for line in _lines:
		draw_line(line.start + _drift_offset, line.end + _drift_offset, line.color, line.width)
	
	for shape in _shapes:
		var offset_pos = shape["pos"] + _drift_offset
		match shape["type"]:
			0:  # 圆形
				if shape["filled"]:
					draw_circle(offset_pos, shape["size"].x * 0.5, shape["color"])
				else:
					draw_arc(offset_pos, shape["size"].x * 0.5, 0, 2*PI, 64, shape["color"], 1.0, true)
			1:  # 三角形
				# 三角形点集整体偏移
				var points = PackedVector2Array()
				for p in shape["points"]:
					points.append(p + _drift_offset)

				if shape["filled"]:
					draw_polygon(points, [shape["color"]])
				else:
					draw_polyline(points, shape["color"], 1.0, true)
			2:  # 矩形
				var rect = Rect2(offset_pos - shape["size"]/2, shape["size"])
				if shape["filled"]:
					draw_rect(rect, shape["color"], true)
				else:
					draw_rect(rect, shape["color"], false, 1.0)
