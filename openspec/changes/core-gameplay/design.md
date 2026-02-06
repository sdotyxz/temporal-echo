# 核心玩法技术设计

## 架构概览

```
Game (Node2D)
├── GameManager (Node) - 全局游戏状态
├── Player (CharacterBody2D) - 玩家控制器
│   ├── HistoryRecorder - 位置/瞄准历史
│   ├── Sprite2D
│   └── CollisionShape2D
├── Echo (CharacterBody2D) [动态生成] - 时间回声
│   ├── EchoShooter - 生成时开火
│   └── Sprite2D
├── Boss (CharacterBody2D) - 敌人AI
│   ├── PursuitAI - 追击玩家
│   ├── HealthSystem - 10 HP
│   └── Sprite2D
├── Bullet (Area2D) [动态生成] - 投射物
│   ├── PhysicsMover - 线性移动
│   ├── BounceHandler - 墙壁碰撞
│   └── Sprite2D
├── TrajectoryPreview (Node2D) - 瞄准辅助
│   └── Line2D - 虚线轨迹
├── ArenaWalls (Node2D) - 静态障碍物
│   └── Wall[8] (StaticBody2D)
└── UI (CanvasLayer) - HUD元素
    ├── BossHPBar
    ├── PlayerHPBar
    └── TimerLabel
```

## 核心系统

### 1. 历史记录器

**目的**: 记录玩家状态用于回声生成

**数据结构**:
```gdscript
class HistoryFrame:
    position: Vector2
    aim_direction: Vector2
    timestamp: float

var history: Array[HistoryFrame] = []
const HISTORY_SIZE = 180  # 3秒 @ 60fps
```

**算法**:
```gdscript
func _physics_process(delta):
    # 添加当前帧
    history.append(HistoryFrame.new(position, aim_direction, Time.get_time_dict_from_system()))
    
    # 移除旧帧
    if history.size() > HISTORY_SIZE:
        history.pop_front()
    
    # 检查回声生成
    if should_spawn_echo:
        var echo_frame = history[history.size() - HISTORY_SIZE]
        spawn_echo(echo_frame.position, echo_frame.aim_direction)
```

**复杂度**: 每帧 O(1) (循环缓冲区)

### 2. 子弹物理

**移动**:
```gdscript
velocity = direction * speed
position += velocity * delta
```

**反弹检测**:
```gdscript
func _on_body_entered(body):
    if body.is_in_group("walls"):
        bounce(body)

func bounce(wall):
    # 基于碰撞侧计算法线
    var to_wall = wall.global_position - global_position
    if abs(to_wall.x) > abs(to_wall.y):
        velocity.x = -velocity.x  # 水平反弹
    else:
        velocity.y = -velocity.y  # 垂直反弹
    
    bounce_count += 1
    speed *= 1.2  # 20%加速
    update_color()
```

**边界情况**:
- 角落命中：优先水平反弹
- 多墙壁：每帧处理一个
- 最大反弹：第3次反弹后 queue_free()

### 3. 回声生成

**触发**: 玩家开火后3秒

**流程**:
```gdscript
func spawn_echo(spawn_pos, aim_dir):
    var echo = EchoScene.instantiate()
    echo.global_position = spawn_pos
    echo.aim_direction = aim_dir
    get_parent().add_child(echo)
    
    # 回声0.1秒延迟后自动开火
    await get_tree().create_timer(0.1).timeout
    echo.fire()
```

**视觉**:
- 50%透明度
- 青色色调 (#40E0D0)
- 幽灵拖尾效果（3帧淡出）

### 4. Boss AI

**状态机**:
```gdscript
enum State { PURSUIT, ATTACK, DEAD }

func _physics_process(delta):
    match current_state:
        State.PURSUIT:
            var dir = (player.position - position).normalized()
            velocity = dir * speed
            move_and_slide()
            
            # 面向玩家
            look_at(player.position)
```

**生命系统**:
```gdscript
var hp = 10

func take_damage(amount):
    hp -= amount
    flash_red()
    
    if hp <= 0:
        die()

func die():
    emit_signal("boss_defeated")
    queue_free()
```

### 5. 伤害检测

**双重命中窗口**:
```gdscript
var last_hit_time = 0
const DUAL_HIT_WINDOW = 0.1  # 秒

func take_damage(amount):
    var current_time = Time.get_time_dict_from_system()
    
    if current_time - last_hit_time < DUAL_HIT_WINDOW:
        # 双重命中 - 造成2点伤害
        hp -= 2
    else:
        # 单次命中 - 造成1点伤害
        hp -= 1
    
    last_hit_time = current_time
```

### 6. 轨迹预览

**RayCast计算**:
```gdscript
func calculate_trajectory():
    var points = [player.position]
    var current_pos = player.position
    var current_dir = aim_direction
    
    for i in range(3):  # 最多3次反弹
        var ray = PhysicsRayQueryParameters2D.create(
            current_pos,
            current_pos + current_dir * 1000
        )
        var result = space_state.intersect_ray(ray)
        
        if result:
            points.append(result.position)
            current_pos = result.position
            current_dir = current_dir.bounce(result.normal)
        else:
            points.append(current_pos + current_dir * 500)
            break
    
    return points
```

**渲染**:
- 虚线纹理的Line2D
- 瞄准时每帧更新
- 射击后隐藏

## 音频系统

**事件**:
| 事件 | 音效 | 音调 |
|------|------|------|
| 开火 | laser_charge.wav | 1.0 |
| 回声生成 | time_warp.wav | 1.2 |
| 反弹1 | metallic_ping.wav | 1.0 |
| 反弹2 | metallic_ping.wav | 1.1 |
| 反弹3 | metallic_ping.wav | 1.2 |
| 命中 | deep_impact.wav | 1.0 |
| 玩家受伤 | error_buzz.wav | 1.0 |

**实现**:
```gdscript
class AudioManager:
    func play_sound(event, pitch_mod = 1.0):
        var player = AudioStreamPlayer.new()
        player.stream = load("res://assets/audio/" + event + ".wav")
        player.pitch_scale = pitch_mod
        add_child(player)
        player.play()
```

## 文件结构

```
src/
├── player.gd              # 玩家控制器 + 历史
├── echo.gd                # 时间回声实体
├── bullet.gd              # 投射物物理
├── boss.gd                # 敌人AI
├── trajectory_preview.gd  # 瞄准辅助
├── audio_manager.gd       # 音效系统
└── game_manager.gd        # 全局状态

scenes/
├── game.tscn              # 主游戏场景
├── player.tscn            # 玩家预制件
├── echo.tscn              # 回声预制件
├── bullet.tscn            # 子弹预制件
├── boss.tscn              # Boss预制件
└── wall.tscn              # 墙预制件

assets/
└── audio/
    ├── laser_charge.wav
    ├── time_warp.wav
    ├── metallic_ping.wav
    ├── deep_impact.wav
    └── error_buzz.wav
```

## 性能考虑

### 内存
- 历史缓冲区：180帧 × (8字节位置 + 8字节方向) ≈ 2.9 KB
- 最多子弹：100 × ~50字节 ≈ 5 KB
- 总计：远低于100MB目标

### CPU
- 历史记录：每帧 O(1)
- 物理：O(n)，n = 子弹数量
- 目标：60 FPS下每帧 < 1ms

### 渲染
- 使用Godot内置批处理
- 限制粒子（可选）
- 简单精灵（有色矩形可接受）

## 测试策略

### 单元测试（如果时间允许）
- 反弹角度计算
- 历史缓冲区溢出
- 双重命中检测

### 集成测试
- 回声恰好3秒后生成
- Boss可在合理时间内击败
- 玩家可以赢/输

### 手动QA
- 输入响应
- 视觉清晰
- 音频时机

## 风险缓解

| 风险 | 缓解措施 |
|------|---------|
| 回声时机不准 | 使用帧计数，非实时 |
| 反弹角度错误 | 简化为轴对齐墙壁 |
| 性能问题 | 限制最多50颗子弹 |
| 时间超支 | 首先削减轨迹预览 |

## 依赖项

- 仅Godot 4.6内置功能
- 无外部插件
- Kenney音频资源（可选）
