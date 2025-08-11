@tool
extends EditorPlugin

const RiveRuntimePanel = preload("res://addons/rive_runtime_loader/rive_runtime_panel.gd")

var runtime_panel_instance

func _enter_tree():
	print("[RiveRuntimeLoader] Plugin enabled")

func _exit_tree():
	print("[RiveRuntimeLoader] Plugin disabled")

func _has_main_screen():
	return false

func _get_plugin_name():
	return "Rive Runtime Loader"
