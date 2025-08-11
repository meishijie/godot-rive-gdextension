extends Control

@onready var rive_viewer: RiveViewer = $RiveViewer
@onready var status_label: Label = $UI/StatusLabel

var auto_cycle = false
var cycle_timer = 0.0
var cycle_interval = 3.0
var current_animation_index = -1
var current_file_index = 0
var selected_input_index := 0

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
		# 如果有 scene，默认切到第一个 scene，动画None
		print("[AnimationSwitchTest] Using scene mode (scene=0, animation=-1)")
		rive_viewer.scene = 0
		rive_viewer.animation = -1
		current_animation_index = -1
		selected_input_index = 0
	else:
		# 如果没有 scene，直接播放第一个动画
		if animation_count > 0:
			print("[AnimationSwitchTest] No scenes available, using animation mode (scene=-1, animation=0)")
			rive_viewer.scene = -1
			rive_viewer.animation = 0
			current_animation_index = 0
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

func set_scene(index: int):
	print("[AnimationSwitchTest] Setting scene to index: ", index)
	rive_viewer.scene = index
	# 如果进入 scene 模式，动画通常不会生效，将动画索引设为-1 以避免误导
	if index != -1:
		current_animation_index = -1
	selected_input_index = 0
	await get_tree().process_frame
	update_status()

func next_prev_animation(step: int):
	var artboard = rive_viewer.get_artboard()
	if artboard == null:
		return
	var animation_count = artboard.get_animation_count()
	if animation_count == 0:
		current_animation_index = -1
		set_animation(-1)
		return
	var next_index = current_animation_index
	if next_index == -1:
		next_index = 0 if step > 0 else animation_count - 1
	else:
		next_index = clamp(next_index + step, -1, animation_count - 1)
	set_animation(next_index)
	update_status()

func next_prev_scene(step: int):
	var artboard = rive_viewer.get_artboard()
	if artboard == null:
		return
	var scene_count = 0
	if artboard.has_method("get_scene_count"):
		scene_count = artboard.get_scene_count()
	if scene_count == 0:
		set_scene(-1)
		return
	var curr := int(rive_viewer.scene)
	if curr == -1:
		curr = 0 if step > 0 else scene_count - 1
	else:
		curr = clamp(curr + step, -1, scene_count - 1)
	set_scene(curr)

func select_input(step: int):
	var scene = rive_viewer.get_scene()
	if scene == null:
		return
	var count = scene.get_input_count()
	if count <= 0:
		return
	selected_input_index = clamp(selected_input_index + step, 0, count - 1)
	update_status()

func toggle_selected_bool():
	var scene = rive_viewer.get_scene()
	if scene == null:
		return
	var input: RiveInput = scene.get_input(selected_input_index)
	if input and input.is_bool():
		input.set_value(!bool(input.get_value()))
		print("[AnimationSwitchTest] Toggled bool input:", input.get_name(), "=>", input.get_value())
		update_status()

func adjust_selected_number(delta_value: float):
	var scene = rive_viewer.get_scene()
	if scene == null:
		return
	var input: RiveInput = scene.get_input(selected_input_index)
	if input and input.is_number():
		var v = float(input.get_value()) + delta_value
		input.set_value(v)
		print("[AnimationSwitchTest] Adjusted number input:", input.get_name(), "=>", input.get_value())
		update_status()

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
	var scene_name = "None"
	if artboard.has_method("get_scene_count"):
		scene_count = artboard.get_scene_count()
		if rive_viewer.scene >= 0 and rive_viewer.scene < scene_count:
			var sc = artboard.get_scene(rive_viewer.scene)
			if sc and sc.has_method("get_name"):
				scene_name = sc.get_name()
	status_text += "Scene: %d/%d (%s)\n" % [rive_viewer.scene, scene_count, scene_name]

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

	# 输入变量信息（仅 scene 模式）
	var scene_ref = rive_viewer.get_scene()
	if scene_ref != null:
		var input_count = scene_ref.get_input_count()
		status_text += "\nInputs: %d" % input_count
		if input_count > 0:
			selected_input_index = clamp(selected_input_index, 0, input_count - 1)
			var sel: RiveInput = scene_ref.get_input(selected_input_index)
			if sel != null:
				var type_str = "bool" if sel.is_bool() else ("number" if sel.is_number() else "unknown")
				status_text += "\nSelected Input [%d]: %s (%s) = %s" % [selected_input_index, sel.get_name(), type_str, str(sel.get_value())]
			else:
				status_text += "\nSelected Input [%d]: null" % selected_input_index

	if auto_cycle:
		status_text += "\nAuto cycling: ON"
	else:
		status_text += "\nAuto cycling: OFF"

	status_label.text = status_text

func _input(event):
	if event is InputEventKey and event.pressed:
		var e := event as InputEventKey
		var shift: bool = e.shift_pressed
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
			KEY_LEFT:
				next_prev_animation(-1)
			KEY_RIGHT:
				next_prev_animation(1)
			KEY_N:
				print("[AnimationSwitchTest] Manual switch to none")
				set_animation(-1)
				update_status()
			KEY_Q:
				next_prev_scene(-1)
			KEY_E:
				next_prev_scene(1)
			KEY_M:
				set_scene(-1) # 退出 scene 模式
			KEY_BRACKETLEFT:
				select_input(-1)
			KEY_BRACKETRIGHT:
				select_input(1)
			KEY_T:
				toggle_selected_bool()
			KEY_UP, KEY_EQUAL:
				adjust_selected_number(1.0 if shift else 0.1)
			KEY_DOWN, KEY_MINUS:
				adjust_selected_number(-(1.0 if shift else 0.1))
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
