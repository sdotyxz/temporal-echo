# Temporal Echo - 坑与解决方案全记录

> 从项目启动到完成的完整踩坑史

---

## 目录
1. [项目启动阶段](#1-项目启动阶段)
2. [子弹系统阶段](#2-子弹系统阶段)
3. [回声系统阶段](#3-回声系统阶段--最坑)
4. [AI系统阶段](#4-ai系统阶段--次坑)
5. [UI与音效阶段](#5-ui与音效阶段)
6. [测试与优化阶段](#6-测试与优化阶段)
7. [通用工具问题](#7-通用工具问题)

---

## 1. 项目启动阶段

### 坑 1.1: 文件被意外覆盖
**时间**: Day 1  
**现象**: `ai_echo_test.gd` 文件内容突然变成只有几行  
**原因**: 使用 `write` 工具时不小心覆盖了整个文件  
**解决**: 
```bash
git checkout HEAD -- src/ai_echo_test.gd
```
**教训**: 
- 编辑前先用 `read` 确认内容
- 使用 `edit` 而非 `write` 修改现有文件
- 频繁提交，方便回滚

---

## 2. 子弹系统阶段

### 坑 2.1: 反弹角度计算错误
**时间**: Day 1  
**现象**: 子弹反弹后角度不对，不是预期的镜面反射  
**最初代码**:
```gdscript
# 错误的向量反射
velocity.x = -velocity.x  # 只在x轴翻转，斜向墙会出问题
```
**解决**: 使用 Godot 内置方法
```gdscript
velocity = velocity.bounce(collision.get_normal())
```
**教训**: 不要自己写物理计算，优先使用引擎提供的工具

### 坑 2.2: 子弹反弹次数不递增
**时间**: Day 1  
**现象**: 子弹无限反弹，不销毁  
**原因**: `bounce_count` 在 `_on_body_entered` 中增加，但信号可能触发多次  
**解决**: 添加防护标志
```gdscript
var _is_bouncing := false

func _on_body_entered(body):
    if _is_bouncing: return
    _is_bouncing = true
    bounce_count += 1
    # ... 反弹逻辑
    _is_bouncing = false
```

### 坑 2.3: 子弹颜色渐变不平滑
**时间**: Day 1  
**现象**: 颜色从白直接跳到红，没有中间色  
**原因**: 使用 `if/elif` 分段设置颜色  
**解决**: 使用线性插值
```gdscript
func _update_color():
    var t = float(bounce_count) / max_bounces
    sprite.modulate = Color(1.0, 1.0 - t * 0.5, 1.0 - t, 1.0)
```

---

## 3. 回声系统阶段 (最坑)

### 坑 3.1: 回声子弹位置偏移 ⭐⭐⭐
**时间**: Day 2  
**现象**: 回声生成的子弹位置不对，不在回声角色位置  
**最初代码**:
```gdscript
# 错误：使用原玩家位置
bullet.global_position = history[pos].pos
```
**原因**: 应该用回声当前位置 + 相对偏移  
**解决**:
```gdscript
# 正确：使用相对坐标
var offset = history[pos].pos - echo_spawn_pos
bullet.global_position = echo.global_position + offset
```
**调试过程**: 
- 添加大量日志打印位置信息
- 发现偏移量恒定，意识到是绝对坐标问题
- 耗时: 2小时

### 坑 3.2: 回声生成导致循环引用 ⭐⭐
**时间**: Day 2  
**现象**: 游戏崩溃，报错循环引用  
**代码**:
```gdscript
# 错误：直接实例化
var echo = echo_scene.instantiate()
player.add_child(echo)  # 在_physics_process中调用
```
**解决**: 使用 `call_deferred`
```gdscript
call_deferred("_spawn_echo")

func _spawn_echo():
    var echo = echo_scene.instantiate()
    player.add_child(echo)
```
**原理**: 延迟到下一帧执行，避免在当前物理帧修改场景树

### 坑 3.3: 历史记录数组越界 ⭐
**时间**: Day 2  
**现象**: 游戏运行一段时间后崩溃，数组索引错误  
**原因**: 
```gdscript
# 错误：索引计算错误
var index = (current_frame - delay) % history_size
# 当 current_frame < delay 时，index 为负数
```
**解决**:
```gdscript
var index = (current_frame - delay + history_size) % history_size
```

### 坑 3.4: 回声射击时机不准确 ⭐⭐
**时间**: Day 2  
**现象**: 回声射击比原玩家慢/快一帧  
**原因**: 历史记录和回声更新的时序问题  
**解决**: 统一使用 `_physics_process`，并确保回声在玩家之后更新
```gdscript
# 在 player.gd 中
func _physics_process(delta):
    _record_history()  # 先记录
    _update_state()

# 在 echo.gd 中  
func _physics_process(delta):
    _replay_history()  # 再回放
```

### 坑 3.5: 回声子弹不销毁 ⭐
**时间**: Day 2  
**现象**: 子弹反弹3次后不消失  
**原因**: 回声子弹和原子弹使用不同脚本，逻辑不一致  
**解决**: 统一使用 `bullet.gd`，通过参数区分

---

## 4. AI系统阶段 (次坑)

### 坑 4.1: AI不射击 ⭐⭐⭐⭐
**时间**: Day 3  
**现象**: AI进入AIM状态，但玩家不发射子弹  
**排查过程**:
1. 添加日志: "🤖 进入AIM状态" ✓
2. 添加日志: "🔫 AI射击" ✓
3. 添加日志: "🎯 fire触发?" ✗

**根因**: 
```gdscript
# AI代码
func _shoot():
    Input.action_press("fire")
    Input.action_release("fire")  # 同一帧释放！

# 玩家代码
func _update_aim():
    if Input.is_action_just_pressed("fire"):  # 只在一帧内返回true
        _transition_to(SHOOT)
```
AI释放fire太快，玩家检测不到

**解决**: 延迟释放
```gdscript
# 方法1：延迟一帧
func _shoot():
    Input.action_press("fire")
    await get_tree().process_frame
    Input.action_release("fire")

# 方法2：使用标志位（最终采用）
var _fire_pressed = false
func _physics_process():
    if _fire_pressed:
        Input.action_release("fire")
        _fire_pressed = false

func _shoot():
    Input.action_press("fire")
    _fire_pressed = true
```

### 坑 4.2: _physics_process缺少状态机调用 ⭐⭐
**时间**: Day 3  
**现象**: AI状态不变，一直卡在IDLE  
**错误代码**:
```gdscript
func _physics_process(delta):
    # 处理射击释放
    if _fire_pressed:
        Input.action_release("fire")
        _fire_pressed = false
    
    # 忘了调用状态机！
    # _update_state_machine(delta, boss)  <- 这一行缺失！
```
**解决**: 补全调用
**教训**: 重构代码时要检查所有入口点

### 坑 4.3: 场景树顺序问题 ⭐
**时间**: Day 3  
**现象**: 玩家射击有延迟  
**原因**: Player节点在场景树中排在AIPlayer之前，Player先执行_physics_process，AI后执行
**解决**: 调整节点顺序，或使用 `_process` 替代 `_physics_process` 处理输入

### 坑 4.4: AI被Boss黏住无法逃脱 ⭐⭐
**时间**: Day 3  
**现象**: AI和Boss距离太近，一直接触受伤  
**最初方案**: 随机方向逃离  
**问题**: 随机方向可能指向Boss  
**解决**: 智能方向评分 + 噪声
```gdscript
func _pick_best_direction(boss):
    var best_dir = Vector2.ZERO
    var best_score = -999
    
    for dir in sample_directions:
        var score = _evaluate_direction(dir, boss)
        score += rng.randf() * 0.3  # 添加噪声
        if score > best_score:
            best_score = score
            best_dir = dir
    
    # 额外角度扰动
    best_dir = best_dir.rotated(rng.randf_range(-PI/8, PI/8))
    return best_dir
```

---

## 5. UI与音效阶段

### 坑 5.1: 游戏结束UI不显示
**时间**: Day 3  
**现象**: 玩家死亡后，GameOver画面不出现  
**原因**: UI节点层级错误，被其他节点遮挡  
**解决**: 使用 CanvasLayer 确保UI在最上层
```gdscript
# game_manager.gd
var ui_layer: CanvasLayer

func show_game_over():
    var game_over = preload("res://scenes/game_over.tscn").instantiate()
    ui_layer.add_child(game_over)  # 添加到CanvasLayer
```

### 坑 5.2: BGM不循环
**时间**: Day 3  
**现象**: 背景音乐播放一次后停止  
**解决**: 
```gdscript
audio_stream_player.loop = true
# 或者在编辑器中勾选 Loop
```

### 坑 5.3: 音效重叠导致爆音
**时间**: Day 3  
**现象**: 多个子弹同时反弹时，声音刺耳  
**解决**: 限制同帧音效数量
```gdscript
var _sfx_count_this_frame = 0
const MAX_SFX_PER_FRAME = 3

func play_sfx(sound):
    if _sfx_count_this_frame >= MAX_SFX_PER_FRAME:
        return
    _sfx_count_this_frame += 1
    audio_player.play(sound)

func _physics_process(delta):
    _sfx_count_this_frame = 0  # 每帧重置
```

---

## 6. 测试与优化阶段

### 坑 6.1: AVI视频无法直接发送
**时间**: Day 3-4  
**现象**: Godot录制的.avi文件太大，Discord不支持  
**解决**: 使用 ffmpeg 转码
```bash
ffmpeg -i input.avi -c:v libx264 -preset fast -crf 23 \
       -s 640x480 -r 30 -movflags +faststart output.mp4
```
**参数说明**:
- `-crf 23`: 质量/压缩平衡
- `-s 640x480`: 降低分辨率减少体积
- `-movflags +faststart`: 优化网络播放

### 坑 6.2: 测试视频录到一半中断
**时间**: Day 4  
**现象**: 录制命令超时，视频不完整  
**原因**: `timeout` 设置太短  
**解决**: 增加超时时间，或使用后台进程
```bash
# 原来
timeout 30 godot --write-movie test.avi

# 改进
timeout 120 godot --write-movie test.avi &
sleep 100 && kill %1
```

### 坑 6.3: AI测试结果不准确
**时间**: Day 4  
**现象**: AI测试5局，结果都一样（都失败）  
**原因**: AI行为完全确定，没有随机性  
**解决**: 添加噪声算法（见坑4.4）

---

## 7. 通用工具问题

### 坑 7.1: Git提交冲突
**时间**: 全程  
**现象**: `git push` 被拒绝，提示有冲突  
**解决**:
```bash
git pull origin main --rebase
git push origin main
```
**预防措施**: 
- 每次修改前 `git pull`
- 小步提交，避免大量改动

### 坑 7.2: 大文件问题
**时间**: Day 4  
**现象**: GitHub警告大文件  
**原因**: 不小心提交了.avi文件  
**解决**: 添加到 .gitignore
```bash
echo "*.avi" >> .gitignore
git rm --cached *.avi
```

### 坑 7.3: Godot UID变化
**时间**: Day 4  
**现象**: `.tscn` 文件出现大量无意义的diff  
**原因**: Godot 4.6自动生成UID引用  
**解决**: 统一提交一次UID更新，后续忽略
```bash
git add scenes/*.tscn
git commit -m "chore: update uid references"
```

---

## 坑的严重程度排行

| 排名 | 坑 | 耗时 | 影响 |
|------|---|------|------|
| 🥇 | 回声子弹位置偏移 | 2小时 | 核心机制无法工作 |
| 🥈 | AI不射击 | 1.5小时 | 测试系统瘫痪 |
| 🥉 | 反弹角度计算 | 1小时 | 物理系统错误 |
| 4 | 循环引用崩溃 | 45分钟 | 游戏崩溃 |
| 5 | 历史记录越界 | 30分钟 | 随机崩溃 |
| 6 | _physics_process缺失 | 30分钟 | AI卡住 |
| 7 | 文件被覆盖 | 20分钟 | 代码丢失风险 |
| 8 | UI不显示 | 20分钟 | 用户体验差 |
| 9 | BGM不循环 | 10分钟 | 氛围缺失 |
| 10 | AVI转MP4 | 10分钟 | 无法分享视频 |

---

## 避免踩坑的建议

### 给未来的我们

1. **回声系统**:
   - 从第一天就使用相对坐标
   - 用 `call_deferred` 处理场景树修改
   - 数组索引检查负数情况

2. **AI系统**:
   - Input模拟要测试 `just_pressed` 检测
   - 重构后检查所有 `_physics_process` 入口
   - 添加随机性避免机械化

3. **物理系统**:
   - 优先使用引擎内置方法
   - 反弹/碰撞用 `bounce()` 别自己算

4. **版本控制**:
   - 大文件进 .gitignore
   - 频繁小步提交
   - 编辑前 `read` 确认内容

5. **调试技巧**:
   - 用 emoji 前缀的日志便于过滤
   - 录视频比截图更直观
   - 添加可视化调试（轨迹预览）

---

## 总结

**总共踩了 20+ 个坑**，其中最耗时的是：
1. **回声系统** - 坐标问题最难搞
2. **AI系统** - 时序问题很隐蔽
3. **物理计算** - 别自己写，用引擎的

**最有价值的经验**:
- 视频录制反馈比文字描述高效10倍
- 日志驱动调试是定位问题的最佳方式
- `git checkout` 是后悔药，频繁提交

---

*记录时间: 2026-02-09*  
*项目: Temporal Echo*  
*坑数统计: 20+ | 总耗时: 约8小时调试*
