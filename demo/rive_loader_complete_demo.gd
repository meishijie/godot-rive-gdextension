extends Control

# 完整的Rive加载器演示
# 展示如何使用Rive Runtime Loader addon的所有功能

@onready var rive_viewer: RiveViewer = $HBox/ViewerContainer/RiveViewer
@onready var runtime_panel = $HBox/RiveRuntimePanel
@onready var hotkey_controller = $RiveHotkeyController
@onready var status_label: Label = $HBox/ViewerContainer/StatusLabel
@onready var help_label: Label = $HelpLabel

# 加载器管理器引用
var loader_manager: Node

func _ready():
	print("[RiveLoaderCompleteDemo] Complete demo scene ready")

	# 获取或创建加载器管理器
	loader_manager = get_node_or_null("/root/RiveLoaderManager")
	if not loader_manager:
		loader_manager = preload("res://addons/rive_runtime_loader/rive_loader_manager.gd").new()
		loader_manager.name = "RiveLoaderManager"
		get_tree().root.call_deferred("add_child", loader_manager)

	# 自动扫描examples目录
	loader_manager.auto_scan_examples()

	# 连接信号
	loader_manager.file_loaded.connect(_on_file_loaded)
	loader_manager.file_load_failed.connect(_on_file_load_failed)

	# 设置热键控制器的目标
	hotkey_controller.target_rive_viewer = rive_viewer

	# 显示帮助信息
	update_help_text()

	# 延迟加载默认文件
	call_deferred("_load_default_file")

func _load_default_file():
	if rive_viewer and loader_manager:
		await loader_manager.load_preset_file(rive_viewer, 0)
	update_status()

func _on_file_loaded(_viewer: RiveViewer, file_path: String):
	print("[RiveLoaderCompleteDemo] File loaded: ", file_path)
	update_status()

func _on_file_load_failed(_viewer: RiveViewer, _file_path: String, error: String):
	print("[RiveLoaderCompleteDemo] File load failed: ", error)
	status_label.text = "加载失败: " + error

func update_status():
	if not rive_viewer or not loader_manager:
		return
	
	var info = loader_manager.get_viewer_info(rive_viewer)
	var status_text = ""
	
	# 文件信息
	var file_name = info.file_path.get_file() if info.file_path != "" else "未加载"
	status_text += "文件: %s\n" % file_name
	
	# 播放状态
	status_text += "状态: %s\n" % ("暂停" if info.paused else "播放")
	
	# 场景和动画信息
	if info.has_artboard:
		status_text += "场景: %d/%d\n" % [info.scene, info.scene_count]
		status_text += "动画: %d/%d\n" % [info.animation, info.animation_count]
		status_text += "输入: %d个" % info.input_count
	else:
		status_text += "未加载有效的artboard"
	
	status_label.text = status_text

func update_help_text():
	var help_text = """快捷键帮助:
F1 - 切换控制面板
F2/F3 - 下一个/上一个文件
F4 - 重新加载文件
空格 - 暂停/播放
R - 重置动画
1-5 - 加载预设文件
←→ - 切换动画
↑↓ - 切换场景
ESC - 退出"""
	
	help_label.text = help_text

func _process(_delta):
	# 定期更新状态
	if Engine.get_process_frames() % 60 == 0:  # 每秒更新一次
		update_status()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_H:
				# 切换帮助显示
				help_label.visible = !help_label.visible
