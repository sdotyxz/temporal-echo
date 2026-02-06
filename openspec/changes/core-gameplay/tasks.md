# Core Gameplay Tasks

## Phase 1: Foundation (0:00-0:35)

### 1.1 Player Movement
**Time**: 10 minutes
**File**: `src/player.gd`, `scenes/player.tscn`

- [ ] 1.1.1 Create Player scene with CharacterBody2D
- [ ] 1.1.2 Implement WASD movement (200 px/s)
- [ ] 1.1.3 Add mouse aim tracking (sprite rotation)
- [ ] 1.1.4 Create basic player sprite (blue rectangle)
- [ ] 1.1.5 Add collision shape (32x32)

**Acceptance Criteria**:
- Player moves smoothly in all directions
- Sprite rotates to face mouse cursor
- No input lag

---

### 1.2 History Recording System
**Time**: 15 minutes
**File**: `src/player.gd`

- [ ] 1.2.1 Create HistoryFrame class (position, aim_direction)
- [ ] 1.2.2 Initialize history array (max 180 frames)
- [ ] 1.2.3 Record position every _physics_process
- [ ] 1.2.4 Record aim_direction every _physics_process
- [ ] 1.2.5 Implement circular buffer (pop_front when full)
- [ ] 1.2.6 Add get_frame_from_3s_ago() method

**Acceptance Criteria**:
- History stores exactly 3 seconds of data
- Position and aim are synchronized
- Memory usage is constant

---

### 1.3 Echo Spawning
**Time**: 10 minutes
**File**: `src/echo.gd`, `scenes/echo.tscn`, `src/player.gd`

- [ ] 1.3.1 Create Echo scene with Area2D
- [ ] 1.3.2 Add echo sprite (cyan, 50% transparent)
- [ ] 1.3.3 Implement spawn_echo(spawn_pos, aim_dir) function
- [ ] 1.3.4 Trigger echo spawn 3 seconds after player fires
- [ ] 1.3.5 Echo auto-fires bullet after 0.1s delay
- [ ] 1.3.6 Add ghost trail effect (optional)

**Acceptance Criteria**:
- Echo appears exactly 3 seconds after fire
- Echo spawns at correct historical position
- Echo fires in correct direction

---

## Phase 2: Combat (0:35-1:15)

### 2.1 Bullet Physics
**Time**: 15 minutes
**File**: `src/bullet.gd`, `scenes/bullet.tscn`

- [ ] 2.1.1 Create Bullet scene with Area2D
- [ ] 2.1.2 Implement linear movement (velocity * delta)
- [ ] 2.1.3 Add wall collision detection
- [ ] 2.1.4 Implement mirror bounce (45° in = 45° out)
- [ ] 2.1.5 Track bounce count (max 3)
- [ ] 2.1.6 Increase speed 20% per bounce
- [ ] 2.1.7 Destroy bullet after 3rd bounce

**Acceptance Criteria**:
- Bullets move at constant speed
- Bounces follow mirror reflection
- Speed increases correctly per bounce

---

### 2.2 Bullet Visuals
**Time**: 5 minutes
**File**: `src/bullet.gd`

- [ ] 2.2.1 Create bullet sprite (8x8 white square)
- [ ] 2.2.2 Change color per bounce count:
  - [ ] 0 bounces: White
  - [ ] 1 bounce: Yellow
  - [ ] 2 bounces: Orange
  - [ ] 3 bounces: Red
- [ ] 2.2.3 Echo bullets use cyan color
- [ ] 2.2.4 Add scale pulse on bounce (optional)

**Acceptance Criteria**:
- Color changes visibly per bounce
- Echo bullets distinct from player bullets

---

### 2.3 Trajectory Preview
**Time**: 15 minutes
**File**: `src/trajectory_preview.gd`

- [ ] 2.3.1 Create TrajectoryPreview node with Line2D
- [ ] 2.3.2 Implement raycast calculation for path prediction
- [ ] 2.3.3 Calculate up to 3 bounce points
- [ ] 2.3.4 Render dashed line while aiming
- [ ] 2.3.5 Update in real-time as player aims
- [ ] 2.3.6 Hide line after firing

**Acceptance Criteria**:
- Line shows while player is aiming
- Accurately predicts bounce points
- Performance: < 1ms calculation time

---

### 2.4 Boss AI
**Time**: 15 minutes
**File**: `src/boss.gd`, `scenes/boss.tscn`

- [ ] 2.4.1 Create Boss scene with CharacterBody2D
- [ ] 2.4.2 Add boss sprite (red rectangle, 64x64)
- [ ] 2.4.3 Implement pursuit AI (move toward player at 80 px/s)
- [ ] 2.4.4 Add "always face player" rotation
- [ ] 2.4.5 Implement 10 HP health system
- [ ] 2.4.6 Add contact damage (player loses 1 HP)

**Acceptance Criteria**:
- Boss moves toward player
- Boss sprite faces player continuously
- HP system works correctly

---

## Phase 3: Game Loop (1:15-2:00)

### 3.1 Damage System
**Time**: 10 minutes
**File**: `src/boss.gd`, `src/bullet.gd`

- [ ] 3.1.1 Implement bullet-boss collision detection
- [ ] 3.1.2 Single bullet deals 1 damage
- [ ] 3.1.3 Detect simultaneous hits (0.1s window)
- [ ] 3.1.4 Dual hit deals 2 damage
- [ ] 3.1.5 Add visual feedback (flash red for 0.1s)
- [ ] 3.1.6 Update Boss HP bar

**Acceptance Criteria**:
- Boss takes damage from bullets
- Dual hit detection works
- Visual feedback is clear

---

### 3.2 Player Health
**Time**: 5 minutes
**File**: `src/player.gd`

- [ ] 3.2.1 Implement 3 HP system
- [ ] 3.2.2 Detect boss contact damage
- [ ] 3.2.3 Add 1-second invincibility after hit
- [ ] 3.2.4 Add visual feedback (flash red)
- [ ] 3.2.5 Update Player HP bar

**Acceptance Criteria**:
- Player loses HP on boss contact
- Invincibility frames work
- Visual feedback is clear

---

### 3.3 Win/Lose Conditions
**Time**: 10 minutes
**File**: `src/game_manager.gd`

- [ ] 3.3.1 Detect Boss death (HP reaches 0)
- [ ] 3.3.2 Detect Player death (HP reaches 0)
- [ ] 3.3.3 Show Victory screen (text + timer)
- [ ] 3.3.4 Show Game Over screen
- [ ] 3.3.5 Add restart functionality (R key or button)

**Acceptance Criteria**:
- Victory triggers when Boss dies
- Game Over triggers when Player dies
- Can restart game

---

### 3.4 UI/HUD
**Time**: 10 minutes
**File**: `scenes/ui.tscn` or in `scenes/game.tscn`

- [ ] 3.4.1 Create Boss HP bar (ProgressBar)
- [ ] 3.4.2 Create Player HP bar (ProgressBar)
- [ ] 3.4.3 Add game timer (2-minute countdown)
- [ ] 3.4.4 Style UI with readable colors
- [ ] 3.4.5 Position UI in corners (don't block gameplay)

**Acceptance Criteria**:
- HP bars update in real-time
- Timer counts down correctly
- UI is readable and non-intrusive

---

## Phase 4: Polish (2:00-2:50)

### 4.1 Audio
**Time**: 15 minutes
**File**: `src/audio_manager.gd`, `assets/audio/`

- [ ] 4.1.1 Import Kenney Digital Audio files
- [ ] 4.1.2 Implement fire sound (laser_charge)
- [ ] 4.1.3 Implement echo spawn sound (time_warp)
- [ ] 4.1.4 Implement bounce sound (metallic_ping + pitch)
- [ ] 4.1.5 Implement hit sounds (deep_impact, error_buzz)
- [ ] 4.1.6 Add background music loop (30s ambient)

**Acceptance Criteria**:
- All key events have audio
- Bounce pitch increases per bounce
- Music loops seamlessly

---

### 4.2 Screen Effects
**Time**: 10 minutes
**File**: `src/game_manager.gd`

- [ ] 4.2.1 Add screen shake on dual hit (0.2s, 2px)
- [ ] 4.2.2 Add flash effect on player damage
- [ ] 4.2.3 Add chromatic aberration on echo spawn (optional)
- [ ] 4.2.4 Add motion blur on dash (optional)

**Acceptance Criteria**:
- Effects enhance gameplay
- Not overwhelming or distracting
- Performance maintained at 60 FPS

---

### 4.3 Visual Polish
**Time**: 10 minutes
**File**: Various

- [ ] 4.3.1 Add arena background (dark gray)
- [ ] 4.3.2 Style walls (steel gray rectangles)
- [ ] 4.3.3 Add player glow effect (optional)
- [ ] 4.3.4 Add boss glow effect (optional)
- [ ] 4.3.5 Ensure 60 FPS with all effects

**Acceptance Criteria**:
- Visuals are clear and readable
- Color palette matches design doc
- Performance at 60 FPS

---

### 4.4 Bug Fixes
**Time**: 15 minutes
**File**: Various

- [ ] 4.4.1 Fix echo spawn timing issues (frame-perfect)
- [ ] 4.4.2 Fix bounce angle edge cases (corners)
- [ ] 4.4.3 Fix collision detection (bullet through wall)
- [ ] 4.4.4 Fix UI update lag
- [ ] 4.4.5 Test memory leaks (none expected)

**Acceptance Criteria**:
- No game-breaking bugs
- Smooth 60 FPS gameplay
- No crashes or freezes

---

## Phase 5: Build (2:50-3:00)

### 5.1 Export
**Time**: 5 minutes
**File**: Export presets

- [ ] 5.1.1 Configure Windows export preset
- [ ] 5.1.2 Configure Web/HTML5 export preset
- [ ] 5.1.3 Export Windows build (.exe)
- [ ] 5.1.4 Export Web build (.html + .js)
- [ ] 5.1.5 Test both exports run correctly

**Acceptance Criteria**:
- Both builds export without errors
- Games run outside editor
- No missing assets

---

### 5.2 Itch.io Upload
**Time**: 5 minutes
**File**: Browser

- [ ] 5.2.1 Create itch.io page for Temporal Echo
- [ ] 5.2.2 Upload Windows build
- [ ] 5.2.3 Upload Web build (set as primary)
- [ ] 5.2.4 Add game description (one-sentence pitch)
- [ ] 5.2.5 Add screenshots (optional)
- [ ] 5.2.6 Submit to TriJam #358

**Acceptance Criteria**:
- Page is live and public
- Builds are downloadable/playable
- Successfully submitted to jam

---

## Summary

| Phase | Time | Tasks | Deliverables |
|-------|------|-------|--------------|
| 1. Foundation | 0:35 | 16 | Player moves, Echo spawns |
| 2. Combat | 0:40 | 17 | Bullets bounce, Boss chases |
| 3. Game Loop | 0:45 | 15 | Can win/lose, UI works |
| 4. Polish | 0:50 | 18 | Audio, effects, bugs fixed |
| 5. Build | 0:10 | 11 | Exported, on itch.io |
| **Total** | **3:00** | **77 tasks** | **Complete game** |

## Contingency Plans

If behind schedule, cut in this order:

| Priority | Feature | Time Saved |
|----------|---------|------------|
| 1 | Trajectory preview | 15 min |
| 2 | Screen effects | 10 min |
| 3 | Dash ability | 10 min |
| 4 | Bounce speed increase | 5 min |
| 5 | Audio | 15 min |
| 6 | Echo trail effect | 5 min |

**Minimum Viable Product** (if 1 hour left):
- Player moves and shoots
- Bullets bounce once
- Echo spawns after 3s
- Boss has HP
- Can win/lose
