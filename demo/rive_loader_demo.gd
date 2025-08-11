extends Control

@onready var rive_viewer: RiveViewer = $HBox/RiveViewer
@onready var runtime_panel = $HBox/RiveRuntimePanel

func _ready():
	print("[RiveLoaderDemo] Demo scene ready")
	
	# 设置默认的riv文件
	if rive_viewer:
		rive_viewer.file_path = "res://examples/juice.riv"

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				# 切换面板可见性
				runtime_panel.visible = !runtime_panel.visible
				print("[RiveLoaderDemo] Runtime panel visibility: ", runtime_panel.visible)
			KEY_ESCAPE:
				get_tree().quit()
