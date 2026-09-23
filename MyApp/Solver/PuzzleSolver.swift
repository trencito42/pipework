import Foundation

/// Deterministic CSP backtracking solver for PIPEWORK grids.
/// Supports both full-board coverage search (Solver A) and premature partial-coverage detection (Solver B).
public final class PuzzleSolver {

    public struct SolveResult: Sendable {
        public let isSolvable: Bool
        public let solutionCount: Int
        public let paths: [String: [GridCoord]]?
        public let coveredCellCount: Int
        public let exploredNodes: Int
    }

    private let gridSize: GridSize
    private let terminals: [Terminal]
    private let pairs: [(lineId: String, start: GridCoord, end: GridCoord)]

    public init(gridSize: GridSize, pairs: [TerminalPairDefinition]) {
        self.gridSize = gridSize
        self.pairs = pairs.map { (lineId: $0.id, start: $0.terminalA, end: $0.terminalB) }

        var termList: [Terminal] = []
        for pair in pairs {
            termList.append(Terminal(id: "\(pair.id)_A", lineId: pair.id, fluidType: pair.fluidType, coord: pair.terminalA, isPrimarySocket: true))
            termList.append(Terminal(id: "\(pair.id)_B", lineId: pair.id, fluidType: pair.fluidType, coord: pair.terminalB, isPrimarySocket: false))
        }
        self.terminals = termList
    }

    // MARK: - Backward Compatibility

    public func solve(maxSolutions: Int = 2) -> SolveResult {
        solveFullBoard(maxSolutions: maxSolutions)
    }

    // MARK: - Solver A: Full Board Solutions (100% Coverage Required)

    /// Finds valid 100% full-board coverage solutions up to `maxSolutions`.
    public func solveFullBoard(maxSolutions: Int = 2, maxSteps: Int = 50_000) -> SolveResult {
        var occupancy = Array(repeating: Array(repeating: Optional<String>.none, count: gridSize.height), count: gridSize.width)
        for t in terminals {
            occupancy[t.coord.x][t.coord.y] = t.lineId
        }

        var currentPaths: [String: [GridCoord]] = [:]
        for p in pairs {
            currentPaths[p.lineId] = [p.start]
        }

        var foundSolutions: [[String: [GridCoord]]] = []
        var steps = 0

        backtrackFullBoard(
            pairIndex: 0,
            currentPaths: &currentPaths,
            occupancy: &occupancy,
            foundSolutions: &foundSolutions,
            maxSolutions: maxSolutions,
            steps: &steps,
            maxSteps: maxSteps
        )

        let firstPaths = foundSolutions.first
        let count = firstPaths?.values.reduce(0) { $0 + $1.count } ?? 0

        return SolveResult(
            isSolvable: !foundSolutions.isEmpty,
            solutionCount: foundSolutions.count,
            paths: firstPaths,
            coveredCellCount: count,
            exploredNodes: steps
        )
    }

    private func backtrackFullBoard(
        pairIndex: Int,
        currentPaths: inout [String: [GridCoord]],
        occupancy: inout [[String?]],
        foundSolutions: inout [[String: [GridCoord]]],
        maxSolutions: Int,
        steps: inout Int,
        maxSteps: Int
    ) {
        if foundSolutions.count >= maxSolutions || steps >= maxSteps { return }
        steps += 1

        // If all pairs connected: check 100% full coverage
        if pairIndex >= pairs.count {
            if isFullCoverage(occupancy) {
                foundSolutions.append(currentPaths)
            }
            return
        }

        let currentPair = pairs[pairIndex]
        let lineId = currentPair.lineId
        guard let currentHead = currentPaths[lineId]?.last else { return }

        // If reached target endpoint
        if currentHead == currentPair.end {
            if canRemainingPairsConnect(fromPairIndex: pairIndex + 1, occupancy: occupancy) {
                backtrackFullBoard(
                    pairIndex: pairIndex + 1,
                    currentPaths: &currentPaths,
                    occupancy: &occupancy,
                    foundSolutions: &foundSolutions,
                    maxSolutions: maxSolutions,
                    steps: &steps,
                    maxSteps: maxSteps
                )
            }
            return
        }

        // Branch into orthogonal neighbors sorted by distance to target
        let neighbors = currentHead.orthogonalNeighbors(in: gridSize).sorted {
            $0.manhattanDistance(to: currentPair.end) < $1.manhattanDistance(to: currentPair.end)
        }

        for next in neighbors {
            if next == currentPair.end {
                currentPaths[lineId]?.append(next)
                if canRemainingPairsConnect(fromPairIndex: pairIndex + 1, occupancy: occupancy) {
                    backtrackFullBoard(
                        pairIndex: pairIndex + 1,
                        currentPaths: &currentPaths,
                        occupancy: &occupancy,
                        foundSolutions: &foundSolutions,
                        maxSolutions: maxSolutions,
                        steps: &steps,
                        maxSteps: maxSteps
                    )
                }
                currentPaths[lineId]?.removeLast()
                if foundSolutions.count >= maxSolutions || steps >= maxSteps { return }
                continue
            }

            // Cell must be unoccupied
            if occupancy[next.x][next.y] == nil {
                occupancy[next.x][next.y] = lineId
                currentPaths[lineId]?.append(next)

                if isValidFullBoardState(occupancy: occupancy, currentHead: next, target: currentPair.end, pairIndex: pairIndex) {
                    backtrackFullBoard(
                        pairIndex: pairIndex,
                        currentPaths: &currentPaths,
                        occupancy: &occupancy,
                        foundSolutions: &foundSolutions,
                        maxSolutions: maxSolutions,
                        steps: &steps,
                        maxSteps: maxSteps
                    )
                }

                currentPaths[lineId]?.removeLast()
                occupancy[next.x][next.y] = nil
                if foundSolutions.count >= maxSolutions || steps >= maxSteps { return }
            }
        }
    }

    private func isValidFullBoardState(
        occupancy: [[String?]],
        currentHead: GridCoord,
        target: GridCoord,
        pairIndex: Int
    ) -> Bool {
        // Degree check: Every empty cell must have at least 2 available connections (or at least 1 for heads/endpoints)
        for y in 0..<gridSize.height {
            for x in 0..<gridSize.width {
                if occupancy[x][y] == nil {
                    let coord = GridCoord(x: x, y: y)
                    var available = 0
                    for n in coord.orthogonalNeighbors(in: gridSize) {
                        if occupancy[n.x][n.y] == nil || n == currentHead || n == target {
                            available += 1
                        } else {
                            // Check if n is an unstarted terminal
                            for p in (pairIndex + 1)..<pairs.count {
                                if pairs[p].start == n || pairs[p].end == n {
                                    available += 1
                                    break
                                }
                            }
                        }
                    }
                    if available < 2 {
                        return false
                    }
                }
            }
        }
        return true
    }

    // MARK: - Solver B: Premature Complete Routing Search (Shortcuts / Partial Coverage)

    /// Searches for ANY legal routing where ALL pairs connect, but coverage is < 100% (at least one cell left empty).
    /// If such a solution exists, returns it (proving the level is flawed and must be rejected).
    public func findPrematureSolution(maxSteps: Int = 30_000) -> SolveResult? {
        var occupancy = Array(repeating: Array(repeating: Optional<String>.none, count: gridSize.height), count: gridSize.width)
        for t in terminals {
            occupancy[t.coord.x][t.coord.y] = t.lineId
        }

        var currentPaths: [String: [GridCoord]] = [:]
        for p in pairs {
            currentPaths[p.lineId] = [p.start]
        }

        var prematureSolution: [String: [GridCoord]]? = nil
        var stepCount = 0

        backtrackPremature(
            pairIndex: 0,
            currentPaths: &currentPaths,
            occupancy: &occupancy,
            prematureSolution: &prematureSolution,
            stepCount: &stepCount,
            maxSteps: maxSteps
        )

        if let sol = prematureSolution {
            let totalCovered = sol.values.reduce(0) { $0 + $1.count }
            return SolveResult(
                isSolvable: true,
                solutionCount: 1,
                paths: sol,
                coveredCellCount: totalCovered,
                exploredNodes: stepCount
            )
        }
        return nil
    }

    private func backtrackPremature(
        pairIndex: Int,
        currentPaths: inout [String: [GridCoord]],
        occupancy: inout [[String?]],
        prematureSolution: inout [String: [GridCoord]]?,
        stepCount: inout Int,
        maxSteps: Int
    ) {
        if prematureSolution != nil || stepCount >= maxSteps { return }
        stepCount += 1

        // If all pairs connected: check if at least one empty cell remains
        if pairIndex >= pairs.count {
            if !isFullCoverage(occupancy) {
                prematureSolution = currentPaths
            }
            return
        }

        let currentPair = pairs[pairIndex]
        let lineId = currentPair.lineId
        guard let currentHead = currentPaths[lineId]?.last else { return }

        // If reached target endpoint
        if currentHead == currentPair.end {
            if canRemainingPairsConnect(fromPairIndex: pairIndex + 1, occupancy: occupancy) {
                backtrackPremature(
                    pairIndex: pairIndex + 1,
                    currentPaths: &currentPaths,
                    occupancy: &occupancy,
                    prematureSolution: &prematureSolution,
                    stepCount: &stepCount,
                    maxSteps: maxSteps
                )
            }
            return
        }

        // Branch into orthogonal neighbors prioritizing shortest paths to target
        let neighbors = currentHead.orthogonalNeighbors(in: gridSize).sorted {
            $0.manhattanDistance(to: currentPair.end) < $1.manhattanDistance(to: currentPair.end)
        }

        for next in neighbors {
            if next == currentPair.end {
                currentPaths[lineId]?.append(next)
                if canRemainingPairsConnect(fromPairIndex: pairIndex + 1, occupancy: occupancy) {
                    backtrackPremature(
                        pairIndex: pairIndex + 1,
                        currentPaths: &currentPaths,
                        occupancy: &occupancy,
                        prematureSolution: &prematureSolution,
                        stepCount: &stepCount,
                        maxSteps: maxSteps
                    )
                }
                currentPaths[lineId]?.removeLast()
                if prematureSolution != nil || stepCount >= maxSteps { return }
                continue
            }

            // Cell must be unoccupied
            if occupancy[next.x][next.y] == nil {
                occupancy[next.x][next.y] = lineId
                currentPaths[lineId]?.append(next)

                // Quick BFS reachability check to currentPair.end
                if isReachable(from: next, to: currentPair.end, occupancy: occupancy) {
                    backtrackPremature(
                        pairIndex: pairIndex,
                        currentPaths: &currentPaths,
                        occupancy: &occupancy,
                        prematureSolution: &prematureSolution,
                        stepCount: &stepCount,
                        maxSteps: maxSteps
                    )
                }

                currentPaths[lineId]?.removeLast()
                occupancy[next.x][next.y] = nil
                if prematureSolution != nil || stepCount >= maxSteps { return }
            }
        }
    }

    private func canRemainingPairsConnect(fromPairIndex: Int, occupancy: [[String?]]) -> Bool {
        guard fromPairIndex < pairs.count else { return true }

        var emptyCount = 0
        for x in 0..<gridSize.width {
            for y in 0..<gridSize.height {
                if occupancy[x][y] == nil { emptyCount += 1 }
            }
        }

        var minRequiredCells = 0
        for p in fromPairIndex..<pairs.count {
            let pair = pairs[p]
            let dist = pair.start.manhattanDistance(to: pair.end)
            minRequiredCells += max(0, dist - 1)
            if !isReachable(from: pair.start, to: pair.end, occupancy: occupancy, allowedLineId: pair.lineId) {
                return false
            }
        }

        if emptyCount < minRequiredCells {
            return false
        }

        return true
    }

    private func isReachable(
        from start: GridCoord,
        to target: GridCoord,
        occupancy: [[String?]],
        allowedLineId: String? = nil
    ) -> Bool {
        if start == target { return true }
        var visited = Set<GridCoord>([start])
        var queue = [start]
        var qIdx = 0

        while qIdx < queue.count {
            let current = queue[qIdx]
            qIdx += 1

            for n in current.orthogonalNeighbors(in: gridSize) {
                if n == target { return true }
                if !visited.contains(n) {
                    let cellOccupant = occupancy[n.x][n.y]
                    if cellOccupant == nil || (allowedLineId != nil && cellOccupant == allowedLineId) {
                        visited.insert(n)
                        queue.append(n)
                    }
                }
            }
        }
        return false
    }

    private func isFullCoverage(_ occupancy: [[String?]]) -> Bool {
        for col in occupancy {
            for cell in col {
                if cell == nil { return false }
            }
        }
        return true
    }
}
