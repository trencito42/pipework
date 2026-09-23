import Foundation

/// Represents the geometric dimensions and bounding geometry of a PIPEWORK board.
public struct GridSize: Codable, Hashable, Sendable, CustomStringConvertible {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        precondition(width >= 3 && height >= 3, "Grid dimensions must be at least 3x3")
        self.width = width
        self.height = height
    }

    public init(dimension: Int) {
        self.init(width: dimension, height: dimension)
    }

    public var totalCells: Int {
        width * height
    }

    public var isSquare: Bool {
        width == height
    }

    public var description: String {
        "\(width)x\(height)"
    }

    /// Checks if a coordinate is strictly within grid bounds.
    @inlinable
    public func contains(_ coord: GridCoord) -> Bool {
        coord.x >= 0 && coord.x < width && coord.y >= 0 && coord.y < height
    }

    /// Sequence of all valid coordinates within this grid.
    public var allCoordinates: [GridCoord] {
        var coords: [GridCoord] = []
        coords.reserveCapacity(totalCells)
        for y in 0..<height {
            for x in 0..<width {
                coords.append(GridCoord(x: x, y: y))
            }
        }
        return coords
    }
}
