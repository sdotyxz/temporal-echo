# Core Gameplay Specifications

## Requirements

### Functional Requirements

#### FR-001: Player Movement
- **Priority**: P0 (Critical)
- **Description**: Player can move in 8 directions using WASD or arrow keys
- **Acceptance Criteria**:
  - [ ] Movement speed: 200 px/s
  - [ ] Smooth acceleration/deceleration
  - [ ] No input lag
  - [ ] Sprite faces movement direction

#### FR-002: Mouse Aiming
- **Priority**: P0 (Critical)
- **Description**: Player aims using mouse cursor
- **Acceptance Criteria**:
  - [ ] Sprite rotates to face mouse position
  - [ ] Aim direction is continuous (360 degrees)
  - [ ] No dead zones

#### FR-003: Temporal Echo Shooting
- **Priority**: P0 (Critical)
- **Description**: Left click fires a temporal echo
- **Acceptance Criteria**:
  - [ ] Bullet spawns at player position
  - [ ] Bullet travels in aim direction
  - [ ] Echo spawns exactly 3 seconds later
  - [ ] Echo fires from recorded position
  - [ ] Cooldown: 0.3 seconds between shots

#### FR-004: History Recording
- **Priority**: P0 (Critical)
- **Description**: System records 3 seconds of player state
- **Acceptance Criteria**:
  - [ ] Records position every frame (60fps)
  - [ ] Records aim direction every frame
  - [ ] Stores exactly 180 frames
  - [ ] Circular buffer implementation
  - [ ] Memory efficient

#### FR-005: Bullet Physics
- **Priority**: P0 (Critical)
- **Description**: Bullets bounce off walls
- **Acceptance Criteria**:
  - [ ] Mirror reflection bounce (45° in = 45° out)
  - [ ] Max 3 bounces per bullet
  - [ ] Speed increases 20% per bounce
  - [ ] Bullets destroyed after 3rd bounce

#### FR-006: Bullet Visuals
- **Priority**: P1 (Important)
- **Description**: Bullets change color per bounce
- **Acceptance Criteria**:
  - [ ] 0 bounces: White
  - [ ] 1 bounce: Yellow
  - [ ] 2 bounces: Orange
  - [ ] 3 bounces: Red
  - [ ] Echo bullets: Cyan (distinct from player)

#### FR-007: Boss AI
- **Priority**: P0 (Critical)
- **Description**: Single boss enemy with pursuit behavior
- **Acceptance Criteria**:
  - [ ] Moves toward player at 80 px/s
  - [ ] Always faces player
  - [ ] 10 HP total
  - [ ] Contact damage to player
  - [ ] Defeatable (can reach 0 HP)

#### FR-008: Damage System
- **Priority**: P0 (Critical)
- **Description**: Bullets deal damage to boss
- **Acceptance Criteria**:
  - [ ] Single bullet: 1 damage
  - [ ] Simultaneous player+echo: 2 damage
  - [ ] Dual hit detection within 0.1s window
  - [ ] Visual flash on hit (red)

#### FR-009: Player Health
- **Priority**: P0 (Critical)
- **Description**: Player can take damage and die
- **Acceptance Criteria**:
  - [ ] 3 HP total
  - [ ] Lose 1 HP on boss contact
  - [ ] 1-second invincibility after hit
  - [ ] Visual feedback (flash red)

#### FR-010: Win/Lose Conditions
- **Priority**: P0 (Critical)
- **Description**: Game ends with victory or defeat
- **Acceptance Criteria**:
  - [ ] Victory: Boss HP reaches 0
  - [ ] Defeat: Player HP reaches 0
  - [ ] Victory screen displays
  - [ ] Game Over screen displays
  - [ ] Restart option available

#### FR-011: Trajectory Preview
- **Priority**: P1 (Important)
- **Description**: Shows predicted bullet path
- **Acceptance Criteria**:
  - [ ] Dashed line shows while aiming
  - [ ] Predicts up to 3 bounces
  - [ ] Updates in real-time
  - [ ] Disappears after firing

#### FR-012: Dash Ability
- **Priority**: P2 (Nice to have)
- **Description**: Space key triggers dash
- **Acceptance Criteria**:
  - [ ] Brief speed burst (2x normal)
  - [ ] 0.5-second cooldown
  - [ ] Invincibility during dash
  - [ ] Motion blur effect

### Non-Functional Requirements

#### NFR-001: Performance
- **Target**: 60 FPS on mid-range hardware
- **Metrics**:
  - Max 100 bullets on screen
  - Max 1 boss + 10 echoes
  - Memory usage < 100MB

#### NFR-002: Input Responsiveness
- **Target**: < 16ms input lag
- **Metrics**:
  - Movement starts within 1 frame of input
  - Shooting fires within 1 frame of click

#### NFR-003: Gameplay Duration
- **Target**: 2-5 minutes per session
- **Metrics**:
  - Boss defeatable in 1-2 minutes (optimal play)
  - Player death occurs in 30s-2min (suboptimal)

## Scenarios

### Scenario 1: First Time Player
**Actor**: New player
**Goal**: Understand the game
**Steps**:
1. Player moves around
2. Player shoots at wall
3. Waits 3 seconds
4. Sees echo fire
5. Echo hits boss
6. "Aha!" moment

**Expected Result**: Player understands time echo mechanic

### Scenario 2: Optimal Play
**Actor**: Experienced player
**Goal**: Defeat boss quickly
**Steps**:
1. Shoot at wall while boss is on left
2. Dash to right side
3. Echo fires from left, player fires from right
4. Boss takes 2 damage (dual hit)
5. Repeat 5 times
6. Boss defeated in 30 seconds

**Expected Result**: Fast victory using flanking strategy

### Scenario 3: Beginner Strategy
**Actor**: Cautious player
**Goal**: Defeat boss safely
**Steps**:
1. Shoot at wall
2. Retreat to safe distance
3. Wait for echo to hit
4. Boss takes 1 damage
5. Repeat 10 times
6. Boss defeated in 2 minutes

**Expected Result**: Slow but safe victory

## Technical Constraints

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Resolution**: 800x600
- **Target Platform**: Windows, Web (HTML5)
- **Development Time**: 3 hours

## Dependencies

- Godot 4.6 engine
- Kenney Digital Audio Pack (sounds)
- No external plugins required
