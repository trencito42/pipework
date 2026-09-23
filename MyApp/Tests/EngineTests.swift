import Foundation

/// Pure Swift unit test harness for the PIPEWORK puzzle engine.
public struct EngineTests {

    public static func runAll() -> Bool {
        print("🧪 [PIPEWORK EngineTests] Starting test suite...")
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

        // Test 1: Coordinate Math
        do {
            let origin = GridCoord(x: 2, y: 2)
            let north = GridCoord(x: 2, y: 1)
            let east = GridCoord(x: 3, y: 2)
            let diagonal = GridCoord(x: 3, y: 3)

            verify(origin.manhattanDistance(to: north) == 1, "Manhattan distance adjacent")
            verify(origin.manhattanDistance(to: diagonal) == 2, "Manhattan distance diagonal")
            verify(origin.isAdjacent(to: north), "isAdjacent north")
            verify(origin.isAdjacent(to: east), "isAdjacent east")
            verify(!origin.isAdjacent(to: diagonal), "isAdjacent diagonal is false")
            verify(origin.direction(to: north) == .north, "Direction north")
            verify(origin.direction(to: east) == .east, "Direction east")
            verify(origin.direction(to: diagonal) == nil, "Direction diagonal nil")

            let grid = GridSize(dimension: 5)
            verify(grid.totalCells == 25, "Grid total cells 5x5")
            verify(grid.contains(GridCoord(x: 0, y: 0)), "Grid contains (0,0)")
            verify(grid.contains(GridCoord(x: 4, y: 4)), "Grid contains (4,4)")
            verify(!grid.contains(GridCoord(x: 5, y: 2)), "Grid out-of-bounds check")
        }

        // Test 2: Path Drawing & Connection
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 0), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)

            let startRes = PuzzleRules.startStroke(state: &state, at: GridCoord(x: 0, y: 0))
            verify(startRes == .started(lineId: "coolant", startingCoord: GridCoord(x: 0, y: 0)), "Stroke start at terminal")
            verify(state.activeLineId == "coolant", "Active line set")

            let step1 = PuzzleRules.dragStep(state: &state, to: GridCoord(x: 1, y: 0))
            verify(step1 == .extended(lineId: "coolant", newHead: GridCoord(x: 1, y: 0)), "Drag step 1 extended")

            let step2 = PuzzleRules.dragStep(state: &state, to: GridCoord(x: 2, y: 0))
            verify(step2 == .connected(lineId: "coolant", terminal: GridCoord(x: 2, y: 0)), "Drag step 2 connected")

            let endRes = PuzzleRules.endStroke(state: &state)
            verify(endRes == .completed(lineId: "coolant", isConnected: true, puzzleSolved: false), "Stroke end completed")
            verify(state.connectedLineCount == 1, "Connected line count == 1")
            verify(state.paths["coolant"]?.isConnected == true, "Path isConnected == true")
        }

        // Test 3: Backtracking
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 3, y: 0), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 4), terminals: terminals)

            PuzzleRules.startStroke(state: &state, at: GridCoord(x: 0, y: 0))
            PuzzleRules.dragStep(state: &state, to: GridCoord(x: 1, y: 0))
            PuzzleRules.dragStep(state: &state, to: GridCoord(x: 2, y: 0))
            verify(state.paths["coolant"]?.coordinates.count == 3, "Initial 3-cell path")

            let backRes = PuzzleRules.dragStep(state: &state, to: GridCoord(x: 1, y: 0))
            verify(backRes == .backtracked(lineId: "coolant", currentHead: GridCoord(x: 1, y: 0)), "Backtrack step recognized")
            verify(state.paths["coolant"]?.coordinates.count == 2, "Backtrack popped coordinate")
            verify(state.paths["coolant"]?.head == GridCoord(x: 1, y: 0), "Backtrack head updated")
        }

        // Test 4: Auto-Cut Collision Resolution
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
            verify(state.paths["coolant"]?.isConnected == true, "Coolant connected")

            // Draw Fuel through (0, 1) cutting Coolant
            PuzzleRules.startStroke(state: &state, at: GridCoord(x: 1, y: 1))
            let cutStep = PuzzleRules.dragStep(state: &state, to: GridCoord(x: 0, y: 1))

            verify(cutStep == .cut(severedLineId: "coolant", activeLineId: "fuel", newHead: GridCoord(x: 0, y: 1)), "Auto-cut detected")
            verify(state.paths["coolant"]?.coordinates == [GridCoord(x: 0, y: 0)], "Coolant severed before (0,1)")
            verify(state.paths["coolant"]?.isConnected == false, "Coolant no longer connected")
            verify(state.paths["fuel"]?.coordinates == [GridCoord(x: 1, y: 1), GridCoord(x: 0, y: 1)], "Fuel acquired (0,1)")
        }

        // Test 5: Enemy Terminal Blocking
        do {
            let terminals = [
                Terminal(id: "c_A", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 0, y: 0), isPrimarySocket: true),
                Terminal(id: "c_B", lineId: "coolant", fluidType: .coolant, coord: GridCoord(x: 2, y: 0), isPrimarySocket: false),
                Terminal(id: "f_A", lineId: "fuel", fluidType: .fuel, coord: GridCoord(x: 0, y: 1), isPrimarySocket: true),
                Terminal(id: "f_B", lineId: "fuel", fluidType: .fuel, coord: GridCoord(x: 2, y: 1), isPrimarySocket: false)
            ]
            var state = PuzzleState(gridSize: GridSize(dimension: 3), terminals: terminals)

            PuzzleRules.startStroke(state: &state, at: GridCoord(x: 0, y: 0))
            let blockedStep = PuzzleRules.dragStep(state: &state, to: GridCoord(x: 0, y: 1))
            verify(blockedStep == .blocked(reason: "Cannot cross or enter enemy terminal"), "Enemy terminal blocked")
            verify(state.paths["coolant"]?.coordinates == [GridCoord(x: 0, y: 0)], "Active path unmodified")
        }

        // Test 6: 100% PRESSURE Win Condition Verification
        do {
            let level = LevelRepository.sector5x5Pack.levels[0]
            var state = level.createInitialState()

            verify(!state.isSolved, "Unsolved at start")
            verify(state.pressure == 0.0, "0% pressure at start")

            if let solution = level.canonicalSolution {
                for pathDef in solution {
                    var path = state.paths[pathDef.lineId]!
                    for coord in pathDef.path {
                        if path.coordinates.isEmpty {
                            path.start(at: coord)
                        } else {
                            path.append(coord)
                        }
                    }
                    state.updatePath(for: pathDef.lineId, path: path)
                }
            }

            verify(state.occupiedCellCount == 25, "All 25 cells occupied")
            verify(state.pressurePercentage == 100, "100% pressure achieved")
            verify(state.connectedLineCount == 3, "All 3 lines connected")
            verify(state.isSolved == true, "Level solved!")
        }

        // Test 7: Move History & Undo
        do {
            let level = LevelRepository.sector5x5Pack.levels[0]
            var state = level.createInitialState()
            var history = MoveHistory()

            history.pushSnapshot(state)

            PuzzleRules.startStroke(state: &state, at: GridCoord(x: 0, y: 0))
            PuzzleRules.dragStep(state: &state, to: GridCoord(x: 1, y: 0))
            PuzzleRules.endStroke(state: &state)

            verify(state.occupiedCellCount == 2, "2 cells occupied after move")
            verify(history.canUndo, "Undo available")

            if let reverted = history.undo(currentState: state) {
                state = reverted
            }

            verify(state.occupiedCellCount == 0, "0 cells occupied after undo")
            verify(state.paths["coolant"]?.coordinates.isEmpty == true, "Path cleared after undo")
        }

        print("🧪 [PIPEWORK EngineTests] Finished. Passed: \(passedCount), Failed: \(failedCount)")
        return failedCount == 0
    }
}
