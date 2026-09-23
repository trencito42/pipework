import Foundation

/// Represents a continuous, non-branching chain of orthogonal cells forming a fluid pipe.
public struct PipePath: Codable, Hashable, Sendable, Identifiable {
    public var id: String { lineId }
    public let lineId: String
    public let fluidType: FluidType
    public let terminalA: GridCoord
    public let terminalB: GridCoord
    public private(set) var coordinates: [GridCoord]

    public init(
        lineId: String,
        fluidType: FluidType,
        terminalA: GridCoord,
        terminalB: GridCoord,
        coordinates: [GridCoord] = []
    ) {
        self.lineId = lineId
        self.fluidType = fluidType
        self.terminalA = terminalA
        self.terminalB = terminalB
        self.coordinates = coordinates
    }

    /// The leading head coordinate of the active stroke, if any.
    public var head: GridCoord? {
        coordinates.last
    }

    /// The anchor origin coordinate of the active stroke, if any.
    public var root: GridCoord? {
        coordinates.first
    }

    /// Whether this line is fully connected between both terminals.
    public var isConnected: Bool {
        guard coordinates.count >= 2,
              let first = coordinates.first,
              let last = coordinates.last else {
            return false
        }
        return (first == terminalA && last == terminalB) || (first == terminalB && last == terminalA)
    }

    /// The terminal opposite to the stroke's starting root, or nil if no path is drawn yet.
    public var targetTerminal: GridCoord? {
        guard let first = coordinates.first else { return nil }
        return first == terminalA ? terminalB : terminalA
    }

    /// True if the coordinate is contained anywhere in this path.
    public func contains(_ coord: GridCoord) -> Bool {
        coordinates.contains(coord)
    }

    /// Index of coordinate in path, or nil if not present.
    public func firstIndex(of coord: GridCoord) -> Int? {
        coordinates.firstIndex(of: coord)
    }

    /// Starts a path from the specified terminal.
    public mutating func start(at terminalCoord: GridCoord) {
        precondition(terminalCoord == terminalA || terminalCoord == terminalB, "Can only start at terminal socket")
        coordinates = [terminalCoord]
    }

    /// Extends the path by appending an orthogonally adjacent coordinate.
    public mutating func append(_ coord: GridCoord) {
        guard let currentHead = coordinates.last else {
            precondition(coord == terminalA || coord == terminalB, "First coordinate must be a terminal")
            coordinates = [coord]
            return
        }
        precondition(currentHead.isAdjacent(to: coord), "Appended coordinate must be orthogonally adjacent")
        precondition(!coordinates.contains(coord), "Appended coordinate cannot already exist in path")
        coordinates.append(coord)
    }

    /// Removes the leading head coordinate (backtracks by 1 cell).
    @discardableResult
    public mutating func popLast() -> GridCoord? {
        guard coordinates.count > 1 else {
            // Keep at least the starting terminal, or clear
            return coordinates.popLast()
        }
        return coordinates.popLast()
    }

    /// Truncates the path up to and including the specified coordinate index.
    public mutating func truncate(keepingUpToIndex index: Int) {
        guard index >= 0 && index < coordinates.count else { return }
        coordinates = Array(coordinates.prefix(through: index))
    }

    /// Truncates the path to stop right before the specified coordinate (freeing the coordinate and everything after).
    public mutating func truncate(before coord: GridCoord) {
        guard let idx = coordinates.firstIndex(of: coord) else { return }
        if idx == 0 {
            coordinates.removeAll()
        } else {
            coordinates = Array(coordinates.prefix(upTo: idx))
        }
    }

    /// Completely clears the path.
    public mutating func clear() {
        coordinates.removeAll()
    }
}
