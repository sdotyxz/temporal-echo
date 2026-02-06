# Temporal Echo

**TriJam #358 Entry** - A 3-hour game jam game featuring temporal echo mechanics.

## One-Sentence Pitch

> "Fire your temporal echo - 3 seconds later, your past self rebounds from walls to fight alongside you."

## Core Mechanic

Players shoot "temporal echoes" that don't interact with enemies immediately. After a 3-second delay, a ghost of the player appears at their firing position and fires the same shot, creating cross-fire opportunities with the current player.

## Gameplay Loop

1. **Aim & Fire** → Shoot at walls to set up rebound angles
2. **Move** → Position yourself for the cross-fire moment
3. **Temporal Echo Activates** → 3-second-ago self fires from past position
4. **Coordinated Strike** → Present + Past fire simultaneously at the enemy

## Tech Stack

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Resolution**: 800x600
- **Target FPS**: 60

## Project Structure

```
TemporalEcho/
├── openspec/              # OpenSpec documentation
│   └── changes/
│       └── core-gameplay/
│           ├── proposal.md       # Game concept
│           ├── specs/            # Requirements
│           ├── design.md         # Technical design
│           └── tasks.md          # 92 implementation tasks
├── src/                   # Source code (to be implemented)
├── scenes/                # Godot scenes (to be implemented)
├── assets/                # Game assets (to be implemented)
└── project.godot          # Godot project file
```

## Design Documents

- **[Proposal](openspec/changes/core-gameplay/proposal.md)** - Game concept and overview
- **[Requirements](openspec/changes/core-gameplay/specs/requirements.md)** - Detailed specifications
- **[Design](openspec/changes/core-gameplay/design.md)** - Technical architecture
- **[Tasks](openspec/changes/core-gameplay/tasks.md)** - 92 implementation tasks with timeline

## Status

⏳ **Design Phase** - Reviewing OpenSpec documentation before implementation

## License

MIT License - See [LICENSE](LICENSE) for details
