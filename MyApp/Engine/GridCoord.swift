import Foundation

/// Represents a discrete 2D grid position on the PIPEWORK board.
/// Origin (0, 0) is top-left: x increases eastward (right), y increases southward (down).
public struct GridCoord: Codable, Hashable, Sendable, CustomStringConvertible, Comparable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public var description: String {
        "(\(x), \(y))"
    }

    /// Manhattan distance to another grid coordinate.
    @inlinable
    public func manhattanDistance(to other: GridCoord) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }

    /// True if this coordinate is orthogonally adjacent (Manhattan distance == 1).
    @inlinable
    public func isAdjacent(to other: GridCoord) -> Bool {
        manhattanDistance(to: other) == 1
    }

    /// Returns the orthogonal direction from this coordinate to an adjacent coordinate, or nil if not adjacent.
    public func direction(to other: GridCoord) -> GridDirection? {
        guard isAdjacent(to: other) else { return nil }
        if other.x == x {
            return other.y > y ? .south : .north
        } else {
            return other.x > x ? .east : .west
        }
    }

    /// Returns the neighbor coordinate offset by the given direction.
    @inlinable
    public func offset(by direction: GridDirection) -> GridCoord {
        GridCoord(x: x + direction.dx, y: y + direction.dy)
    }

    /// Returns all four orthogonal neighbors.
    public var orthogonalNeighbors: [GridCoord] {
        [
            GridCoord(x: x, y: y - 1), // North
            GridCoord(x: x, y: y + 1), // South
            GridCoord(x: x + 1, y: y), // East
            GridCoord(x: x - 1, y: y)  // West
        ]
    }

    /// Returns bounded orthogonal neighbors within a given grid size.
    public func orthogonalNeighbors(in gridSize: GridSize) -> [GridCoord] {
        orthogonalNeighbors.filter { gridSize.contains($0) }
    }

    public static func < (lhs: GridCoord, rhs: GridCoord) -> Bool {
        if lhs.y != rhs.y {
            return lhs.y < rhs.y
        }
        return lhs.x < rhs.x
    }
}
