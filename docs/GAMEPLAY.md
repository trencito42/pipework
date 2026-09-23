# PIPEWORK — Gameplay Rules & Mechanics Specification

## 1. Grid Model
The board is represented as an $N \times N$ orthogonal grid where each cell $(x, y)$ has:
- Coordinates $0 \le x < N$ and $0 \le y < N$ ($x$: column index left-to-right, $y$: row index top-to-bottom).
- Cell contents: either empty, an endpoint terminal socket, or an active pipe path segment.

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

## 4. Stroke Lifecycle & Non-Destructive Touch-Down
Drawing interaction follows an explicit 3-state lifecycle machine managed by `GridGestureInterpreter`:

```
               [Touch Down]
                  │
                  ▼
              ┌───────┐
              │ IDLE  │
              └───┬───┘
                  │ Valid Terminal or Pipe Touched
                  ▼
              ┌───────┐  [Lift without Drag (< Deadband)]
              │ ARMED ├─────────────────────────────────► Rollback Transaction
              └───┬───┘                                   (0 moves, 0 mutations)
                  │ Drag >= 25% Cell Deadband
                  ▼
             ┌──────────┐
             │ DRAGGING │
             └────┬─────┘
                  │
                  ├─► [Blocked Step Encountered] ──► Retain Head at Valid Cell
                  │                                  (Slide sideways without finger lift)
                  ├─► [Touch Cancelled Event]    ──► Rollback Snapshot (0 moves)
                  │
                  ▼ [Touch Ended / Final Point]
               Commit Transaction ──► Move Count + 1 ──► Win Evaluation
```

1. **Non-Destructive Touch Down (`.armed` Mode)**:
   - Touching a terminal, intermediate pipe segment, or completed line arms the stroke without altering the board or history.
   - If the player lifts their finger without exceeding the deadband threshold ($25\%$ cell width), the transaction is cleanly rolled back with **0 moves recorded**, **0 undo entries created**, and **0 mutations**.
2. **Drag Transition (`.dragging` Mode)**:
   - Once movement exceeds the deadband, the armed mode executes:
     - `newFromTerminal`: clears old path and starts new head from touched socket.
     - `resumeFromHead`: continues seamlessly from existing head.
     - `truncateFromMiddle`: trims the pipe forward of the touched segment.
3. **Continuous DDA Stepping & Directional Hysteresis**:
   - Touch movements are projected onto the grid using 2D Amanatides & Woo continuous DDA raycasting (`ContinuousGridTraverser.crossedCells`).
   - Axis intent tracking prevents accidental perpendicular jitter.
   - Ambiguous $45^\circ$ diagonal corners resolve in favor of the current movement axis.
4. **Blocked Route Reconciliation**:
   - Moving into an enemy terminal or boundary triggers a blocked feedback pulse.
   - The logical pipe head remains stationary at the last accepted valid cell.
   - The player can immediately drag sideways or backward into any valid neighbor without lifting their finger.
5. **Touch End & Cancellation**:
   - `touchesEnded` passes the final touch coordinate into the interpreter to guarantee that quick flick gestures landing on destination terminals connect accurately.
   - `touchesCancelled` immediately reverts the board to its pre-stroke state with zero move penalty.

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

## 7. Win Condition & Deterministic Victory Sequence
- **Pressure Formula**:
  $$\text{Pressure} = \frac{\text{Occupied Usable Cells}}{\text{Total Usable Cells}} \times 100\%$$
- **Victory Rule**:
  $$\text{All } K \text{ pairs connected} \quad \wedge \quad \text{Pressure} == 100\%$$
- **Atomic Victory Commit Flow**:
  1. Stroke commits the final board transaction.
  2. Move count increments to its final count.
  3. Win condition evaluates to `true`.
  4. Progression and star rating are recorded in `PersistenceService` with the final move count.
  5. Celebratory haptics and completion sound are emitted.
  6. Victory modal overlay is presented following a polished $350\text{ms}$ celebration delay.
