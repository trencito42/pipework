# CHANGELOG

## [1.1.0] - PIPEWORK Recovery & Stabilization Pass
### Completed
- **Continuous 1-Finger Multi-Turn Routing**: Implemented 2D Amanatides & Woo DDA / boundary intersection algorithm in `ContinuousGridTraverser.swift`. Finger moves smoothly through any number of turns (`1a -> 1b -> 2b -> 2c -> 3c -> 3d -> 4d`) without needing to stop or lift finger.
- **Strict Orthogonal Raycasting**: Guaranteed zero diagonal grid transitions even when crossing corners or fast-swiping diagonally.
- **Hardware-Level Touch Tracking Surface**: Created `TouchTrackingView.swift` leveraging direct UIKit touches with 120Hz ProMotion coalesced touch delivery and zero gesture recognition delays.
- **Move Counting & Transactions**: Refactored `MoveHistory.swift` with atomic begin/commit/discard transaction lifecycle. Zero-change touches count as 0 moves. Single physical multi-step gestures count as exactly 1 move. Undo cleanly restores the pre-stroke board state.
- **Immediate Hardware Settings Propagation**: Settings toggles (Sound, Haptics, Reduce Motion, Color Labels) immediately propagate to `AudioService` and `HapticService`.
- **Reduce Motion & Performance Optimization**: Disabled fluid pulse animation when Reduce Motion is on; optimized Canvas redrawing.
- **Blipmade Intro Splash**: Minimal cold-launch intro (< 1.0s) displaying "BLIPMADE" with cyan accent dot, shown once on cold start.
- **UI Copy & Menu Streamlining**: Replaced fake industrial jargon with simple, natural labels (`Play`, `Continue`, `Levels`, `Settings`, `Sound`, `Haptics`, `Color Labels`, `Reduce Motion`, `Reset Progress`, `Undo`, `Hint`, `Restart`, `Next Level`).
- **Curated Levels & Solution-First Validation**: Implemented `LevelValidator.swift` and verified 100% full-board coverage, canonical solution continuity, and solvability across curated packs.
- **Disabled Procedural Mode from Player Menu**: Preserved solver and generator algorithms while hiding experimental endless mode from the main UI.
- **Automated Test Suite**: Built comprehensive 40-test automated suite in `EngineTests.swift` exercising pure engine rules, continuous gesture routing, transactions, backtracking, collision cut, and level validation with 100% pass rate.
