# GameManager.gd
extends Node
	
var UI_TUTORIAL_SCENE : PackedScene = preload("res://场景/ui_tutorial.tscn")	
var UI_RESPAWN_SCENE : PackedScene = preload("res://场景/ui_respawn.tscn")	

var is_tutor_op_played : bool = false
var is_tutor_death_played : bool = false
var is_game_start : bool = false
var scene_changing : bool = false
var scene_curr : String = "StartScene"

signal game_start
signal game_camera_shake(amout : float, rot: float) # 相机抖动

"""函数"""
## 改变当前场景
func changeScene(scene : String) -> void:
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
func gameStart() -> void:
	is_game_start = true
	game_start.emit()

## @param amout 建议数值范围：0.0 ~ 10.0
## @param rot 
func cameraShake(amout : float) -> void:
	game_camera_shake.emit(amout)
