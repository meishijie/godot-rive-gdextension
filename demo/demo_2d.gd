extends Control

@onready var rive_viewer: RiveViewer = $RiveViewer
@onready var status_label: Label = $UI/StatusLabel
var current_file_index = 0
var rive_files = [
	"res://examples/juice.riv",
	"res://examples/walle.riv",
	"res://examples/off_road_car.riv",
	"res://examples/rating-animation.riv",
	"res://examples/on_off.riv",
	"res://examples/glass_button.riv",
	"res://examples/notification.riv",
	"res://examples/meteor.riv",
	"res://examples/joystick.riv",
	"res://examples/house_resizing.riv",
	"res://examples/bullet_man.riv",
	"res://examples/ghost.riv",
	"res://examples/light_switch.riv",
	"res://examples/rocket.riv",
	"res://examples/hello_world.riv",
	"res://examples/death_knight.riv",
	"res://examples/jellyfish_test.riv",
	"res://examples/two_artboards.riv"
]


var is_loading = false
var load_timer = 0.0
var load_timeout = 3.0  # 3秒超时

func _ready():
	print("[Demo2D] Starting demo with dynamic Rive loading")

	# 等待一帧确保RiveViewer完全初始化
	await get_tree().process_frame

	# 开始加载第一个文件
	load_next_rive_file()

	# 设置定时器每5秒切换文件
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.timeout.connect(_on_switch_timer_timeout)
	timer.autostart = true
	add_child(timer)

func _process(delta):
	if is_loading:
		load_timer += delta
		if load_timer > load_timeout:
			var file_name = rive_files[current_file_index].get_file()
			print("[Demo2D] Loading timeout for file: ", rive_files[current_file_index])
			status_label.text = "TIMEOUT: %s (%d/%d)" % [file_name, current_file_index + 1, rive_files.size()]
			is_loading = false
			load_timer = 0.0
			# 等待2秒后尝试加载下一个文件
			await get_tree().create_timer(2.0).timeout
			_on_switch_timer_timeout()

func load_next_rive_file():
	if is_loading:
		print("[Demo2D] Already loading, skipping...")
		return

	var file_path = rive_files[current_file_index]
	var file_name = file_path.get_file()
	print("[Demo2D] Loading Rive file: ", file_path)

	# 更新UI状态
	status_label.text = "Loading: %s (%d/%d)" % [file_name, current_file_index + 1, rive_files.size()]

	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		print("[Demo2D] ERROR: File does not exist: ", file_path)
		status_label.text = "ERROR: File not found: %s" % file_name
		current_file_index = (current_file_index + 1) % rive_files.size()
		return

	is_loading = true
	load_timer = 0.0

	# 设置文件路径
	rive_viewer.file_path = file_path

	# # 等待一小段时间让渲染器处理
	# await get_tree().create_timer(3.5).timeout
	print("[Demo2D] Waiting done, validating file...")
	# 检查是否成功加载
	if validate_rive_file():
		is_loading = false
		load_timer = 0.0
	else:
		# 继续等待，让_process中的超时机制处理
		pass

func validate_rive_file():
	var rive_file = rive_viewer.get_file()
	var artboard = rive_viewer.get_artboard()

	print("[Demo2D] Rive file validation: File=", rive_file, " Artboard=", artboard)

	if rive_file != null and artboard != null:
		var file_name = rive_files[current_file_index].get_file()
		print("[Demo2D] SUCCESS: Rive file loaded successfully: ", rive_files[current_file_index])

		# 智能设置 scene 和 animation
		setup_scene_and_animation()

		# Try to get artboard name for more info
		var artboard_name = "Unknown"
		if artboard.has_method("get_name"):
			artboard_name = artboard.get_name()

		# 更新状态显示，包含 scene 和 animation 信息
		update_detailed_status(file_name, artboard_name)
		return true
	else:
		var file_name = rive_files[current_file_index].get_file()
		var error_detail = ""
		if rive_file == null:
			error_detail = "File null"
		elif artboard == null:
			error_detail = "Artboard null"
		print("[Demo2D] WARNING: Rive file may not be loaded properly: ", rive_files[current_file_index], " (", error_detail, ")")
		status_label.text = "FAILED: %s [%s] (%d/%d)" % [file_name, error_detail, current_file_index + 1, rive_files.size()]
		return false

func setup_scene_and_animation():
	var artboard = rive_viewer.get_artboard()
	if artboard == null:
		print("[Demo2D] No artboard available")
		return

	# 检查是否有 scene
	var scene_count = 0
	if artboard.has_method("get_scene_count"):
		scene_count = artboard.get_scene_count()

	# 检查动画数量
	var animation_count = artboard.get_animation_count()
	print("[Demo2D] Scene count: ", scene_count, ", Animation count: ", animation_count)

	if scene_count > 0:
		# 如果有 scene，使用第一个 scene，并尝试播放第一个动画
		if animation_count > 0:
			print("[Demo2D] Using scene mode with animation (scene=0, animation=0)")
			rive_viewer.scene = 0
			rive_viewer.animation = 1
		else:
			print("[Demo2D] Using scene mode without animation (scene=0, animation=-1)")
			rive_viewer.scene = 0
			rive_viewer.animation = 1
	else:
		# 如果没有 scene，直接播放第一个动画
		if animation_count > 0:
			print("[Demo2D] No scenes available, using animation mode (scene=-1, animation=0)")
			rive_viewer.scene = -1
			rive_viewer.animation = 0
		else:
			print("[Demo2D] No scenes or animations available (scene=-1, animation=-1)")
			rive_viewer.scene = -1
			rive_viewer.animation = -1

func update_detailed_status(file_name: String, artboard_name: String):
	var artboard = rive_viewer.get_artboard()
	if artboard == null:
		status_label.text = "SUCCESS: %s [%s] (%d/%d)" % [file_name, artboard_name, current_file_index + 1, rive_files.size()]
		return

	# 获取 scene 和 animation 信息
	var scene_count = 0
	if artboard.has_method("get_scene_count"):
		scene_count = artboard.get_scene_count()

	var animation_count = artboard.get_animation_count()
	var current_scene = rive_viewer.scene
	var current_animation = rive_viewer.animation

	# 构建详细状态信息
	var status_text = "SUCCESS: %s [%s] (%d/%d)\n" % [file_name, artboard_name, current_file_index + 1, rive_files.size()]
	status_text += "Scene: %d/%d, Animation: %d/%d" % [current_scene, scene_count, current_animation, animation_count]

	status_label.text = status_text

func _on_switch_timer_timeout():
	print("[Demo2D] Switching to next Rive file...")
	current_file_index = (current_file_index + 1) % rive_files.size()
	load_next_rive_file()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				print("[Demo2D] Manual switch triggered")
				_on_switch_timer_timeout()
			KEY_R:
				print("[Demo2D] Reloading current file")
				load_next_rive_file()
			KEY_ESCAPE:
				print("[Demo2D] Exiting demo")
				get_tree().quit()
