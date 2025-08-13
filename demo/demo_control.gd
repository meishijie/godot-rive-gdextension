extends Control

@onready var v = $RiveViewer
var _anchor_screen: Vector2 = Vector2.ZERO
var _anchor_local: Vector2 = Vector2.ZERO
var _has_anchor: bool = false

var _last_win_pos: Vector2i = Vector2i.ZERO
var _last_scale: float = -1.0


func _ready() -> void:
	var win = v.get_window()
	if win:
		win.size_changed.connect(func(): _has_anchor = false)

func _process(_dt: float) -> void:
	if v == null:
		return

	if v.get_artboard() == null:
		return
	# 使用全局屏幕坐标驱动（窗口内外都可跟随）
	var screen = Vector2(DisplayServer.mouse_get_position())
	var win = v.get_window()
	if win == null:
		return
	var scale = float(win.get_content_scale_factor())
	var win_pos_i: Vector2i = win.position
	if _last_win_pos != win_pos_i or not is_equal_approx(_last_scale, scale):
		_has_anchor = false
		_last_win_pos = win_pos_i
		_last_scale = scale
	var win_pos = Vector2(win_pos_i)
	var in_window = (screen - win_pos) / scale
	var win_size: Vector2i = win.size
	var inside_window: bool = (in_window.x >= 0.0 and in_window.y >= 0.0 and in_window.x < win_size.x and in_window.y < win_size.y)
	# 判断是否在 Viewer 区域内（用 Control 尺寸判断）
	var local_from_api: Vector2 = v.get_local_mouse_position()
	var inside_viewer: bool = (local_from_api.x >= 0.0 and local_from_api.y >= 0.0
		and local_from_api.x < v.size.x and local_from_api.y < v.size.y)

	var local: Vector2
	if inside_viewer:
		# 方案A：窗口内，直接走“第一种方案”——使用本地坐标
		local = local_from_api
		_anchor_screen = screen
		_anchor_local = local_from_api
		_has_anchor = true
	else:
		# 方案B：窗口外，使用“锚点+增量”的方式，把全屏鼠标位移传入第一种方案
		if _has_anchor:
			var delta_window: Vector2 = (screen - _anchor_screen) / scale
			var gxf: Transform2D = v.get_global_transform()
			var inv: Transform2D = gxf.affine_inverse()
			var window_anchor: Vector2 = gxf * _anchor_local
			var window_now: Vector2 = window_anchor + delta_window
			local = inv * window_now
		else:
			# 没有锚点（比如一开始就在窗口外），回退到当前全局换算
			local = v.get_global_transform().affine_inverse() * in_window
	# 限制在 Viewer 的可见区域内
	local.x = clamp(local.x, 0.0, v.size.x)
	local.y = clamp(local.y, 0.0, v.size.y)
	v.set_node_position_from_local("Face_Control", local)
