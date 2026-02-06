# Core Gameplay Technical Design

## Architecture Overview

```
Game (Node2D)
├── GameManager (Node) - Global game state
├── Player (CharacterBody2D) - Player controller
│   ├── HistoryRecorder - Position/aim history
│   ├── Sprite2D
│   └── CollisionShape2D
├── Echo (CharacterBody2D) [spawned] - Temporal echo
│   ├── EchoShooter - Fires bullet on spawn
│   └── Sprite2D
├── Boss (CharacterBody2D) - Enemy AI
│   ├── PursuitAI - Follows player
│   ├── HealthSystem - 10 HP
│   └── Sprite2D
├── Bullet (Area2D) [spawned] - Projectile
│   ├── PhysicsMover - Linear movement
│   ├── BounceHandler - Wall collision
│   └── Sprite2D
├── TrajectoryPreview (Node2D) - Aim helper
│   └── Line2D - Dashed trajectory line
├── ArenaWalls (Node2D) - Static obstacles
│   └── Wall[8] (StaticBody2D)
└── UI (CanvasLayer) - HUD elements
    ├── BossHPBar
    ├── PlayerHPBar
    └── TimerLabel
```

## Core Systems

### 1. History Recorder

**Purpose**: Record player state for echo spawning

**Data Structure**:
```gdscript
class HistoryFrame:
    position: Vector2
    aim_direction: Vector2
    timestamp: float

var history: Array[HistoryFrame] = []
const HISTORY_SIZE = 180  # 3 seconds at 60fps
```

**Algorithm**:
```gdscript
func _physics_process(delta):
    # Add current frame
    history.append(HistoryFrame.new(position, aim_direction, Time.get_time_dict_from_system()))
    
    # Remove old frames
    if history.size() > HISTORY_SIZE:
        history.pop_front()
    
    # Check for echo spawn
    if should_spawn_echo:
        var echo_frame = history[history.size() - HISTORY_SIZE]
        spawn_echo(echo_frame.position, echo_frame.aim_direction)
```

**Complexity**: O(1) per frame (circular buffer)

### 2. Bullet Physics

**Movement**:
```gdscript
velocity = direction * speed
position += velocity * delta
```

**Bounce Detection**:
```gdscript
func _on_body_entered(body):
    if body.is_in_group("walls"):
        bounce(body)

func bounce(wall):
    # Calculate normal based on collision side
    var to_wall = wall.global_position - global_position
    if abs(to_wall.x) > abs(to_wall.y):
        velocity.x = -velocity.x  # Horizontal bounce
    else:
        velocity.y = -velocity.y  # Vertical bounce
    
    bounce_count += 1
    speed *= 1.2  # 20% speed increase
    update_color()
```

**Edge Cases**:
- Corner hits: Prioritize horizontal bounce
- Multiple walls: Process one per frame
- Max bounces: Queue_free() after 3rd bounce

### 3. Echo Spawning

**Trigger**: 3 seconds after player fires

**Process**:
```gdscript
func spawn_echo(spawn_pos, aim_dir):
    var echo = EchoScene.instantiate()
    echo.global_position = spawn_pos
    echo.aim_direction = aim_dir
    get_parent().add_child(echo)
    
    # Echo auto-fires after 0.1s delay
    await get_tree().create_timer(0.1).timeout
    echo.fire()
```

**Visuals**:
- 50% opacity
- Cyan tint (#40E0D0)
- Ghost trail effect (3 frame fade)

### 4. Boss AI

**State Machine**:
```gdscript
enum State { PURSUIT, ATTACK, DEAD }

func _physics_process(delta):
    match current_state:
        State.PURSUIT:
            var dir = (player.position - position).normalized()
            velocity = dir * speed
            move_and_slide()
            
            # Face player
            look_at(player.position)
```

**Health System**:
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

### 5. Damage Detection

**Dual Hit Window**:
```gdscript
var last_hit_time = 0
const DUAL_HIT_WINDOW = 0.1  # seconds

func take_damage(amount):
    var current_time = Time.get_time_dict_from_system()
    
    if current_time - last_hit_time < DUAL_HIT_WINDOW:
        # Dual hit - deal 2 damage
        hp -= 2
    else:
        # Single hit - deal 1 damage
        hp -= 1
    
    last_hit_time = current_time
```

### 6. Trajectory Preview

**RayCast Calculation**:
```gdscript
func calculate_trajectory():
    var points = [player.position]
    var current_pos = player.position
    var current_dir = aim_direction
    
    for i in range(3):  # Max 3 bounces
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

**Rendering**:
- Line2D with dashed texture
- Updates every frame while aiming
- Hidden after firing

## Audio System

**Events**:
| Event | Sound | Pitch |
|-------|-------|-------|
| Fire | laser_charge.wav | 1.0 |
| Echo Spawn | time_warp.wav | 1.2 |
| Bounce 1 | metallic_ping.wav | 1.0 |
| Bounce 2 | metallic_ping.wav | 1.1 |
| Bounce 3 | metallic_ping.wav | 1.2 |
| Hit | deep_impact.wav | 1.0 |
| Player Hit | error_buzz.wav | 1.0 |

**Implementation**:
```gdscript
class AudioManager:
    func play_sound(event, pitch_mod = 1.0):
        var player = AudioStreamPlayer.new()
        player.stream = load("res://assets/audio/" + event + ".wav")
        player.pitch_scale = pitch_mod
        add_child(player)
        player.play()
```

## File Structure

```
src/
├── player.gd              # Player controller + history
├── echo.gd                # Temporal echo entity
├── bullet.gd              # Projectile physics
├── boss.gd                # Enemy AI
├── trajectory_preview.gd  # Aim helper
├── audio_manager.gd       # Sound system
└── game_manager.gd        # Global state

scenes/
├── game.tscn              # Main game scene
├── player.tscn            # Player prefab
├── echo.tscn              # Echo prefab
├── bullet.tscn            # Bullet prefab
├── boss.tscn              # Boss prefab
└── wall.tscn              # Wall prefab

assets/
└── audio/
    ├── laser_charge.wav
    ├── time_warp.wav
    ├── metallic_ping.wav
    ├── deep_impact.wav
    └── error_buzz.wav
```

## Performance Considerations

### Memory
- History buffer: 180 frames × (8 bytes position + 8 bytes direction) ≈ 2.9 KB
- Max bullets: 100 × ~50 bytes ≈ 5 KB
- Total: Well under 100MB target

### CPU
- History recording: O(1) per frame
- Physics: O(n) where n = bullet count
- Target: < 1ms per frame for 60 FPS

### Rendering
- Use Godot's built-in batching
- Limit particles (optional)
- Simple sprites (colored rectangles acceptable)

## Testing Strategy

### Unit Tests (if time permits)
- Bounce angle calculation
- History buffer overflow
- Dual hit detection

### Integration Tests
- Echo spawns exactly 3s after fire
- Boss defeatable in reasonable time
- Player can win/lose

### Manual QA
- Input responsiveness
- Visual clarity
- Audio timing

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Echo timing off | Use frame count, not real-time |
| Bounce angle wrong | Simplify to axis-aligned walls |
| Performance issues | Limit max bullets to 50 |
| Time overrun | Cut trajectory preview first |

## Dependencies

- Godot 4.6 built-in features only
- No external plugins
- Kenney audio assets (optional)
