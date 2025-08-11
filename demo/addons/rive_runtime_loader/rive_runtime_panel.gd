extends Control

# UI节点引用
@onready var file_path_line_edit: LineEdit = $VBox/FileSection/HBox/FilePathLineEdit
@onready var browse_button: Button = $VBox/FileSection/HBox/BrowseButton
@onready var load_button: Button = $VBox/FileSection/LoadButton
@onready var rive_viewer_option: OptionButton = $VBox/ViewerSection/HBox/RiveViewerOption
@onready var refresh_viewers_button: Button = $VBox/ViewerSection/HBox/RefreshButton

@onready var file_info_label: Label = $VBox/InfoSection/FileInfoLabel
@onready var scene_option: OptionButton = $VBox/ControlSection/SceneHBox/SceneOption
@onready var animation_option: OptionButton = $VBox/ControlSection/AnimationHBox/AnimationOption
@onready var play_pause_button: Button = $VBox/ControlSection/PlayPauseButton

@onready var inputs_container: VBoxContainer = $VBox/InputsSection/ScrollContainer/InputsContainer

# 文件对话框
var file_dialog: FileDialog

# 当前选中的RiveViewer
var current_rive_viewer: RiveViewer = null
var rive_viewers: Array[RiveViewer] = []

# 输入控件缓存
var input_controls: Array = []

func _ready():
	setup_ui()
	setup_file_dialog()
	refresh_rive_viewers()
	
	# 连接信号
	browse_button.pressed.connect(_on_browse_pressed)
	load_button.pressed.connect(_on_load_pressed)
	refresh_viewers_button.pressed.connect(_on_refresh_viewers_pressed)
	rive_viewer_option.item_selected.connect(_on_rive_viewer_selected)
	scene_option.item_selected.connect(_on_scene_selected)
	animation_option.item_selected.connect(_on_animation_selected)
	play_pause_button.pressed.connect(_on_play_pause_pressed)

func setup_ui():
	# 设置基本UI属性
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 设置默认文件路径
	file_path_line_edit.text = "res://examples/"
	file_path_line_edit.placeholder_text = "选择.riv文件路径"

func setup_file_dialog():
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.add_filter("*.riv", "Rive Files")
	file_dialog.current_dir = "res://examples/"
	add_child(file_dialog)
	file_dialog.file_selected.connect(_on_file_selected)

func refresh_rive_viewers():
	rive_viewers.clear()
	rive_viewer_option.clear()
	
	# 查找场景中的所有RiveViewer节点
	var root = get_tree().current_scene
	if root:
		_find_rive_viewers_recursive(root)
	
	# 更新选项按钮
	for i in range(rive_viewers.size()):
		var viewer = rive_viewers[i]
		var name = viewer.name if viewer.name != "" else "RiveViewer_%d" % i
		rive_viewer_option.add_item(name)
	
	if rive_viewers.size() > 0:
		rive_viewer_option.selected = 0
		_on_rive_viewer_selected(0)
	else:
		file_info_label.text = "未找到RiveViewer节点"

func _find_rive_viewers_recursive(node: Node):
	if node is RiveViewer:
		rive_viewers.append(node as RiveViewer)
	
	for child in node.get_children():
		_find_rive_viewers_recursive(child)

func _on_browse_pressed():
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_file_selected(path: String):
	file_path_line_edit.text = path

func _on_load_pressed():
	if not current_rive_viewer:
		print("[RiveRuntimePanel] 没有选中的RiveViewer")
		return

	var file_path = file_path_line_edit.text
	if file_path == "":
		print("[RiveRuntimePanel] 文件路径为空")
		return

	print("[RiveRuntimePanel] 加载文件: ", file_path)
	current_rive_viewer.file_path = file_path

	# 延迟更新信息
	call_deferred("_update_after_load")

func _update_after_load():
	if get_tree():
		await get_tree().process_frame
		await get_tree().process_frame
	update_file_info()

func _on_refresh_viewers_pressed():
	refresh_rive_viewers()

func _on_rive_viewer_selected(index: int):
	if index >= 0 and index < rive_viewers.size():
		current_rive_viewer = rive_viewers[index]
		update_file_info()
		print("[RiveRuntimePanel] 选中RiveViewer: ", current_rive_viewer.name)

func update_file_info():
	if not current_rive_viewer:
		file_info_label.text = "未选中RiveViewer"
		return
	
	var artboard = current_rive_viewer.get_artboard()
	if not artboard:
		file_info_label.text = "未加载文件或文件无效"
		return
	
	# 更新文件信息
	var info_text = "文件: %s\n" % current_rive_viewer.file_path
	
	# 场景信息
	var scene_count = 0
	if artboard.has_method("get_scene_count"):
		scene_count = artboard.get_scene_count()
	
	# 动画信息
	var animation_count = artboard.get_animation_count()
	
	info_text += "场景数: %d, 动画数: %d" % [scene_count, animation_count]
	file_info_label.text = info_text
	
	# 更新场景选项
	update_scene_options(artboard, scene_count)
	
	# 更新动画选项
	update_animation_options(artboard, animation_count)
	
	# 更新输入控件
	update_input_controls()

func update_scene_options(artboard, scene_count: int):
	scene_option.clear()
	scene_option.add_item("无场景 (-1)")
	
	for i in range(scene_count):
		var scene_name = "场景 %d" % i
		if artboard.has_method("get_scene"):
			var scene = artboard.get_scene(i)
			if scene and scene.has_method("get_name"):
				scene_name = scene.get_name()
		scene_option.add_item(scene_name)
	
	# 设置当前选中的场景
	var current_scene = current_rive_viewer.scene
	scene_option.selected = current_scene + 1  # +1因为第一项是"无场景"

func update_animation_options(artboard, animation_count: int):
	animation_option.clear()
	animation_option.add_item("无动画 (-1)")
	
	for i in range(animation_count):
		var animation_name = "动画 %d" % i
		var animation = artboard.get_animation(i)
		if animation and animation.has_method("get_name"):
			animation_name = animation.get_name()
		animation_option.add_item(animation_name)
	
	# 设置当前选中的动画
	var current_animation = current_rive_viewer.animation
	animation_option.selected = current_animation + 1  # +1因为第一项是"无动画"

func _on_scene_selected(index: int):
	if not current_rive_viewer:
		return

	var scene_index = index - 1  # -1因为第一项是"无场景"
	print("[RiveRuntimePanel] 切换到场景: ", scene_index)
	current_rive_viewer.scene = scene_index

	# 延迟更新输入控件
	call_deferred("_update_input_controls_deferred")

func _update_input_controls_deferred():
	if get_tree():
		await get_tree().process_frame
	update_input_controls()

func _on_animation_selected(index: int):
	if not current_rive_viewer:
		return
	
	var animation_index = index - 1  # -1因为第一项是"无动画"
	print("[RiveRuntimePanel] 切换到动画: ", animation_index)
	current_rive_viewer.animation = animation_index

func _on_play_pause_pressed():
	if not current_rive_viewer:
		return
	
	current_rive_viewer.paused = !current_rive_viewer.paused
	play_pause_button.text = "播放" if current_rive_viewer.paused else "暂停"
	print("[RiveRuntimePanel] ", "暂停" if current_rive_viewer.paused else "播放")

func update_input_controls():
	# 清除现有的输入控件
	for control in input_controls:
		if is_instance_valid(control):
			control.queue_free()
	input_controls.clear()
	
	if not current_rive_viewer:
		return
	
	var scene = current_rive_viewer.get_scene()
	if not scene:
		return
	
	var input_count = scene.get_input_count()
	if input_count == 0:
		return
	
	# 为每个输入创建控件
	for i in range(input_count):
		var input: RiveInput = scene.get_input(i)
		if not input:
			continue
		
		create_input_control(input, i)

func create_input_control(input: RiveInput, index: int):
	var container = HBoxContainer.new()
	inputs_container.add_child(container)
	input_controls.append(container)
	
	# 输入名称标签
	var name_label = Label.new()
	name_label.text = input.get_name()
	name_label.custom_minimum_size.x = 100
	container.add_child(name_label)
	
	# 根据输入类型创建不同的控件
	if input.is_bool():
		var checkbox = CheckBox.new()
		checkbox.button_pressed = bool(input.get_value())
		checkbox.toggled.connect(func(pressed: bool): input.set_value(pressed))
		container.add_child(checkbox)
	elif input.is_number():
		var spinbox = SpinBox.new()
		spinbox.value = float(input.get_value())
		spinbox.step = 0.1
		spinbox.allow_greater = true
		spinbox.allow_lesser = true
		spinbox.value_changed.connect(func(value: float): input.set_value(value))
		container.add_child(spinbox)
	else:
		var type_label = Label.new()
		type_label.text = "未知类型"
		container.add_child(type_label)
