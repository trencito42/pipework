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
        // 3. COMPREHENSIVE INTERACTION & STROKE LIFECYCLE REGRESSIONS
        // ==========================================

        // R1: Tap on empty cell produces 0 moves and 0 mutations
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 0), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)
            var history = MoveHistory()
            let interpreter = GridGestureInterpreter()
            let geometry = BoardGeometry(gridSize: state.gridSize, containerSize: CGSize(width: 300, height: 300), margin: 0)

            let emptyPoint = geometry.center(for: GridCoord(x: 1, y: 1))
            interpreter.beginStroke(at: emptyPoint, geometry: geometry, state: &state, history: &history)
            let result = interpreter.endStroke(at: emptyPoint, geometry: geometry, state: &state, history: &history)

            verify(result.didMutate == false, "R1: Tap on empty cell did not mutate")
            verify(state.moveCount == 0, "R1: Tap on empty cell produces 0 moves")
            verify(!history.canUndo, "R1: Tap on empty cell leaves undo stack empty")
        }

        // R2: Tap on terminal without movement produces 0 moves and keeps original state
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 0), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)
            var history = MoveHistory()
            let interpreter = GridGestureInterpreter()
            let geometry = BoardGeometry(gridSize: state.gridSize, containerSize: CGSize(width: 300, height: 300), margin: 0)

            let termPoint = geometry.center(for: GridCoord(x: 0, y: 0))
            interpreter.beginStroke(at: termPoint, geometry: geometry, state: &state, history: &history)
            verify(interpreter.phase != .idle, "R2: Interpreter armed on terminal")
            let result = interpreter.endStroke(at: termPoint, geometry: geometry, state: &state, history: &history)

            verify(result.didMutate == false, "R2: Tap on terminal did not mutate")
            verify(state.moveCount == 0, "R2: Tap on terminal produces 0 moves")
            verify(!history.canUndo, "R2: Tap on terminal leaves undo stack empty")
            verify(state.paths["coolant"]?.coordinates.isEmpty == true, "R2: Path was not prematurely created")
        }

        // R3: Tap on completed line terminal without movement keeps line intact with 0 moves
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 0), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)
            var path = state.paths["coolant"]!
            path.start(at: GridCoord(x: 0, y: 0))
            path.append(GridCoord(x: 1, y: 0))
            path.append(GridCoord(x: 2, y: 0))
            state.updatePath(for: "coolant", path: path)

            var history = MoveHistory()
            let interpreter = GridGestureInterpreter()
            let geometry = BoardGeometry(gridSize: state.gridSize, containerSize: CGSize(width: 300, height: 300), margin: 0)

            let p0 = geometry.center(for: GridCoord(x: 0, y: 0))
            interpreter.beginStroke(at: p0, geometry: geometry, state: &state, history: &history)
            let result = interpreter.endStroke(at: p0, geometry: geometry, state: &state, history: &history)

            verify(result.didMutate == false, "R3: Tap on completed line terminal did not mutate")
            verify(state.moveCount == 0, "R3: Tap on completed line terminal produces 0 moves")
            verify(state.paths["coolant"]?.isConnected == true, "R3: Completed line remained connected")
            verify(state.paths["coolant"]?.coordinates.count == 3, "R3: Completed line coordinates preserved")
        }

        // R4: Tap on middle of completed line without movement preserves line with 0 moves
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 0), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)
            var path = state.paths["coolant"]!
            path.start(at: GridCoord(x: 0, y: 0))
            path.append(GridCoord(x: 1, y: 0))
            path.append(GridCoord(x: 2, y: 0))
            state.updatePath(for: "coolant", path: path)

            var history = MoveHistory()
            let interpreter = GridGestureInterpreter()
            let geometry = BoardGeometry(gridSize: state.gridSize, containerSize: CGSize(width: 300, height: 300), margin: 0)

            let midPoint = geometry.center(for: GridCoord(x: 1, y: 0))
            interpreter.beginStroke(at: midPoint, geometry: geometry, state: &state, history: &history)
            let result = interpreter.endStroke(at: midPoint, geometry: geometry, state: &state, history: &history)

            verify(result.didMutate == false, "R4: Tap on middle of completed line did not mutate")
            verify(state.moveCount == 0, "R4: Tap on middle produces 0 moves")
            verify(state.paths["coolant"]?.isConnected == true, "R4: Line remains connected")
        }

        // R5: Quick flick connecting A to B where touch ended is the only event landing inside B
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 0), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)
            var history = MoveHistory()
            let interpreter = GridGestureInterpreter()
            let geometry = BoardGeometry(gridSize: state.gridSize, containerSize: CGSize(width: 300, height: 300), margin: 0)

            let pA = geometry.center(for: GridCoord(x: 0, y: 0))
            let pMid = geometry.center(for: GridCoord(x: 1, y: 0))
            let pB = geometry.center(for: GridCoord(x: 2, y: 0))

            interpreter.beginStroke(at: pA, geometry: geometry, state: &state, history: &history)
            interpreter.continueStroke(to: pMid, geometry: geometry, state: &state)
            // Final flick directly into B at touchEnd
            let result = interpreter.endStroke(at: pB, geometry: geometry, state: &state, history: &history)

            verify(result.didConnectLine == true, "R5: Flick connected line successfully")
            verify(result.moveCountIncremented == true, "R5: Flick incremented move count")
            verify(state.paths["coolant"]?.isConnected == true, "R5: Coolant path connected")
            verify(state.moveCount == 1, "R5: Exactly 1 move committed")
        }

        // R6: Drag into enemy terminal -> blocked, head preserved at previous valid cell
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 0), isPrimarySocket: false),
                Terminal(id: "f_A", lineId: "fuel", fluidType: .fuel, coord: GridCoord(x: 1, y: 0), isPrimarySocket: true),
                Terminal(id: "f_B", lineId: "fuel", fluidType: .fuel, coord: GridCoord(x: 1, y: 2), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)
            var history = MoveHistory()
            let interpreter = GridGestureInterpreter()
            let geometry = BoardGeometry(gridSize: state.gridSize, containerSize: CGSize(width: 300, height: 300), margin: 0)

            let p0 = geometry.center(for: GridCoord(x: 0, y: 0))
            let pEnemy = geometry.center(for: GridCoord(x: 1, y: 0))

            interpreter.beginStroke(at: p0, geometry: geometry, state: &state, history: &history)
            interpreter.continueStroke(to: pEnemy, geometry: geometry, state: &state)

            verify(interpreter.acceptedPipeHead == GridCoord(x: 0, y: 0), "R6: Head preserved at (0,0) after hitting enemy terminal")
            verify(interpreter.feedbackController.lastBlockedCoord == GridCoord(x: 1, y: 0), "R6: Blocked coord recorded")
        }

        // R7: Drag into enemy terminal, then slide sideways into valid neighbor without finger lift
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 2), isPrimarySocket: false),
                Terminal(id: "f_A", lineId: "fuel", fluidType: .fuel, coord: GridCoord(x: 1, y: 0), isPrimarySocket: true),
                Terminal(id: "f_B", lineId: "fuel", fluidType: .fuel, coord: GridCoord(x: 1, y: 1), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)
            var history = MoveHistory()
            let interpreter = GridGestureInterpreter()
            let geometry = BoardGeometry(gridSize: state.gridSize, containerSize: CGSize(width: 300, height: 300), margin: 0)

            let p0 = geometry.center(for: GridCoord(x: 0, y: 0))
            let pEnemy = geometry.center(for: GridCoord(x: 1, y: 0))
            let pDown = geometry.center(for: GridCoord(x: 0, y: 1))

            interpreter.beginStroke(at: p0, geometry: geometry, state: &state, history: &history)
            interpreter.continueStroke(to: pEnemy, geometry: geometry, state: &state)
            verify(interpreter.acceptedPipeHead == GridCoord(x: 0, y: 0), "R7: Head at (0,0) when blocked")

            // Slide sideways/down to (0,1) without lifting finger
            interpreter.continueStroke(to: pDown, geometry: geometry, state: &state)
            verify(interpreter.acceptedPipeHead == GridCoord(x: 0, y: 1), "R7: Pipe seamlessly moved to (0,1) after sliding sideways")
            verify(state.paths["coolant"]?.head == GridCoord(x: 0, y: 1), "R7: State path head is (0,1)")

            _ = interpreter.endStroke(state: &state, history: &history)
            verify(state.moveCount == 1, "R7: Move committed successfully")
        }

        // R8: Touch cancellation restores board snapshot with 0 moves
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

            interpreter.beginStroke(at: p0, geometry: geometry, state: &state, history: &history)
            interpreter.continueStroke(to: p1, geometry: geometry, state: &state)
            verify(state.paths["coolant"]?.coordinates.count == 2, "Path extended during drag")

            // Cancel stroke (e.g. system gesture or incoming call)
            interpreter.cancelStroke(state: &state, history: &history)

            verify(state.paths["coolant"]?.coordinates.isEmpty == true, "R8: Path reverted to empty on cancel")
            verify(state.moveCount == 0, "R8: 0 moves recorded on cancel")
            verify(!history.canUndo, "R8: No undo snapshot created on cancel")
            verify(!interpreter.isStrokeActive, "R8: Interpreter returned to idle")
        }

        // R9: Directional hysteresis & axis intent
        do {
            let geometry = BoardGeometry(
                gridSize: GridSize(dimension: 5),
                containerSize: CGSize(width: 250, height: 250),
                margin: 0
            )

            // Start at center of (0,0), move horizontally to (1,0) with minor vertical wobble
            let pStart = geometry.center(for: GridCoord(x: 0, y: 0))
            let pWobble = CGPoint(x: geometry.center(for: GridCoord(x: 1, y: 0)).x, y: pStart.y + 4.0) // small 4pt wobble

            let crossed = ContinuousGridTraverser.crossedCells(
                from: pStart,
                to: pWobble,
                geometry: geometry,
                currentAxis: .horizontal
            )
            verify(crossed == [GridCoord(x: 1, y: 0)], "R9: Horizontal axis intent filtered vertical wobble")
        }

        // R10: Corner crossing tie breaker respects current axis
        do {
            let geometry = BoardGeometry(
                gridSize: GridSize(dimension: 5),
                containerSize: CGSize(width: 250, height: 250),
                margin: 0
            )

            let p0 = geometry.center(for: GridCoord(x: 0, y: 0))
            let pDiag = geometry.center(for: GridCoord(x: 1, y: 1))

            let crossedHoriz = ContinuousGridTraverser.crossedCells(from: p0, to: pDiag, geometry: geometry, currentAxis: .horizontal)
            verify(crossedHoriz == [GridCoord(x: 1, y: 0), GridCoord(x: 1, y: 1)], "R10: Horizontal axis stepped X then Y")

            let crossedVert = ContinuousGridTraverser.crossedCells(from: p0, to: pDiag, geometry: geometry, currentAxis: .vertical)
            verify(crossedVert == [GridCoord(x: 0, y: 1), GridCoord(x: 1, y: 1)], "R10: Vertical axis stepped Y then X")
        }

        // R11: Blocked event deduplication
        do {
            let feedback = TouchFeedbackController()
            var eventCount = 0
            feedback.onBlockedCoord = { _ in eventCount += 1 }

            feedback.handle(.blocked(GridCoord(x: 1, y: 0)))
            feedback.handle(.blocked(GridCoord(x: 1, y: 0))) // Duplicate
            feedback.handle(.blocked(GridCoord(x: 1, y: 0))) // Duplicate

            verify(eventCount == 1, "R11: Blocked feedback deduplicated on same cell")

            // Move to different blocked cell
            feedback.handle(.blocked(GridCoord(x: 2, y: 0)))
            verify(eventCount == 2, "R11: New blocked cell triggers event")
        }

        // R12: Victory commit ordering & move count integrity
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 1, y: 0), isPrimarySocket: false),
                Terminal(id: "f_A", lineId: "fuel", fluidType: .fuel, coord: GridCoord(x: 2, y: 0), isPrimarySocket: true),
                Terminal(id: "f_B", lineId: "fuel", fluidType: .fuel, coord: GridCoord(x: 2, y: 2), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)

            // Pre-complete fuel path covering all remaining 7 cells:
            // (2,0) -> (2,1) -> (1,1) -> (0,1) -> (0,2) -> (1,2) -> (2,2)
            var fuelPath = state.paths["fuel"]!
            fuelPath.start(at: GridCoord(x: 2, y: 0))
            fuelPath.append(GridCoord(x: 2, y: 1))
            fuelPath.append(GridCoord(x: 1, y: 1))
            fuelPath.append(GridCoord(x: 0, y: 1))
            fuelPath.append(GridCoord(x: 0, y: 2))
            fuelPath.append(GridCoord(x: 1, y: 2))
            fuelPath.append(GridCoord(x: 2, y: 2))
            state.updatePath(for: "fuel", path: fuelPath)

            var history = MoveHistory()
            let interpreter = GridGestureInterpreter()
            let geometry = BoardGeometry(gridSize: state.gridSize, containerSize: CGSize(width: 300, height: 300), margin: 0)

            let p0 = geometry.center(for: GridCoord(x: 0, y: 0))
            let p1 = geometry.center(for: GridCoord(x: 1, y: 0))

            interpreter.beginStroke(at: p0, geometry: geometry, state: &state, history: &history)
            interpreter.continueStroke(to: p1, geometry: geometry, state: &state)
            let result = interpreter.endStroke(at: p1, geometry: geometry, state: &state, history: &history)

            verify(result.isPuzzleSolved == true, "R12: Puzzle is solved on commit")
            verify(result.moveCountIncremented == true, "R12: Move count incremented on commit")
            verify(state.moveCount == 1, "R12: Move count is exactly 1 upon victory evaluation")
        }

        // ==========================================
        // 4. LEVEL VALIDATION & DUAL SOLVER TESTS
        // ==========================================

        // Test 1 (Bad Level): Level with premature shortcut is rejected
        do {
            let badLevel = LevelDefinition(
                id: "test-bad-shortcut",
                packId: "test",
                number: 1,
                size: 5,
                pairs: [
                    TerminalPairDefinition(id: "coolant", fluidType: .coolant, terminalA: GridCoord(x: 4, y: 3), terminalB: GridCoord(x: 3, y: 2)),
                    TerminalPairDefinition(id: "fuel", fluidType: .fuel, terminalA: GridCoord(x: 4, y: 4), terminalB: GridCoord(x: 1, y: 3)),
                    TerminalPairDefinition(id: "chemical", fluidType: .chemical, terminalA: GridCoord(x: 2, y: 1), terminalB: GridCoord(x: 0, y: 2)),
                    TerminalPairDefinition(id: "pressure", fluidType: .pressure, terminalA: GridCoord(x: 4, y: 2), terminalB: GridCoord(x: 3, y: 1))
                ],
                canonicalSolution: [
                    CanonicalPathDefinition(lineId: "coolant", path: [
                        GridCoord(x: 4, y: 3), GridCoord(x: 3, y: 3), GridCoord(x: 2, y: 3), GridCoord(x: 2, y: 2), GridCoord(x: 3, y: 2)
                    ]),
                    CanonicalPathDefinition(lineId: "fuel", path: [
                        GridCoord(x: 4, y: 4), GridCoord(x: 3, y: 4), GridCoord(x: 2, y: 4), GridCoord(x: 1, y: 4),
                        GridCoord(x: 0, y: 4), GridCoord(x: 0, y: 3), GridCoord(x: 1, y: 3)
                    ]),
                    CanonicalPathDefinition(lineId: "chemical", path: [
                        GridCoord(x: 2, y: 1), GridCoord(x: 2, y: 0), GridCoord(x: 1, y: 0), GridCoord(x: 0, y: 0),
                        GridCoord(x: 0, y: 1), GridCoord(x: 1, y: 1), GridCoord(x: 1, y: 2), GridCoord(x: 0, y: 2)
                    ]),
                    CanonicalPathDefinition(lineId: "pressure", path: [
                        GridCoord(x: 4, y: 2), GridCoord(x: 4, y: 1), GridCoord(x: 4, y: 0), GridCoord(x: 3, y: 0), GridCoord(x: 3, y: 1)
                    ])
                ],
                parMoves: 4,
                difficultyScore: 1.0,
                signature: "bad_test"
            )

            let solver = PuzzleSolver(gridSize: GridSize(dimension: 5), pairs: badLevel.pairs)
            let prematureResult = solver.findPrematureSolution()
            verify(prematureResult != nil, "Solver B detected premature shortcut on bad level")
            if let premature = prematureResult {
                verify(premature.coveredCellCount < 25, "Premature solution coverage \(premature.coveredCellCount) < 25")
            }

            var caughtPremature = false
            do {
                _ = try LevelValidator.validate(badLevel, enforceUniqueSolution: true, enforceNoPrematureRouting: true)
            } catch LevelValidator.ValidationError.prematureCompleteRoutingExists {
                caughtPremature = true
            } catch {
                caughtPremature = false
            }
            verify(caughtPremature, "LevelValidator correctly rejected bad level with .prematureCompleteRoutingExists")
        }

        // Test 2 (Good Level): Certified level is accepted with uniqueness and zero premature routings
        do {
            let goodLevel = LevelRepository.sector5x5Pack.levels[0]
            do {
                let report = try LevelValidator.validate(goodLevel, enforceUniqueSolution: true, enforceNoPrematureRouting: true, enforceQualityFilter: true)
                verify(report.isAccepted, "Good level 5x5-01 is accepted")
                verify(report.isUniqueFullBoard, "Good level has exactly 1 full-board solution")
                verify(!report.hasPrematureRouting, "Good level has 0 premature routings")
                verify(report.coveredCellCount == 25, "Good level has 100% canonical coverage (25/25)")
            } catch {
                verify(false, "Good level unexpectedly failed validation: \(error)")
            }
        }

        // Test 3 (Unsolvable Level): Level with topologically impossible configuration is rejected
        do {
            let unsolvableLevel = LevelDefinition(
                id: "test-unsolvable",
                packId: "test",
                number: 1,
                size: 3,
                pairs: [
                    TerminalPairDefinition(id: "coolant", fluidType: .coolant, terminalA: GridCoord(x: 0, y: 0), terminalB: GridCoord(x: 2, y: 2)),
                    TerminalPairDefinition(id: "fuel", fluidType: .fuel, terminalA: GridCoord(x: 0, y: 2), terminalB: GridCoord(x: 2, y: 0)),
                    TerminalPairDefinition(id: "chemical", fluidType: .chemical, terminalA: GridCoord(x: 1, y: 0), terminalB: GridCoord(x: 1, y: 2))
                ],
                canonicalSolution: [
                    CanonicalPathDefinition(lineId: "coolant", path: [GridCoord(x: 0, y: 0), GridCoord(x: 1, y: 1), GridCoord(x: 2, y: 2)])
                ],
                parMoves: 3,
                difficultyScore: 1.0,
                signature: "unsolvable"
            )

            var caughtUnsolvable = false
            do {
                _ = try LevelValidator.validate(unsolvableLevel, enforceUniqueSolution: true, enforceNoPrematureRouting: true)
            } catch {
                caughtUnsolvable = true
            }
            verify(caughtUnsolvable, "LevelValidator correctly rejected unsolvable level")
        }

        // Test 4 (Multiple Full Solutions): Level with ambiguous solution is rejected
        do {
            let multipleSolLevel = LevelDefinition(
                id: "test-multiple",
                packId: "test",
                number: 1,
                size: 4,
                pairs: [
                    TerminalPairDefinition(id: "coolant", fluidType: .coolant, terminalA: GridCoord(x: 0, y: 0), terminalB: GridCoord(x: 3, y: 0)),
                    TerminalPairDefinition(id: "fuel", fluidType: .fuel, terminalA: GridCoord(x: 0, y: 3), terminalB: GridCoord(x: 3, y: 3))
                ],
                canonicalSolution: [
                    CanonicalPathDefinition(lineId: "coolant", path: [
                        GridCoord(x: 0, y: 0), GridCoord(x: 0, y: 1), GridCoord(x: 1, y: 1), GridCoord(x: 1, y: 0),
                        GridCoord(x: 2, y: 0), GridCoord(x: 2, y: 1), GridCoord(x: 3, y: 1), GridCoord(x: 3, y: 0)
                    ]),
                    CanonicalPathDefinition(lineId: "fuel", path: [
                        GridCoord(x: 0, y: 3), GridCoord(x: 0, y: 2), GridCoord(x: 1, y: 2), GridCoord(x: 1, y: 3),
                        GridCoord(x: 2, y: 3), GridCoord(x: 2, y: 2), GridCoord(x: 3, y: 2), GridCoord(x: 3, y: 3)
                    ])
                ],
                parMoves: 2,
                difficultyScore: 1.0,
                signature: "multiple"
            )

            var caughtMultipleOrPremature = false
            do {
                _ = try LevelValidator.validate(multipleSolLevel, enforceUniqueSolution: true, enforceNoPrematureRouting: true)
            } catch LevelValidator.ValidationError.notUniquelySolvable {
                caughtMultipleOrPremature = true
            } catch LevelValidator.ValidationError.prematureCompleteRoutingExists {
                caughtMultipleOrPremature = true
            } catch {
                caughtMultipleOrPremature = true
            }
            verify(caughtMultipleOrPremature, "LevelValidator rejected ambiguous / non-unique level")
        }

        // Test 5: Every D4-unique campaign level exposed by the repository passes strict validation.
        do {
            for pack in LevelRepository.allPacks {
                for level in pack.levels {
                    do {
                        let report = try LevelValidator.validate(level, enforceUniqueSolution: true, enforceNoPrematureRouting: true, enforceQualityFilter: true)
                        verify(report.isAccepted && report.isUniqueFullBoard && !report.hasPrematureRouting, "Shipped level \(level.id) strictly verified (Score: \(String(format: "%.2f", report.qualityScore)))")
                    } catch {
                        verify(false, "Shipped level \(level.id) failed validation: \(error)")
                    }
                }
            }
        }

        print("🧪 [PIPEWORK Automated Tests] Completed. Passed: \(passedCount), Failed: \(failedCount)")
        return (passed: passedCount, failed: failedCount, allPassed: failedCount == 0)
    }
}
