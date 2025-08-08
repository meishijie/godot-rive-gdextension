# RiveViewer 动画切换偏移问题修复记录

## 问题描述

在使用RiveViewer组件时，当动画切换到"none"状态，然后再切换回其他动画时，会出现动画位置偏移的问题。动画不会回到原来的正确位置，而是保持偏移状态。

## 问题分析

### 初始调试
1. **添加调试信息**：在关键方法中添加了详细的调试输出
   - `_on_animation_changed`：记录动画切换过程
   - `_on_size_changed`：记录尺寸变化
   - `_on_transform_changed`：记录变换处理
   - `width()`/`height()`：记录尺寸获取

### 发现的问题
1. **时序问题**：动画切换时，组件尺寸为1x1像素，说明切换发生在正确尺寸设置之前
2. **变换重置问题**：当动画切换到"none"状态时，变换矩阵没有正确重置
3. **渲染时机问题**：在`_on_transform_changed`中立即重绘导致状态不一致

## 解决方案

### 1. 注释动画切换时的强制resize
**文件**: `rive_viewer_base.cpp`
**方法**: `_on_animation_changed`

```cpp
// COMMENTED OUT: Ensure proper dimensions are set by triggering size change
// UtilityFunctions::print("[RiveViewer] Triggering size change: " + String::num(width()) + "x" + String::num(height()));
// _on_size_changed(width(), height());
```

**原因**: 避免在动画切换时强制触发尺寸变化，防止尺寸不匹配导致的偏移问题。

### 2. 注释_on_transform_changed中的立即渲染
**文件**: `rive_viewer_base.cpp`
**方法**: `_on_transform_changed`

```cpp
// PackedByteArray bytes = redraw();
// // Update image and texture with new frame data
// if (bytes.size() > 0 && !is_null(image) && !is_null(texture)) {
//     // Ensure image size matches expected size
//     int expected_size = width() * height() * 4; // RGBA8 = 4 bytes per pixel
//     if (bytes.size() == expected_size) {
//         // image->set_data(width(), height(), false, Image::FORMAT_RGBA8, bytes);
//         // texture->set_image(image);
//         // owner->queue_redraw();
//     }
// }
```

**原因**: 避免在变换改变时立即重绘，让渲染逻辑只在`frame`方法中统一处理，确保状态一致性。

### 3. 保留的改进
**文件**: `rive_viewer_base.cpp`
**方法**: `_on_animation_changed`

保留了以下改进：
- 实例重置：`inst.reset()`
- 强制变换重新计算：`inst.current_transform = inst.get_transform()`
- 无动画状态的正确处理

## 核心原理

### 渲染流程分离
- **变换更新**：在`_on_transform_changed`中只更新变换矩阵，不立即渲染
- **统一渲染**：所有渲染逻辑集中在`frame`方法中处理
- **避免冲突**：防止多个地方同时触发渲染导致的状态不一致

### 时序控制
- **避免强制resize**：不在动画切换时强制触发尺寸变化
- **自然流程**：让Godot的自然更新流程处理尺寸和渲染

## 测试验证

### 测试步骤
1. 启动项目，观察初始动画状态
2. 切换动画到"none"状态
3. 再切换回其他动画
4. 验证动画位置是否正确，无偏移

### 预期结果
- 动画切换流畅，无位置偏移
- 尺寸变化正常处理
- 渲染性能稳定

## 调试信息保留

为了便于后续问题排查，保留了关键的调试输出：
- 动画切换过程记录
- 变换计算过程记录
- 实例重置确认
- 尺寸变化监控

## 文件修改清单

### 主要修改文件
- `/src/rive_viewer_base.cpp`

### 修改内容
1. `_on_animation_changed`方法：注释强制resize调用
2. `_on_transform_changed`方法：注释立即渲染逻辑
3. 保留调试信息输出

## 注意事项

1. **不要恢复被注释的代码**：这些注释是解决偏移问题的关键
2. **保持frame方法完整**：确保正常的动画播放和渲染功能
3. **监控性能**：虽然解决了偏移问题，但要注意渲染性能

## 后续优化建议

1. **清理调试代码**：在确认稳定后，可以移除部分调试输出
2. **性能优化**：监控渲染性能，必要时进行优化
3. **边界情况测试**：测试更多动画切换场景

---

**修复日期**: 2024年12月
**修复状态**: 已验证有效
**影响范围**: RiveViewer动画切换功能