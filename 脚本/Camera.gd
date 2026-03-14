extends Camera2D

@export var shake_str : float = 0.0     # 相机抖动强度
#@export var shake_rot : float = 0.0     # 相机旋转强度
@export var shake_recover : float = 20.0 # 相机抖动回复强度
#@export var rot_recover : float = 5.0 # 相机旋转回复强度
@export var shake_time : float = 0.1    # 相机抖动时间
const ZOOM_DELTA = Vector2(0.01, 0.01)


func _ready() -> void:
	GameManager.game_camera_shake.connect(func(amount):
		shake_str = amount	
		#shake_rot = rot
	)

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("ui_down"):
		self.zoom -= ZOOM_DELTA
	elif Input.is_action_pressed("ui_up"):
		self.zoom += ZOOM_DELTA
		
	create_tween().tween_property(self, "offset", Vector2(
		randf_range(-shake_str, +shake_str),
		randf_range(-shake_str, +shake_str)
	), 0.1)
	
	shake_str = move_toward(shake_str, 0, shake_recover * delta)
