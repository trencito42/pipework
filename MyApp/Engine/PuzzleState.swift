import Foundation

/// Immutable snapshot and authoritative state of the PIPEWORK puzzle.
public struct PuzzleState: Codable, Hashable, Sendable {
    public let gridSize: GridSize
    public let terminals: [Terminal]
    public private(set) var terminalLookup: [GridCoord: Terminal]
    public private(set) var paths: [String: PipePath]
    public var activeLineId: String?
    public var moveCount: Int

    public init(gridSize: GridSize, terminals: [Terminal]) {
        self.gridSize = gridSize
        self.terminals = terminals
        
        var lookup: [GridCoord: Terminal] = [:]
        var initialPaths: [String: PipePath] = [:]
        
        // Group terminals by lineId
        var lineTerminals: [String: [Terminal]] = [:]
        for terminal in terminals {
            lookup[terminal.coord] = terminal
            lineTerminals[terminal.lineId, default: []].append(terminal)
        }
        
        for (lineId, termList) in lineTerminals {
            guard termList.count == 2 else {
                fatalError("Line \(lineId) must have exactly 2 terminals")
            }
            let fluid = termList[0].fluidType
            let termA = termList[0].coord
            let termB = termList[1].coord
            initialPaths[lineId] = PipePath(
                lineId: lineId,
                fluidType: fluid,
                terminalA: termA,
                terminalB: termB,
                coordinates: []
            )
        }
        
        self.terminalLookup = lookup
        self.paths = initialPaths
        self.activeLineId = nil
        self.moveCount = 0
    }

    // MARK: - Computed Status

    /// Total unique board cells currently occupied by active pipes.
    public var occupiedCoordinates: Set<GridCoord> {
        var set = Set<GridCoord>()
        for path in paths.values {
            for coord in path.coordinates {
                set.insert(coord)
            }
        }
        return set
    }

    /// Number of occupied usable cells.
    public var occupiedCellCount: Int {
        occupiedCoordinates.count
    }

    /// Total number of cells on the board.
    public var totalCellCount: Int {
        gridSize.totalCells
    }

    /// Board pressure ratio (0.0 to 1.0).
    public var pressure: Double {
        guard totalCellCount > 0 else { return 0.0 }
        return Double(occupiedCellCount) / Double(totalCellCount)
    }

    /// Board pressure percentage integer (0 to 100).
    public var pressurePercentage: Int {
        Int(round(pressure * 100.0))
    }

    /// Number of fully connected line pairs.
    public var connectedLineCount: Int {
        paths.values.filter { $0.isConnected }.count
    }

    /// Total number of line pairs in this puzzle.
    public var totalLineCount: Int {
        paths.count
    }

    /// True if all pairs are connected AND board coverage is 100%.
    public var isSolved: Bool {
        connectedLineCount == totalLineCount && occupiedCellCount == totalCellCount
    }

    /// Checks which line occupies the given coordinate, if any.
    public func lineOccupying(_ coord: GridCoord) -> String? {
        for (lineId, path) in paths {
            if path.contains(coord) {
                return lineId
            }
        }
        return nil
    }

    /// Returns the terminal at the coordinate, if any.
    public func terminal(at coord: GridCoord) -> Terminal? {
        terminalLookup[coord]
    }

    // MARK: - Mutating Engine Actions

    /// Sets the path for a given line.
    public mutating func updatePath(for lineId: String, path: PipePath) {
        paths[lineId] = path
    }

    /// Resets all paths to empty state.
    public mutating func resetAllPaths() {
        for lineId in paths.keys {
            if let existing = paths[lineId] {
                paths[lineId] = PipePath(
                    lineId: lineId,
                    fluidType: existing.fluidType,
                    terminalA: existing.terminalA,
                    terminalB: existing.terminalB,
                    coordinates: []
                )
            }
        }
        activeLineId = nil
        moveCount = 0
    }
}
