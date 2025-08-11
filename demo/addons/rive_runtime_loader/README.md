# Rive Runtime Loader Addon

一个用于在Godot运行时方便加载和控制Rive文件的插件。

## 功能特性

- 🎮 **运行时控制面板** - 在游戏运行时提供图形化界面来加载和控制Rive文件
- 🔥 **热键支持** - 使用快捷键快速切换文件、动画和场景
- 📁 **文件管理** - 浏览和加载.riv文件，支持预设文件列表
- 🎬 **动画控制** - 切换场景、动画，控制播放/暂停
- ⚙️ **输入参数** - 实时调整Rive状态机的输入参数
- 🔍 **自动检测** - 自动发现场景中的RiveViewer节点

## 安装方法

1. 将 `addons/rive_runtime_loader` 文件夹复制到你的项目中
2. 在项目设置中启用插件（如果需要编辑器功能）
3. 或者直接在场景中使用提供的组件

## 使用方法

### 方法1：使用完整演示场景

运行 `rive_loader_complete_demo.tscn` 来查看所有功能的演示。

### 方法2：添加到现有场景

1. 将 `RiveRuntimePanel` 场景实例化到你的场景中
2. 添加 `RiveHotkeyController` 节点并设置目标RiveViewer
3. 可选：使用 `RiveLoaderManager` 作为单例来管理多个RiveViewer

### 方法3：使用组件

```gdscript
# 在你的脚本中
extends Control

@onready var rive_viewer: RiveViewer = $RiveViewer
var loader_manager: Node

func _ready():
    # 创建加载器管理器
    loader_manager = preload("res://addons/rive_runtime_loader/rive_loader_manager.gd").new()
    add_child(loader_manager)
    
    # 注册RiveViewer
    loader_manager.register_viewer(rive_viewer)
    
    # 加载文件
    await loader_manager.load_file(rive_viewer, "res://examples/juice.riv")
```

## 快捷键列表

| 快捷键 | 功能 |
|--------|------|
| F1 | 切换控制面板显示/隐藏 |
| F2 | 加载下一个预设文件 |
| F3 | 加载上一个预设文件 |
| F4 | 重新加载当前文件 |
| 空格 | 暂停/播放动画 |
| R | 重置当前动画 |
| 1-5 | 加载预设文件 0-4 |
| ← → | 切换到上一个/下一个动画 |
| ↑ ↓ | 切换到上一个/下一个场景 |

## 组件说明

### RiveRuntimePanel
运行时控制面板，提供图形化界面来：
- 浏览和加载.riv文件
- 选择和切换RiveViewer节点
- 控制场景和动画播放
- 调整输入参数

### RiveLoaderManager
加载器管理器，提供：
- RiveViewer注册和管理
- 文件加载和验证
- 预设文件管理
- 批量操作功能

### RiveHotkeyController
热键控制器，提供：
- 快捷键映射和处理
- 动画和场景切换
- 文件加载控制

## 示例场景

- `rive_loader_demo.tscn` - 基本使用示例
- `rive_loader_complete_demo.tscn` - 完整功能演示

## 自定义配置

你可以通过修改以下文件来自定义功能：

- `rive_loader_manager.gd` 中的 `preset_files` 数组来设置默认的预设文件
- `rive_hotkey_controller.gd` 中的 `hotkey_actions` 字典来自定义快捷键映射

## 注意事项

- 确保你的项目中已经正确安装了Rive扩展
- .riv文件需要放在项目的资源目录中
- 某些功能需要RiveViewer节点已经添加到场景树中

## 故障排除

1. **控制面板不显示** - 检查RiveRuntimePanel是否正确添加到场景中
2. **快捷键不工作** - 确保RiveHotkeyController的enable_hotkeys属性为true
3. **文件加载失败** - 检查文件路径是否正确，文件是否存在

## 许可证

本插件遵循与Rive扩展相同的许可证。
