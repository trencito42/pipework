import Foundation

/// Fast CSP backtracking solver with flood-fill island reachability pruning.
public final class PuzzleSolver {

    public struct SolveResult: Sendable {
        public let isSolvable: Bool
        public let solutionCount: Int
        public let paths: [String: [GridCoord]]?
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

    /// Solves the puzzle and finds valid 100% coverage solutions up to maxSolutions.
    public func solve(maxSolutions: Int = 2) -> SolveResult {
        var occupancy = Array(repeating: Array(repeating: Optional<String>.none, count: gridSize.height), count: gridSize.width)
        for t in terminals {
            occupancy[t.coord.x][t.coord.y] = t.lineId
        }

        var currentPaths: [String: [GridCoord]] = [:]
        for p in pairs {
            currentPaths[p.lineId] = [p.start]
        }

        var foundSolutions: [[String: [GridCoord]]] = []
        backtrack(
            pairIndex: 0,
            currentPaths: &currentPaths,
            occupancy: &occupancy,
            foundSolutions: &foundSolutions,
            maxSolutions: maxSolutions
        )

        return SolveResult(
            isSolvable: !foundSolutions.isEmpty,
            solutionCount: foundSolutions.count,
            paths: foundSolutions.first
        )
    }

    private func backtrack(
        pairIndex: Int,
        currentPaths: inout [String: [GridCoord]],
        occupancy: inout [[String?]],
        foundSolutions: inout [[String: [GridCoord]]],
        maxSolutions: Int
    ) {
        if foundSolutions.count >= maxSolutions { return }

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
            backtrack(
                pairIndex: pairIndex + 1,
                currentPaths: &currentPaths,
                occupancy: &occupancy,
                foundSolutions: &foundSolutions,
                maxSolutions: maxSolutions
            )
            return
        }

        // Branch into orthogonal neighbors
        let neighbors = currentHead.orthogonalNeighbors(in: gridSize)
        for next in neighbors {
            // Target endpoint check
            if next == currentPair.end {
                currentPaths[lineId]?.append(next)
                backtrack(
                    pairIndex: pairIndex + 1,
                    currentPaths: &currentPaths,
                    occupancy: &occupancy,
                    foundSolutions: &foundSolutions,
                    maxSolutions: maxSolutions
                )
                currentPaths[lineId]?.removeLast()
                continue
            }

            // Cell must be unoccupied
            if occupancy[next.x][next.y] == nil {
                occupancy[next.x][next.y] = lineId
                currentPaths[lineId]?.append(next)

                if hasNoIsolatedUnreachableEmptyCells(occupancy: occupancy, currentHead: next, target: currentPair.end) {
                    backtrack(
                        pairIndex: pairIndex,
                        currentPaths: &currentPaths,
                        occupancy: &occupancy,
                        foundSolutions: &foundSolutions,
                        maxSolutions: maxSolutions
                    )
                }

                currentPaths[lineId]?.removeLast()
                occupancy[next.x][next.y] = nil
            }
        }
    }

    private func isFullCoverage(_ occupancy: [[String?]]) -> Bool {
        for col in occupancy {
            for cell in col {
                if cell == nil { return false }
            }
        }
        return true
    }

    private func hasNoIsolatedUnreachableEmptyCells(
        occupancy: [[String?]],
        currentHead: GridCoord,
        target: GridCoord
    ) -> Bool {
        for y in 0..<gridSize.height {
            for x in 0..<gridSize.width {
                if occupancy[x][y] == nil {
                    let coord = GridCoord(x: x, y: y)
                    var openNeighbors = 0
                    for n in coord.orthogonalNeighbors(in: gridSize) {
                        if occupancy[n.x][n.y] == nil || n == currentHead || n == target {
                            openNeighbors += 1
                        }
                    }
                    if openNeighbors == 0 {
                        return false
                    }
                }
            }
        }
        return true
    }
}
