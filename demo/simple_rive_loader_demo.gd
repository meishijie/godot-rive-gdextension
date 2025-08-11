extends Control

# 简化版Rive加载器演示
# 避免复杂的依赖关系，提供基本的运行时加载功能

@onready var rive_viewer: RiveViewer = $HBox/RiveViewer
@onready var file_path_edit: LineEdit = $HBox/ControlPanel/VBox/FilePathEdit
@onready var load_button: Button = $HBox/ControlPanel/VBox/LoadButton
@onready var file_list: ItemList = $HBox/ControlPanel/VBox/FileList
@onready var info_label: Label = $HBox/ControlPanel/VBox/InfoLabel
@onready var scene_spin: SpinBox = $HBox/ControlPanel/VBox/SceneHBox/SceneSpin
@onready var animation_spin: SpinBox = $HBox/ControlPanel/VBox/AnimationHBox/AnimationSpin
@onready var pause_button: Button = $HBox/ControlPanel/VBox/PauseButton

# 预设文件列表
var preset_files: Array[String] = []

func _ready():
	print("[SimpleRiveLoader] Simple demo ready")
	
	# 扫描examples目录
	scan_examples_directory()
	
	# 连接信号
	load_button.pressed.connect(_on_load_button_pressed)
	file_list.item_selected.connect(_on_file_selected)
	scene_spin.value_changed.connect(_on_scene_changed)
	animation_spin.value_changed.connect(_on_animation_changed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	
	# 设置默认值
	scene_spin.min_value = -1
	scene_spin.max_value = 10
	scene_spin.value = -1
	animation_spin.min_value = -1
	animation_spin.max_value = 20
	animation_spin.value = -1
	
	# 加载第一个文件
	if preset_files.size() > 0:
		load_file(preset_files[0])

func scan_examples_directory():
	var dir = DirAccess.open("res://examples")
	if not dir:
		print("[SimpleRiveLoader] Cannot open examples directory")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".riv"):
			var full_path = "res://examples/" + file_name
			preset_files.append(full_path)
			file_list.add_item(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("[SimpleRiveLoader] Found ", preset_files.size(), " .riv files")

func _on_load_button_pressed():
	var path = file_path_edit.text
	if path != "":
		load_file(path)

func _on_file_selected(index: int):
	if index >= 0 and index < preset_files.size():
		var path = preset_files[index]
		file_path_edit.text = path
		load_file(path)

func load_file(file_path: String):
	print("[SimpleRiveLoader] Loading: ", file_path)
	rive_viewer.file_path = file_path
	
	# 等待加载完成
	await get_tree().process_frame
	await get_tree().process_frame
	
	update_info()

func update_info():
	var artboard = rive_viewer.get_artboard()
	if not artboard:
		info_label.text = "加载失败或无效文件"
		return
	
	var scene_count = 0
	if artboard.has_method("get_scene_count"):
		scene_count = artboard.get_scene_count()
	
	var animation_count = artboard.get_animation_count()
	
	info_label.text = "场景数: %d\n动画数: %d" % [scene_count, animation_count]
	
	# 更新SpinBox范围
	scene_spin.max_value = max(scene_count - 1, 0)
	animation_spin.max_value = max(animation_count - 1, 0)

func _on_scene_changed(value: float):
	rive_viewer.scene = int(value)
	print("[SimpleRiveLoader] Scene: ", int(value))

func _on_animation_changed(value: float):
	rive_viewer.animation = int(value)
	print("[SimpleRiveLoader] Animation: ", int(value))

func _on_pause_button_pressed():
	rive_viewer.paused = !rive_viewer.paused
	pause_button.text = "播放" if rive_viewer.paused else "暂停"
	print("[SimpleRiveLoader] Paused: ", rive_viewer.paused)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F2:
				# 下一个文件
				var current_index = file_list.get_selected_items()
				if current_index.size() > 0:
					var next_index = (current_index[0] + 1) % preset_files.size()
					file_list.select(next_index)
					_on_file_selected(next_index)
			KEY_F3:
				# 上一个文件
				var current_index = file_list.get_selected_items()
				if current_index.size() > 0:
					var prev_index = (current_index[0] - 1 + preset_files.size()) % preset_files.size()
					file_list.select(prev_index)
					_on_file_selected(prev_index)
			KEY_SPACE:
				_on_pause_button_pressed()
			KEY_ESCAPE:
				get_tree().quit()
