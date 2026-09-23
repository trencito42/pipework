# PIPEWORK — Product Specification & Vision

## 1. Product Overview
- **Product Name**: PIPEWORK
- **Studio**: Blipmade
- **Platform**: Apple iOS (iPhone primary, iPad responsive)
- **Target OS**: iOS 18+ (Forward-compatible with modern iOS conventions)
- **Genre**: Premium Industrial Connection Puzzle

## 2. World & Fiction
PIPEWORK transforms the abstract connection puzzle into an immersive, tactile industrial maintenance terminal.
The player acts as an elite fluid-routing technician restoring damaged industrial flow conduits across isolated sector facilities.

### Fluid Systems & Lines
Instead of generic colors, each circuit corresponds to a distinct industrial flow medium:
1. **Coolant** (Cyan / Light Blue) — Cryogenic thermal stabilization.
2. **Fuel** (Amber / Bright Orange) — Refined chemical propellant.
3. **Chemical** (Acid Green / Emerald) — Reactive solvent agent.
4. **Thermal** (Crimson / Deep Red) — High-temperature heat transfer fluid.
5. **Pressure** (Cobalt / Electric Blue) — Hydraulic control medium.
6. **Auxiliary** (Violet / Deep Purple) — Backup electrical and routing lines.
7. **Plasma** (Magenta / Neon Pink) — High-energy experimental conduit.
8. **Steam** (Titanium White / Silver) — Vapor equalization line.

## 3. Core Mechanics & Win Criteria
- **Square Grid**: Sizes ranging from $5 \times 5$ up to $12 \times 12$.
- **Terminal Pairs**: Each line has exactly two fixed terminal sockets on the grid perimeter or interior.
- **Orthogonal Paths**: Connected lines must traverse adjacent grid cells (North, South, East, West). No diagonals.
- **Full Cell Partitioning (100% PRESSURE)**: A level is completed if and only if:
  1. All terminal pairs are connected with continuous, non-branching paths.
  2. Every single board cell is occupied by a valid path segment (100% board coverage).

## 4. Game Modes
1. **Sectors (Campaign)**:
   - Primary progression through curated, handcrafted, and verified sectors.
   - Grouped by grid size ($5 \times 5$, $6 \times 6$, $7 \times 7$, $8 \times 8$, $9 \times 9$, $10 \times 10$, and Expert).
   - Move efficiency tracking (Moves taken vs Par / minimum moves).
2. **Daily Diagnostic (Daily Puzzle)**:
   - One deterministic puzzle per calendar day derived from date hashing.
   - Streak tracking (Current Streak, Best Streak, Calendar History).
3. **Time Trial (Emergency Overhaul)**:
   - Rapid-fire puzzle solving against a countdown timer (30s, 60s, 120s).
   - Score multiplier for fast, flawless completions without backtracking.

## 5. Monetization & Tone
- **Premium Feel**: No intrusive ad banners, no dark patterns, no energy bars.
- **Atmosphere**: Dark graphite panels, subtle chamfers, crisp glowing conduits, satisfying mechanical clicks, subtle haptics.
