# Rive Runtime Loader 使用指南

我已经为你创建了一个完整的Rive运行时加载器系统，包含两个版本：

## 🚀 快速开始

### 简化版本（推荐）
运行 `simple_rive_loader_demo.tscn` - 这是一个简洁、稳定的版本，提供核心功能：

**功能特性：**
- ✅ 自动扫描examples目录中的所有.riv文件
- ✅ 点击列表项快速加载文件
- ✅ 实时调整场景和动画索引
- ✅ 暂停/播放控制
- ✅ 快捷键支持

**快捷键：**
- `F2` - 下一个文件
- `F3` - 上一个文件  
- `空格` - 暂停/播放
- `ESC` - 退出

### 完整版本（高级功能）
运行 `rive_loader_complete_demo.tscn` - 功能更丰富但更复杂：

**额外功能：**
- 🎮 运行时控制面板（按F1切换）
- 🔥 更多快捷键支持
- ⚙️ 输入参数实时调整
- 📁 文件浏览器
- 🔍 自动RiveViewer检测

## 📁 Addon结构

```
demo/addons/rive_runtime_loader/
├── plugin.cfg                    # 插件配置
├── rive_runtime_panel.gd/.tscn   # 运行时控制面板
├── rive_loader_manager.gd        # 加载器管理器
├── rive_hotkey_controller.gd     # 热键控制器
└── README.md                     # 详细文档
```

## 🛠️ 集成到你的项目

### 方法1：复制简化版本
```gdscript
# 复制 simple_rive_loader_demo.gd 的核心代码
extends Control

@onready var rive_viewer: RiveViewer = $RiveViewer

func load_rive_file(file_path: String):
    rive_viewer.file_path = file_path
    await get_tree().process_frame
    await get_tree().process_frame
    # 文件已加载
```

### 方法2：使用完整Addon
1. 复制 `addons/rive_runtime_loader` 到你的项目
2. 实例化 `RiveRuntimePanel` 场景
3. 添加 `RiveHotkeyController` 节点

### 方法3：使用管理器类
```gdscript
# 使用RiveLoaderManager进行程序化控制
var loader_manager = preload("res://addons/rive_runtime_loader/rive_loader_manager.gd").new()
add_child(loader_manager)

# 注册RiveViewer
loader_manager.register_viewer(your_rive_viewer)

# 加载文件
await loader_manager.load_file(your_rive_viewer, "res://examples/juice.riv")
```

## 🎯 核心功能说明

### 文件加载
- 支持.riv文件的动态加载
- 自动验证文件有效性
- 错误处理和状态反馈

### 场景和动画控制
- 场景索引：-1表示无场景，0+表示具体场景
- 动画索引：-1表示无动画，0+表示具体动画
- 实时切换，立即生效

### 输入参数调整（完整版）
- 自动检测状态机输入
- 布尔值：复选框控制
- 数值：滑块/输入框控制

## 🔧 自定义配置

### 修改预设文件列表
编辑 `rive_loader_manager.gd` 中的 `preset_files` 数组：
```gdscript
var preset_files: Array[String] = [
    "res://your_files/file1.riv",
    "res://your_files/file2.riv"
]
```

### 自定义快捷键
编辑 `rive_hotkey_controller.gd` 中的 `hotkey_actions` 字典：
```gdscript
var hotkey_actions = {
    KEY_F5: "your_custom_action"
}
```

## 📝 注意事项

1. **文件路径**：确保.riv文件在项目资源目录中
2. **RiveViewer节点**：必须在场景树中才能被检测到
3. **加载等待**：文件加载需要等待几帧才能完成
4. **错误处理**：检查控制台输出了解加载状态

## 🐛 故障排除

**问题：文件加载失败**
- 检查文件路径是否正确
- 确认文件存在且格式正确
- 查看控制台错误信息

**问题：控制面板不显示**
- 确保RiveRuntimePanel正确添加到场景
- 检查节点引用是否正确

**问题：快捷键不工作**
- 确保RiveHotkeyController的enable_hotkeys为true
- 检查是否有其他节点拦截了输入事件

## 🎉 完成！

现在你有了一个功能完整的Rive运行时加载器！可以：
- 在游戏运行时动态加载.riv文件
- 实时控制动画和场景
- 使用快捷键快速操作
- 调整状态机参数

选择适合你需求的版本开始使用吧！
