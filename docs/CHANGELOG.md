# PIPEWORK — Changelog

## [0.2.0] - 2026-09-23
### Added
- Integrated full visual fidelity and interaction design system from exploratory prototype:
  - Multi-layer vulcanized hydraulic hoses with ambient occlusion shadows, dark trench cores, glowing fluid channels, specular beams, and moving fluid pulse phase animations.
  - Machined metal terminal sockets with beveled outer flange rings, 6 perimeter mechanical bolts/rivets, dark recessed chambers, fluid well ports with specular highlights, and illuminated connection lock collars.
  - 3-column tactical status bar (`LINES`, `MOVES`, `PRESSURE`) with integrated 4pt glowing pressure gauge progress track transitioning from cyan to emerald green at 100% PRESSURE.
  - 52x52pt circular tactical metallic buttons (`Undo`, `Hint`, `Restart`).
  - Active drag nozzle indicator and elastic tether connecting lead cell nozzle to pointer coordinates.
  - Added full-board 7x7 solution-first sectors from prototype (Sector 07, Sector 08) with 49/49 cell coverage verification.
  - Engineering diagnostic hint system that detects and routes canonical paths.
  - Diagnostic toast notification for blocked routes and system purges.

## [0.1.0] - 2026-09-23
### Added
- Created complete project memory documentation: `AGENTS.md`, and full `/docs/` technical specifications.
- Established clean pure Swift engine architecture (`GridCoord`, `GridDirection`, `GridSize`, `FluidType`, `Terminal`, `PipePath`, `PuzzleState`, `PuzzleRules`, `MoveHistory`).
- Implemented core game rules: orthogonal path creation, auto-cut line collision, backtracking, undo/reset, and strict 100% PRESSURE win validation.
- Implemented Codable `LevelDefinition` schema and starter curated levels.
- Implemented interactive `BoardCanvasView` with `GridGestureInterpreter` for fluid multi-cell dragging and interpolation.
- Added comprehensive unit tests for pure puzzle engine.
