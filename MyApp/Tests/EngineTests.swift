import Foundation
import CoreGraphics

/// Comprehensive automated test suite exercising pure engine, continuous gesture routing, transactions, and level validation.
public struct EngineTests {

    @MainActor
    public static func runAll() -> (passed: Int, failed: Int, allPassed: Bool) {
        var passedCount = 0
        var failedCount = 0

        func verify(_ condition: Bool, _ testName: String) {
            if condition {
                passedCount += 1
                print("  ✅ \(testName)")
            } else {
                failedCount += 1
                print("  ❌ FAILED: \(testName)")
            }
        }

        print("🧪 [PIPEWORK Automated Tests] Executing test suite...")

        // ==========================================
        // 1. GRID / ENGINE TESTS
        // ==========================================

        // Orthogonal adjacency & diagonal rejection
        do {
            let origin = GridCoord(x: 2, y: 2)
            let north = GridCoord(x: 2, y: 1)
            let east = GridCoord(x: 3, y: 2)
            let south = GridCoord(x: 2, y: 3)
            let west = GridCoord(x: 1, y: 2)
            let diagonal = GridCoord(x: 3, y: 3)

            verify(origin.isAdjacent(to: north), "Orthogonal north is adjacent")
            verify(origin.isAdjacent(to: east), "Orthogonal east is adjacent")
            verify(origin.isAdjacent(to: south), "Orthogonal south is adjacent")
            verify(origin.isAdjacent(to: west), "Orthogonal west is adjacent")
            verify(!origin.isAdjacent(to: diagonal), "Diagonal (3,3) is NOT adjacent")
            verify(origin.direction(to: north) == .north, "Direction to north is .north")
            verify(origin.direction(to: diagonal) == nil, "Direction to diagonal is nil")
        }

        // Path extension & connection
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 0), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)

            let start = PuzzleRules.startStroke(state: &state, at: GridCoord(x: 0, y: 0))
            verify(start == .started(lineId: "coolant", startingCoord: GridCoord(x: 0, y: 0)), "Start stroke at socket")

            let step1 = PuzzleRules.dragStep(state: &state, to: GridCoord(x: 1, y: 0))
            verify(step1 == .extended(lineId: "coolant", newHead: GridCoord(x: 1, y: 0)), "Extend path to (1,0)")

            let step2 = PuzzleRules.dragStep(state: &state, to: GridCoord(x: 2, y: 0))
            verify(step2 == .connected(lineId: "coolant", terminal: GridCoord(x: 2, y: 0)), "Connect path to (2,0)")

            let end = PuzzleRules.endStroke(state: &state)
            verify(end == .completed(lineId: "coolant", isConnected: true, puzzleSolved: false), "End stroke completes line")
            verify(state.paths["coolant"]?.isConnected == true, "Line coolant is connected")
        }

        // Simple & deep backtracking along continuous path
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 4, y: 0), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 5), terminals: terminals)

            PuzzleRules.startStroke(state: &state, at: GridCoord(x: 0, y: 0))
            PuzzleRules.dragStep(state: &state, to: GridCoord(x: 1, y: 0))
            PuzzleRules.dragStep(state: &state, to: GridCoord(x: 2, y: 0))
            PuzzleRules.dragStep(state: &state, to: GridCoord(x: 3, y: 0))

            verify(state.paths["coolant"]?.coordinates.count == 4, "Path extended to 4 cells")

            // Backtrack 1 step to (2,0)
            let back1 = PuzzleRules.dragStep(state: &state, to: GridCoord(x: 2, y: 0))
            verify(back1 == .backtracked(lineId: "coolant", currentHead: GridCoord(x: 2, y: 0)), "Simple 1-step backtrack")
            verify(state.paths["coolant"]?.head == GridCoord(x: 2, y: 0), "Head updated to (2,0)")

            // Step backward to (1,0) then (0,0)
            PuzzleRules.dragStep(state: &state, to: GridCoord(x: 1, y: 0))
            let backRoot = PuzzleRules.dragStep(state: &state, to: GridCoord(x: 0, y: 0))
            verify(backRoot == .backtracked(lineId: "coolant", currentHead: GridCoord(x: 0, y: 0)), "Deep backtrack to root")
            verify(state.paths["coolant"]?.coordinates == [GridCoord(x: 0, y: 0)], "Path truncated to root")
        }

        // Auto Cut Collision
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 2), isPrimarySocket: false),
                Terminal(id: "f_A", lineId: "fuel", fluidType: .fuel, coord: GridCoord(x: 1, y: 1), isPrimarySocket: true),
                Terminal(id: "f_B", lineId: "fuel", fluidType: .fuel, coord: GridCoord(x: 3, y: 1), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 4), terminals: terminals)

            // Draw Coolant: (0,0) -> (0,1) -> (0,2)
            PuzzleRules.startStroke(state: &state, at: GridCoord(x: 0, y: 0))
            PuzzleRules.dragStep(state: &state, to: GridCoord(x: 0, y: 1))
            PuzzleRules.dragStep(state: &state, to: GridCoord(x: 0, y: 2))
            PuzzleRules.endStroke(state: &state)
            verify(state.paths["coolant"]?.isConnected == true, "Coolant connected before cut")

            // Draw Fuel crossing (0,1)
            PuzzleRules.startStroke(state: &state, at: GridCoord(x: 1, y: 1))
            let cut = PuzzleRules.dragStep(state: &state, to: GridCoord(x: 0, y: 1))
            verify(cut == .cut(severedLineId: "coolant", activeLineId: "fuel", newHead: GridCoord(x: 0, y: 1)), "Auto cut detected")
            verify(state.paths["coolant"]?.coordinates == [GridCoord(x: 0, y: 0)], "Coolant severed before intersection")
            verify(state.paths["coolant"]?.isConnected == false, "Coolant marked disconnected")
        }

        // Enemy Terminal Protection
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 0), isPrimarySocket: false),
                Terminal(id: "f_A", lineId: "fuel", fluidType: .fuel, coord: GridCoord(x: 0, y: 1), isPrimarySocket: true),
                Terminal(id: "f_B", lineId: "fuel", fluidType: .fuel, coord: GridCoord(x: 2, y: 1), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)

            PuzzleRules.startStroke(state: &state, at: GridCoord(x: 0, y: 0))
            let blocked = PuzzleRules.dragStep(state: &state, to: GridCoord(x: 0, y: 1))
            verify(blocked == .blocked(reason: "Cannot cross or enter enemy terminal"), "Enemy terminal blocked")
        }

        // ==========================================
        // 2. GESTURE ROUTING & DDA TESTS
        // ==========================================

        // Continuous multi-turn one-finger gesture: 1a -> 1b -> 2b -> 2c -> 3c -> 3d -> 4d
        do {
            let geometry = BoardGeometry(
                gridSize: GridSize(dimension: 7),
                containerSize: CGSize(width: 350, height: 350),
                margin: 0
            )

            let p_1a = geometry.center(for: GridCoord(x: 0, y: 0))
            let p_1b = geometry.center(for: GridCoord(x: 0, y: 1))
            let p_2b = geometry.center(for: GridCoord(x: 1, y: 1))
            let p_2c = geometry.center(for: GridCoord(x: 1, y: 2))
            let p_3c = geometry.center(for: GridCoord(x: 2, y: 2))
            let p_3d = geometry.center(for: GridCoord(x: 2, y: 3))
            let p_4d = geometry.center(for: GridCoord(x: 3, y: 3))

            let step_1 = ContinuousGridTraverser.crossedCells(from: p_1a, to: p_1b, geometry: geometry)
            verify(step_1 == [GridCoord(x: 0, y: 1)], "Traverse 1a -> 1b")

            let step_2 = ContinuousGridTraverser.crossedCells(from: p_1b, to: p_2b, geometry: geometry)
            verify(step_2 == [GridCoord(x: 1, y: 1)], "Traverse 1b -> 2b")

            let step_3 = ContinuousGridTraverser.crossedCells(from: p_2b, to: p_2c, geometry: geometry)
            verify(step_3 == [GridCoord(x: 1, y: 2)], "Traverse 2b -> 2c")

            let step_4 = ContinuousGridTraverser.crossedCells(from: p_2c, to: p_3c, geometry: geometry)
            verify(step_4 == [GridCoord(x: 2, y: 2)], "Traverse 2c -> 3c")

            let step_5 = ContinuousGridTraverser.crossedCells(from: p_3c, to: p_3d, geometry: geometry)
            verify(step_5 == [GridCoord(x: 2, y: 3)], "Traverse 3c -> 3d")

            let step_6 = ContinuousGridTraverser.crossedCells(from: p_3d, to: p_4d, geometry: geometry)
            verify(step_6 == [GridCoord(x: 3, y: 3)], "Traverse 3d -> 4d")
        }

        // Fast swipe: 1a -> 1e produces all intermediate cells [1b, 1c, 1d, 1e]
        do {
            let geometry = BoardGeometry(
                gridSize: GridSize(dimension: 7),
                containerSize: CGSize(width: 350, height: 350),
                margin: 0
            )

            let p_1a = geometry.center(for: GridCoord(x: 0, y: 0))
            let p_1e = geometry.center(for: GridCoord(x: 0, y: 4))

            let crossed = ContinuousGridTraverser.crossedCells(from: p_1a, to: p_1e, geometry: geometry)
            let expected = [
                GridCoord(x: 0, y: 1),
                GridCoord(x: 0, y: 2),
                GridCoord(x: 0, y: 3),
                GridCoord(x: 0, y: 4)
            ]
            verify(crossed == expected, "Fast swipe 1a -> 1e produces all intermediate cells")
        }

        // Diagonal trajectory never produces diagonal grid transition
        do {
            let geometry = BoardGeometry(
                gridSize: GridSize(dimension: 7),
                containerSize: CGSize(width: 350, height: 350),
                margin: 0
            )

            let p_start = geometry.center(for: GridCoord(x: 0, y: 0))
            let p_diag = geometry.center(for: GridCoord(x: 2, y: 2))

            let crossed = ContinuousGridTraverser.crossedCells(from: p_start, to: p_diag, geometry: geometry)
            verify(!crossed.isEmpty, "Diagonal crossed non-empty")

            var allOrthogonal = true
            var prev = GridCoord(x: 0, y: 0)
            for c in crossed {
                if !prev.isAdjacent(to: c) {
                    allOrthogonal = false
                }
                prev = c
            }
            verify(allOrthogonal, "Diagonal pixel trajectory produced strictly orthogonal grid transitions")
        }

        // ==========================================
        // 3. TRANSACTION & UNDO TESTS
        // ==========================================

        // No-op touch = 0 moves
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 0), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)
            var history = MoveHistory()
            let interpreter = GridGestureInterpreter()
            let geometry = BoardGeometry(gridSize: state.gridSize, containerSize: CGSize(width: 300, height: 300), margin: 0)

            let p0 = geometry.center(for: GridCoord(x: 0, y: 0))
            interpreter.beginStroke(at: p0, geometry: geometry, state: &state, history: &history)
            interpreter.endStroke(state: &state, history: &history)

            verify(state.moveCount == 0, "No-op touch produces 0 moves")
            verify(!history.canUndo, "No-op touch does not create undo entry")
        }

        // Complex gesture = 1 move; Undo restores full state
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 0), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)
            var history = MoveHistory()
            let interpreter = GridGestureInterpreter()
            let geometry = BoardGeometry(gridSize: state.gridSize, containerSize: CGSize(width: 300, height: 300), margin: 0)

            let p0 = geometry.center(for: GridCoord(x: 0, y: 0))
            let p1 = geometry.center(for: GridCoord(x: 1, y: 0))
            let p2 = geometry.center(for: GridCoord(x: 2, y: 0))

            interpreter.beginStroke(at: p0, geometry: geometry, state: &state, history: &history)
            interpreter.continueStroke(to: p1, geometry: geometry, state: &state)
            interpreter.continueStroke(to: p2, geometry: geometry, state: &state)
            interpreter.endStroke(state: &state, history: &history)

            verify(state.moveCount == 1, "Complex multi-step stroke counts as exactly 1 move")
            verify(state.paths["coolant"]?.isConnected == true, "Line connected")
            verify(history.canUndo, "History contains 1 undo state")

            if let undone = history.undo(currentState: state) {
                state = undone
            }
            verify(state.paths["coolant"]?.coordinates.isEmpty == true, "Undo restored empty board state")
        }

        // ==========================================
        // 4. LEVEL VALIDATION & CSP SOLVER TESTS
        // ==========================================

        // Curated levels pass strict validation
        do {
            for pack in LevelRepository.allPacks {
                for level in pack.levels {
                    do {
                        let enforceUniqueness = level.size <= 6
                        try LevelValidator.validate(level, enforceUniqueSolution: enforceUniqueness)
                        verify(true, "Level \(level.id) in \(pack.name) passed strict validation")
                    } catch {
                        verify(false, "Level \(level.id) failed validation: \(error)")
                    }
                }
            }
        }

        print("🧪 [PIPEWORK Automated Tests] Completed. Passed: \(passedCount), Failed: \(failedCount)")
        return (passed: passedCount, failed: failedCount, allPassed: failedCount == 0)
    }
}
