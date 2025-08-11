extends Node

# Rive热键控制器
# 提供快捷键来控制Rive文件的加载和播放

@export var target_rive_viewer: RiveViewer
@export var enable_hotkeys: bool = true

# 热键映射
var hotkey_actions = {
	KEY_F1: "toggle_panel",
	KEY_F2: "next_file", 
	KEY_F3: "prev_file",
	KEY_F4: "reload_file",
	KEY_SPACE: "toggle_pause",
	KEY_R: "reset_animation",
	KEY_1: "load_preset_0",
	KEY_2: "load_preset_1", 
	KEY_3: "load_preset_2",
	KEY_4: "load_preset_3",
	KEY_5: "load_preset_4",
	KEY_LEFT: "prev_animation",
	KEY_RIGHT: "next_animation",
	KEY_UP: "prev_scene",
	KEY_DOWN: "next_scene"
}

# 引用
var loader_manager: Node
var runtime_panel: Control

func _ready():
	# 查找加载器管理器
	loader_manager = get_node_or_null("/root/RiveLoaderManager")
	if not loader_manager:
		# 如果不存在，创建一个
		loader_manager = preload("res://addons/rive_runtime_loader/rive_loader_manager.gd").new()
		loader_manager.name = "RiveLoaderManager"
		get_tree().root.call_deferred("add_child", loader_manager)
	
	# 自动注册目标viewer
	if target_rive_viewer:
		loader_manager.register_viewer(target_rive_viewer)
	
	print("[RiveHotkeyController] Hotkey controller ready")

func _input(event):
	if not enable_hotkeys or not event is InputEventKey or not event.pressed:
		return
	
	var keycode = event.keycode
	if keycode in hotkey_actions:
		var action = hotkey_actions[keycode]
		execute_action(action)
		get_viewport().set_input_as_handled()

func execute_action(action: String):
	print("[RiveHotkeyController] Executing action: ", action)
	
	match action:
		"toggle_panel":
			toggle_runtime_panel()
		"next_file":
			cycle_file(true)
		"prev_file":
			cycle_file(false)
		"reload_file":
			reload_current_file()
		"toggle_pause":
			toggle_pause()
		"reset_animation":
			reset_animation()
		"prev_animation":
			cycle_animation(false)
		"next_animation":
			cycle_animation(true)
		"prev_scene":
			cycle_scene(false)
		"next_scene":
			cycle_scene(true)
		_:
			if action.begins_with("load_preset_"):
				var index_str = action.substr(12)  # "load_preset_".length()
				var index = index_str.to_int()
				load_preset(index)

func toggle_runtime_panel():
	if not runtime_panel:
		# 查找运行时面板
		runtime_panel = find_runtime_panel()
	
	if runtime_panel:
		runtime_panel.visible = !runtime_panel.visible
		print("[RiveHotkeyController] Runtime panel visibility: ", runtime_panel.visible)

func find_runtime_panel() -> Control:
	# 在场景树中查找运行时面板
	var root = get_tree().current_scene
	return find_node_by_script(root, "res://addons/rive_runtime_loader/rive_runtime_panel.gd")

func find_node_by_script(node: Node, script_path: String) -> Node:
	if node.get_script() and node.get_script().resource_path == script_path:
		return node
	
	for child in node.get_children():
		var result = find_node_by_script(child, script_path)
		if result:
			return result
	
	return null

func cycle_file(forward: bool):
	if not target_rive_viewer or not loader_manager:
		return
	
	await loader_manager.cycle_preset_files(target_rive_viewer, forward)

func reload_current_file():
	if not target_rive_viewer or not loader_manager:
		return
	
	var current_path = target_rive_viewer.file_path
	if current_path != "":
		await loader_manager.load_file(target_rive_viewer, current_path)

func toggle_pause():
	if not target_rive_viewer:
		return
	
	target_rive_viewer.paused = !target_rive_viewer.paused
	print("[RiveHotkeyController] Paused: ", target_rive_viewer.paused)

func reset_animation():
	if not target_rive_viewer:
		return
	
	# 重新设置当前动画来重置它
	var current_animation = target_rive_viewer.animation
	target_rive_viewer.animation = -1
	if get_tree():
		await get_tree().process_frame
	target_rive_viewer.animation = current_animation
	print("[RiveHotkeyController] Animation reset")

func cycle_animation(forward: bool):
	if not target_rive_viewer:
		return
	
	var artboard = target_rive_viewer.get_artboard()
	if not artboard:
		return
	
	var animation_count = artboard.get_animation_count()
	if animation_count == 0:
		return
	
	var current = target_rive_viewer.animation
	var next: int
	
	if forward:
		next = (current + 1) % animation_count
	else:
		next = (current - 1 + animation_count) % animation_count
	
	target_rive_viewer.animation = next
	print("[RiveHotkeyController] Animation: ", next)

func cycle_scene(forward: bool):
	if not target_rive_viewer:
		return
	
	var artboard = target_rive_viewer.get_artboard()
	if not artboard or not artboard.has_method("get_scene_count"):
		return
	
	var scene_count = artboard.get_scene_count()
	if scene_count == 0:
		return
	
	var current = target_rive_viewer.scene
	var next: int
	
	if current == -1:
		next = 0 if forward else scene_count - 1
	else:
		if forward:
			next = (current + 1) % scene_count
		else:
			next = (current - 1 + scene_count) % scene_count
	
	target_rive_viewer.scene = next
	print("[RiveHotkeyController] Scene: ", next)

func load_preset(index: int):
	if not target_rive_viewer or not loader_manager:
		return
	
	await loader_manager.load_preset_file(target_rive_viewer, index)

# 设置目标RiveViewer
func set_target_viewer(viewer: RiveViewer):
	if target_rive_viewer and loader_manager:
		loader_manager.unregister_viewer(target_rive_viewer)
	
	target_rive_viewer = viewer
	
	if target_rive_viewer and loader_manager:
		loader_manager.register_viewer(target_rive_viewer)

# 打印帮助信息
func print_help():
	print("[RiveHotkeyController] Hotkey Help:")
	print("F1 - Toggle runtime panel")
	print("F2 - Next preset file")
	print("F3 - Previous preset file") 
	print("F4 - Reload current file")
	print("Space - Toggle pause")
	print("R - Reset animation")
	print("1-5 - Load preset files 0-4")
	print("Left/Right - Previous/Next animation")
	print("Up/Down - Previous/Next scene")
