---
id: core-gameplay
status: active
priority: high
created: 2026-02-06
author: sdon
---

# Core Gameplay - Temporal Echo

## Overview

Implement the complete core gameplay loop for Temporal Echo, a TriJam #358 entry featuring temporal echo mechanics where players coordinate with their 3-second-ago self to defeat enemies.

## Game Concept

**One-Sentence Pitch:**  
"Fire your temporal echo - 3 seconds later, your past self rebounds from walls to fight alongside you."

**Core Mechanic:**  
Players shoot "temporal echoes" that don't interact with enemies immediately. After a 3-second delay, a ghost of the player appears at their firing position and fires the same shot, creating cross-fire opportunities.

## Gameplay Loop

### Basic Loop
1. **Aim & Fire** → Shoot at walls to set up rebound angles
2. **Move** → Position yourself for the cross-fire moment  
3. **Temporal Echo Activates** → 3-second-ago self fires from past position
4. **Coordinated Strike** → Present + Past fire simultaneously at the enemy
5. **Repeat** → Chain multiple echoes for complex patterns

### Strategy Spectrum

| Skill Level | Strategy | Result |
|-------------|----------|--------|
| **Beginner** | Fire → Retreat → Let echo hit | Safe but slow |
| **Intermediate** | Fire → Flank → Cross-fire | Moderate efficiency |
| **Advanced** | Chain 2-3 echoes → Multi-direction assault | Maximum damage |

## Technical Requirements

- **Engine**: Godot 4.6
- **Resolution**: 800x600
- **Input**: Keyboard (WASD) + Mouse
- **Target FPS**: 60

## Artifacts

### 1. Player System (`src/player.gd`)
- Movement with WASD
- History recording (180 frames = 3 seconds)
- Echo spawning logic
- Dash ability (space)

### 2. Bullet System (`src/bullet.gd`)  
- Physics-based movement
- Wall bouncing (mirror reflection)
- Max 3 bounces
- Speed increase +20% per bounce
- Color progression: white → yellow → orange → red

### 3. Echo System (`src/echo.gd`)
- Spawns at historical player position
- Fires in historical aim direction
- Semi-transparent cyan visual
- Invulnerable (ghost state)
- 2-second lifetime

### 4. Boss System (`src/boss.gd`)
- Single boss: Chronos Sentinel
- 10 HP (requires 5 dual-hits)
- Slow pursuit AI (80 px/s)
- Always faces player

### 5. Game Scene (`scenes/game.tscn`)
- Symmetric arena layout
- 8 steel walls for rebound points
- Boss in center
- UI overlay (HP bars, timer)

### 6. Trajectory Preview (`src/trajectory_preview.gd`)
- Dashed line showing predicted path
- 3-second marker indicator
- RayCast-based calculation

### 7. Audio Manager (`src/audio_manager.gd`)
- Sound effects (Kenney Digital Audio)
- Music loop (30-second ambient)
- Pitch modulation on bounce

## Dependencies

- Godot 4.6
- Kenney Digital Audio Pack (sound effects)
- Kenney 1-bit Pack (optional sprites)

## 3-Hour Development Timeline

| Time | Task | Deliverable |
|------|------|-------------|
| 0:00-0:10 | Project setup + Player movement | Moving character |
| 0:10-0:35 | History recording system | Echo spawns after 3s |
| 0:35-0:55 | Bullet physics + bouncing | Bullets rebound correctly |
| 0:55-1:15 | Trajectory preview | Dashed line shows path |
| 1:15-1:35 | Boss AI + HP system | Boss chases player |
| 1:35-2:00 | Damage system + win/lose | Can kill boss |
| 2:00-2:25 | Audio + screen effects | Juice added |
| 2:25-2:50 | Polish + bug fixes | Smooth experience |
| 2:50-3:00 | Build + Itch.io upload | Submittable game |

## Design Pillars

1. **Cognitive Clarity Over Visual Spectacle**  
   Every element must answer: "What is happening and why?"

2. **Skill Expression Through Timing**  
   Same setup, different execution times = different results

3. **One Deep Mechanic Over Many Shallow Ones**  
   Temporal echo is the star. Everything else supports it.

## Notes

Focus on ONE boss enemy for 3-hour scope. Symmetric arena simplifies learning. Trajectory preview is critical for understanding. Audio feedback essential for timing.
