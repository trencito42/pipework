import SwiftUI

/// Calculates spatial layout, coordinate transforms, and hit-testing for the puzzle board.
public struct BoardGeometry: Sendable {
    public let gridSize: GridSize
    public let boardRect: CGRect
    public let cellSize: CGFloat
    public let origin: CGPoint
    public let margin: CGFloat

    public init(gridSize: GridSize, containerSize: CGSize, margin: CGFloat = 8) {
        self.gridSize = gridSize
        self.margin = margin

        let availableWidth = max(containerSize.width - (margin * 2), 100)
        let availableHeight = max(containerSize.height - (margin * 2), 100)
        let boardSide = min(availableWidth, availableHeight)

        self.cellSize = boardSide / CGFloat(gridSize.width)

        let originX = (containerSize.width - boardSide) / 2.0
        let originY = (containerSize.height - boardSide) / 2.0
        self.origin = CGPoint(x: originX, y: originY)
        self.boardRect = CGRect(x: originX, y: originY, width: boardSide, height: boardSide)
    }

    /// Converts a screen touch point to the corresponding GridCoord with margin tolerance.
    public func coord(for point: CGPoint) -> GridCoord? {
        let hitRect = boardRect.insetBy(dx: -cellSize * 0.5, dy: -cellSize * 0.5)
        guard hitRect.contains(point) else { return nil }

        let relX = point.x - origin.x
        let relY = point.y - origin.y

        let col = Int(floor(relX / cellSize))
        let row = Int(floor(relY / cellSize))

        let clampedCol = max(0, min(gridSize.width - 1, col))
        let clampedRow = max(0, min(gridSize.height - 1, row))

        return GridCoord(x: clampedCol, y: clampedRow)
    }

    /// Returns the center CGPoint for a given grid cell.
    public func center(for coord: GridCoord) -> CGPoint {
        let x = origin.x + (CGFloat(coord.x) + 0.5) * cellSize
        let y = origin.y + (CGFloat(coord.y) + 0.5) * cellSize
        return CGPoint(x: x, y: y)
    }

    /// Returns the bounding CGRect for a given grid cell.
    public func cellRect(for coord: GridCoord) -> CGRect {
        let x = origin.x + CGFloat(coord.x) * cellSize
        let y = origin.y + CGFloat(coord.y) * cellSize
        return CGRect(x: x, y: y, width: cellSize, height: cellSize)
    }
}
