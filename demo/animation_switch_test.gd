extends Control

@onready var rive_viewer: RiveViewer = $RiveViewer
@onready var status_label: Label = $UI/StatusLabel

var auto_cycle = false
var cycle_timer = 0.0
var cycle_interval = 3.0
var current_animation_index = -1
var current_file_index = 0

# 可用的 Rive 文件列表
var rive_files = [
	"res://examples/juice.riv",
	"res://examples/long_name.riv",
	"res://examples/walle.riv",
	"res://examples/rocket.riv",
	"res://examples/hello_world.riv"
]

func _ready():
	print("[AnimationSwitchTest] Starting dynamic loading animation switch test")
	await get_tree().process_frame

	# 顺序测试加载所有文件
	await test_sequential_loading()

	# 最后回到第一个文件进行交互测试
	print("[AnimationSwitchTest] Sequential loading test completed, returning to first file for interactive testing")
	load_rive_file(0)
	await get_tree().create_timer(1.0).timeout
	update_status()

func test_sequential_loading():
	print("[AnimationSwitchTest] === Starting sequential loading test ===")

	for i in range(rive_files.size()):
		print("[AnimationSwitchTest] --- Testing file %d/%d ---" % [i + 1, rive_files.size()])
		load_rive_file(i)

		# 等待加载完成
		await get_tree().create_timer(2.0).timeout

		# 显示当前状态
		update_status()

		# 短暂停顿以便观察
		await get_tree().create_timer(1.0).timeout

	print("[AnimationSwitchTest] === Sequential loading test completed ===")

func _process(delta):
	if auto_cycle:
		cycle_timer += delta
		if cycle_timer >= cycle_interval:
			cycle_timer = 0.0
			cycle_animations()

func load_rive_file(file_index: int):
	if file_index < 0 or file_index >= rive_files.size():
		print("[AnimationSwitchTest] Invalid file index: ", file_index)
		return

	var file_path = rive_files[file_index]
	print("[AnimationSwitchTest] Dynamically loading Rive file: ", file_path)

	# 记录加载前的位置信息
	var viewer_rect_before = rive_viewer.get_rect()
	print("[AnimationSwitchTest] Viewer rect before loading: ", viewer_rect_before)

	# 动态设置文件路径
	rive_viewer.file_path = file_path
	current_file_index = file_index

	# 等待文件加载完成
	await get_tree().process_frame
	await get_tree().process_frame

	# 智能设置 scene 和 animation
	setup_scene_and_animation()

	# 再等待一帧后检查位置
	await get_tree().process_frame
	var viewer_rect_after = rive_viewer.get_rect()
	print("[AnimationSwitchTest] Viewer rect after loading: ", viewer_rect_after)

	# 检查位置是否发生了意外偏移
	if viewer_rect_before != viewer_rect_after:
		print("[AnimationSwitchTest] WARNING: Position changed during file loading!")
		print("[AnimationSwitchTest] Before: ", viewer_rect_before)
		print("[AnimationSwitchTest] After: ", viewer_rect_after)
	else:
		print("[AnimationSwitchTest] SUCCESS: Position remained stable during file loading")

func setup_scene_and_animation():
	var artboard = rive_viewer.get_artboard()
	if artboard == null:
		print("[AnimationSwitchTest] No artboard available")
		return

	# 检查是否有 scene
	var scene_count = 0
	if artboard.has_method("get_scene_count"):
		scene_count = artboard.get_scene_count()

	# 检查动画数量
	var animation_count = artboard.get_animation_count()
	print("[AnimationSwitchTest] Scene count: ", scene_count, ", Animation count: ", animation_count)

	if scene_count > 0:
		# 如果有 scene，使用第一个 scene，并尝试播放第一个动画
		if animation_count > 0:
			print("[AnimationSwitchTest] Using scene mode with animation (scene=0, animation=0)")
			rive_viewer.scene = 0
			rive_viewer.animation = 1
			current_animation_index = 1
		else:
			print("[AnimationSwitchTest] Using scene mode without animation (scene=0, animation=-1)")
			rive_viewer.scene = 0
			rive_viewer.animation = -1
			current_animation_index = -1
	else:
		# 如果没有 scene，直接播放第一个动画
		if animation_count > 0:
			print("[AnimationSwitchTest] No scenes available, using animation mode (scene=-1, animation=0)")
			rive_viewer.scene = -1
			rive_viewer.animation = 0
			current_animation_index =0
		else:
			print("[AnimationSwitchTest] No scenes or animations available (scene=-1, animation=-1)")
			rive_viewer.scene = -1
			rive_viewer.animation = -1
			current_animation_index = -1

func cycle_animations():
	# 循环：None -> Animation 0 -> Animation 1 -> Animation 2 -> None
	var artboard = rive_viewer.get_artboard()
	if artboard == null:
		print("[AnimationSwitchTest] No artboard available")
		return

	var animation_count = artboard.get_animation_count()
	if animation_count == 0:
		print("[AnimationSwitchTest] No animations available")
		return

	current_animation_index += 1
	if current_animation_index >= animation_count:
		current_animation_index = -1  # 回到 None

	set_animation(current_animation_index)
	update_status()

func set_animation(index: int):
	print("[AnimationSwitchTest] Setting animation to index: ", index)

	# 记录切换前的位置信息
	var viewer_rect = rive_viewer.get_rect()
	print("[AnimationSwitchTest] Viewer rect before switch: ", viewer_rect)

	# 切换动画
	rive_viewer.animation = index
	current_animation_index = index

	# 等待一帧后检查位置
	await get_tree().process_frame
	var viewer_rect_after = rive_viewer.get_rect()
	print("[AnimationSwitchTest] Viewer rect after switch: ", viewer_rect_after)

	# 检查位置是否发生了意外偏移
	if viewer_rect != viewer_rect_after:
		print("[AnimationSwitchTest] WARNING: Position changed during animation switch!")
		print("[AnimationSwitchTest] Before: ", viewer_rect)
		print("[AnimationSwitchTest] After: ", viewer_rect_after)

func update_status():
	var status_text = ""

	# 显示当前文件信息
	if current_file_index < rive_files.size():
		var file_name = rive_files[current_file_index].get_file()
		status_text += "File: %s (%d/%d)\n" % [file_name, current_file_index + 1, rive_files.size()]

	var artboard = rive_viewer.get_artboard()
	if artboard == null:
		status_text += "No artboard loaded"
		status_label.text = status_text
		return

	# 显示 scene 信息
	var scene_count = 0
	if artboard.has_method("get_scene_count"):
		scene_count = artboard.get_scene_count()

	status_text += "Scene: %d (Total: %d)\n" % [rive_viewer.scene, scene_count]

	# 显示动画信息
	var animation_count = artboard.get_animation_count()

	if current_animation_index == -1:
		status_text += "Animation: None"
	else:
		var animation = artboard.get_animation(current_animation_index)
		var animation_name = "Unknown"
		if animation != null and animation.has_method("get_name"):
			animation_name = animation.get_name()
		status_text += "Animation: %s (Index: %d)" % [animation_name, current_animation_index]

	status_text += "\nTotal animations: %d" % animation_count
	if auto_cycle:
		status_text += "\nAuto cycling: ON"
	else:
		status_text += "\nAuto cycling: OFF"

	status_label.text = status_text

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("[AnimationSwitchTest] Manual switch to animation 0")
				set_animation(0)
				update_status()
			KEY_2:
				print("[AnimationSwitchTest] Manual switch to animation 1")
				set_animation(1)
				update_status()
			KEY_3:
				print("[AnimationSwitchTest] Manual switch to animation 2")
				set_animation(2)
				update_status()
			KEY_N:
				print("[AnimationSwitchTest] Manual switch to none")
				set_animation(-1)
				update_status()
			KEY_F:
				# 切换到下一个文件
				var next_file_index = (current_file_index + 1) % rive_files.size()
				print("[AnimationSwitchTest] Switching to next file: ", next_file_index)
				load_rive_file(next_file_index)
				await get_tree().create_timer(0.5).timeout  # 等待文件加载
				update_status()
			KEY_R:
				# 重新加载当前文件
				print("[AnimationSwitchTest] Reloading current file: ", current_file_index)
				load_rive_file(current_file_index)
				await get_tree().create_timer(0.5).timeout  # 等待文件加载
				update_status()
			KEY_SPACE:
				auto_cycle = !auto_cycle
				cycle_timer = 0.0
				print("[AnimationSwitchTest] Auto cycle toggled: ", auto_cycle)
				update_status()
			KEY_ESCAPE:
				print("[AnimationSwitchTest] Exiting test")
				get_tree().quit()
