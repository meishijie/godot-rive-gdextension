extends Node

# Rive加载器管理器 - 可以作为单例使用
# 提供全局的Rive文件加载和管理功能

signal file_loaded(rive_viewer: RiveViewer, file_path: String)
signal file_load_failed(rive_viewer: RiveViewer, file_path: String, error: String)

# 预设的riv文件路径
var preset_files: Array[String] = [
	"res://examples/juice.riv",
	"res://examples/long_name.riv", 
	"res://examples/walle.riv",
	"res://examples/rocket.riv",
	"res://examples/hello_world.riv",
	"res://examples/ghost.riv",
	"res://examples/light_switch.riv",
	"res://examples/off_road_car.riv"
]

# 当前管理的RiveViewer实例
var managed_viewers: Array[RiveViewer] = []

func _ready():
	print("[RiveLoaderManager] Manager initialized")

# 注册一个RiveViewer到管理器
func register_viewer(viewer: RiveViewer) -> void:
	if viewer and viewer not in managed_viewers:
		managed_viewers.append(viewer)
		print("[RiveLoaderManager] Registered viewer: ", viewer.name)

# 注销RiveViewer
func unregister_viewer(viewer: RiveViewer) -> void:
	if viewer in managed_viewers:
		managed_viewers.erase(viewer)
		print("[RiveLoaderManager] Unregistered viewer: ", viewer.name)

# 获取所有注册的RiveViewer
func get_managed_viewers() -> Array[RiveViewer]:
	# 清理无效的引用
	managed_viewers = managed_viewers.filter(func(viewer): return is_instance_valid(viewer))
	return managed_viewers

# 加载文件到指定的RiveViewer
func load_file(viewer: RiveViewer, file_path: String) -> bool:
	if not viewer:
		print("[RiveLoaderManager] Invalid viewer")
		return false

	if not FileAccess.file_exists(file_path):
		var error = "File not found: " + file_path
		print("[RiveLoaderManager] ", error)
		file_load_failed.emit(viewer, file_path, error)
		return false

	print("[RiveLoaderManager] Loading file: ", file_path, " to viewer: ", viewer.name)

	# 记录加载前的状态
	var old_path = viewer.file_path

	# 加载文件
	viewer.file_path = file_path

	# 等待加载完成 - 使用更安全的方法
	await _wait_for_frames()

	# 检查是否加载成功
	var artboard = viewer.get_artboard()
	if artboard:
		print("[RiveLoaderManager] Successfully loaded: ", file_path)
		file_loaded.emit(viewer, file_path)
		return true
	else:
		var error = "Failed to load artboard from: " + file_path
		print("[RiveLoaderManager] ", error)
		file_load_failed.emit(viewer, file_path, error)
		return false

# 安全的等待帧函数
func _wait_for_frames():
	var tree = get_tree()
	if tree:
		await tree.process_frame
		await tree.process_frame
	else:
		# 如果没有树，使用定时器作为后备
		await get_tree().create_timer(0.1).timeout

# 加载预设文件
func load_preset_file(viewer: RiveViewer, index: int) -> bool:
	if index < 0 or index >= preset_files.size():
		print("[RiveLoaderManager] Invalid preset index: ", index)
		return false
	
	return await load_file(viewer, preset_files[index])

# 获取预设文件列表
func get_preset_files() -> Array[String]:
	return preset_files

# 添加预设文件
func add_preset_file(file_path: String) -> void:
	if file_path not in preset_files:
		preset_files.append(file_path)
		print("[RiveLoaderManager] Added preset file: ", file_path)

# 移除预设文件
func remove_preset_file(file_path: String) -> void:
	if file_path in preset_files:
		preset_files.erase(file_path)
		print("[RiveLoaderManager] Removed preset file: ", file_path)

# 扫描目录中的riv文件
func scan_directory_for_riv_files(directory_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(directory_path)
	
	if not dir:
		print("[RiveLoaderManager] Cannot open directory: ", directory_path)
		return files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".riv"):
			files.append(directory_path + "/" + file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("[RiveLoaderManager] Found ", files.size(), " .riv files in ", directory_path)
	return files

# 自动扫描并添加examples目录中的文件
func auto_scan_examples() -> void:
	var example_files = scan_directory_for_riv_files("res://examples")
	for file in example_files:
		add_preset_file(file)

# 获取RiveViewer的详细信息
func get_viewer_info(viewer: RiveViewer) -> Dictionary:
	var info = {
		"name": viewer.name,
		"file_path": viewer.file_path,
		"scene": viewer.scene,
		"animation": viewer.animation,
		"paused": viewer.paused,
		"has_artboard": false,
		"scene_count": 0,
		"animation_count": 0,
		"input_count": 0
	}
	
	var artboard = viewer.get_artboard()
	if artboard:
		info.has_artboard = true
		info.animation_count = artboard.get_animation_count()
		
		if artboard.has_method("get_scene_count"):
			info.scene_count = artboard.get_scene_count()
		
		var scene = viewer.get_scene()
		if scene:
			info.input_count = scene.get_input_count()
	
	return info

# 批量操作：暂停/恢复所有管理的viewer
func pause_all_viewers() -> void:
	for viewer in get_managed_viewers():
		viewer.paused = true
	print("[RiveLoaderManager] Paused all viewers")

func resume_all_viewers() -> void:
	for viewer in get_managed_viewers():
		viewer.paused = false
	print("[RiveLoaderManager] Resumed all viewers")

# 批量加载相同文件到所有viewer
func load_file_to_all(file_path: String) -> void:
	for viewer in get_managed_viewers():
		await load_file(viewer, file_path)

# 循环切换预设文件
func cycle_preset_files(viewer: RiveViewer, forward: bool = true) -> void:
	if preset_files.is_empty():
		return
	
	var current_path = viewer.file_path
	var current_index = preset_files.find(current_path)
	
	var next_index: int
	if current_index == -1:
		next_index = 0
	else:
		if forward:
			next_index = (current_index + 1) % preset_files.size()
		else:
			next_index = (current_index - 1 + preset_files.size()) % preset_files.size()
	
	await load_preset_file(viewer, next_index)
