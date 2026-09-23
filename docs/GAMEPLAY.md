# PIPEWORK — Gameplay Rules & Mechanics Specification

## 1. Grid Model
The board is represented as an $N \times N$ orthogonal grid where each cell $(x, y)$ has:
- Coordinates $0 \le x < N$ and $0 \le y < N$ ($x$: column index left-to-right, $y$: row index top-to-bottom).
- Cell contents: either empty, an endpoint terminal, or an active pipe path segment.

---

## 2. Terminals & Flow Lines
- A level contains $K$ flow lines, indexed $0 \le k < K$.
- Each flow line $k$ has:
  - An associated fluid type (Coolant, Fuel, Chemical, Thermal, Pressure, Auxiliary, etc.).
  - Exactly two distinct fixed terminal endpoints: `terminalA` and `terminalB`.
  - A path: an ordered sequence of adjacent grid cells $[C_0, C_1, \dots, C_m]$, where $C_0$ is one terminal and $C_m$ is either the matching terminal (completed line) or a leading open head (partial line).

---

## 3. Path Validity & Movement Constraints
1. **Orthogonal Adjacency**: Consecutive cells in any path must satisfy Manhattan distance $|x_{i} - x_{i-1}| + |y_{i} - y_{i-1}| = 1$. Diagonals are strictly prohibited.
2. **Mutual Exclusion**: A cell can belong to at most one pipe path at any given time.
3. **No Self-Intersection**: A path cannot visit the same cell multiple times (no loops or bifurcations).
4. **Terminal Integrity**: A path for line $k$ can only begin at line $k$'s terminals, and can only end at line $k$'s opposite terminal.

---

## 4. Touch Gestures & Raycast Interpolation
To ensure high responsiveness and prevent missed cells when dragging quickly:
1. **Touch Start**:
   - If touch starts on terminal of line $k$: initiates new path or continues existing path from that terminal.
   - If touch starts on an existing intermediate cell of line $k$: truncates the path to that cell and continues dragging from that position.
   - If touch starts on an empty cell: gesture ignored until an endpoint or existing path is touched.
2. **Continuous Drag Interpolation (Bresenham / Manhattan Stepping)**:
   - When the touch moves from cell $A$ to cell $B$, if $B$ is not adjacent to $A$, the engine computes the intermediate orthogonal line of cells between $A$ and $B$.
   - Stepping order resolves primary axis of movement first, feeding step-by-step transitions into the engine so no cells are skipped.
3. **Touch End**:
   - Finalizes the current stroke. If the path reaches the matching terminal, the line locks into "Connected" state with a success haptic.

---

## 5. Backtracking & Redrawing Algorithm
- **Natural Backtrack**: If the leading head of line $k$ moves onto its own immediate predecessor cell $C_{m-1}$, cell $C_m$ is popped from the path sequence, freeing that cell.
- **Deep Redraw**: If the touch jumps to an earlier cell $C_j$ ($j < m$) in the same path, all subsequent cells $[C_{j+1}, \dots, C_m]$ are trimmed.

---

## 6. Auto-Cut (Collision Resolution) Algorithm
When the active drawing path of line $k$ steps into cell $C_{target}$ which is currently occupied by a different line $j \ne k$:
1. Identify if $C_{target}$ is an endpoint or path segment of line $j$:
   - **Case A: $C_{target}$ is an endpoint of line $j$**:
     The move is **blocked / illegal**. Line $k$ cannot enter or overwrite another line's terminal socket.
   - **Case B: $C_{target}$ is an intermediate path segment of line $j$**:
     Let line $j$'s path be $[P_0, P_1, \dots, P_p]$ where $P_r = C_{target}$.
     - Determine which endpoint ($P_0$ or $P_p$) remains connected to the untouched portion before index $r$.
     - Truncate line $j$'s path: retain $[P_0, \dots, P_{r-1}]$, and free all cells from $P_r$ onwards ($[P_r, \dots, P_p]$).
     - Cell $C_{target}$ is now free and assigned to line $k$'s path.
     - Line $j$ status transitions from Connected to Incomplete.
     - Trigger a subtle route-cut haptic and visual severance.

---

## 7. Win Condition & Pressure Metric
- **Pressure Formula**:
  $$\text{Pressure} = \frac{\text{Occupied Usable Cells}}{\text{Total Usable Cells}} \times 100\%$$
- **Victory Rule**:
  $$\text{All } K \text{ pairs connected} \quad \wedge \quad \text{Pressure} == 100\%$$
- Connecting all endpoints at $< 100\%$ Pressure displays:
  `LINES COMPLETE (5/5) — PRESSURE INSUFFICIENT (92%) — REROUTE TO SEAL GRID`

---

## 8. Moves & Undo Semantics
- **Move Count**: Increments by $1$ on each committed touch stroke that modifies the board state (i.e. on finger lift after adding, trimming, or cutting a line).
- **Undo History**: Stores a stack of immutable board state snapshots. Triggering Undo pops the previous state, restoring path geometries and line connection statuses accurately.
- **Restart**: Restores initial board state (all intermediate paths cleared, zero cells occupied outside terminals).
