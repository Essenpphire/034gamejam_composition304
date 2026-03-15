# GameManager.gd
extends Node
	
var UI_TUTORIAL_SCENE : PackedScene = preload("res://场景/ui_tutorial.tscn")	
var UI_RESPAWN_SCENE : PackedScene = preload("res://场景/ui_respawn.tscn")	
const SAVE_PATH = "user://game.save"

var is_tutor_op_played : bool = false
var is_tutor_death_played : bool = false
#var is_game_start : bool = false
var is_endless_unlocked : bool = false

var scene_changing : bool = false
var scene_curr : String = "StartScene"

signal game_start
signal game_camera_shake(amout : float, rot: float) # 相机抖动
signal battle_player_dead

"""函数"""
# 再封装
func wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds).timeout

# 文件读写函数
func saveGame() -> void:
	print("保存游戏: ", SAVE_PATH)
	
	# 准备数据
	var data = {
		"is_tutor_op_played": is_tutor_op_played,
		"is_tutor_death_played": is_tutor_death_played,
		"is_endless_unlocked": is_endless_unlocked
	}
	
	# 确保目录存在
	var dir = SAVE_PATH.get_base_dir()
	if dir and not DirAccess.dir_exists_absolute(dir):
		var err = DirAccess.make_dir_recursive_absolute(dir)
		if err != OK:
			push_error("无法创建保存目录: ", dir)
			return
	
	# 保存文件
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("无法打开文件: ", SAVE_PATH)
		return
	
	var json_string = JSON.stringify(data)
	file.store_string(json_string)
	file.close()
	
	print("游戏保存成功!  ")

func loadGame() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		var data = JSON.parse_string(json_data) as Dictionary
		file.close()
		
		is_tutor_op_played = data["is_tutor_op_played"]
		is_tutor_death_played = data["is_tutor_death_played"]
		is_endless_unlocked = data["is_endless_unlocked"]


## 改变当前场景
func changeScene(scene : String) -> void:
	saveGame()
	print("正在切换场景：" + scene)
	scene_changing = true
	var res = get_tree().change_scene_to_file(scene)
	if res == OK:
		scene_curr = scene
		scene_changing = false
		print("场景切换成功")
	else:
		print("场景切换失败！")

## 游戏开始
#func gameStart() -> void:
	#is_game_start = true
	#game_start.emit()

## @param amout 建议数值范围：0.0 ~ 10.0
## @param rot 
func cameraShake(amout : float) -> void:
	game_camera_shake.emit(amout)
