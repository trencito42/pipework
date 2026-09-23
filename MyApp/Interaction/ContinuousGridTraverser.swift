import CoreGraphics
import Foundation

/// 2D grid raycaster translating continuous pixel touch trajectories into exact chronological orthogonal cell crossings.
public enum ContinuousGridTraverser {

    /// Computes the ordered sequence of orthogonal grid cells entered when moving from `startPoint` to `endPoint`.
    /// Guaranteed to NEVER produce a diagonal grid transition.
    /// Incorporates directional hysteresis and axis intent to eliminate corner twitching and wobbles.
    public static func crossedCells(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        geometry: BoardGeometry,
        currentAxis: GridDirection.Axis? = nil
    ) -> [GridCoord] {
        let cs = geometry.cellSize
        guard cs > 0 else { return [] }

        let origin = geometry.origin
        let gridSize = geometry.gridSize

        // Convert points to continuous grid-relative coordinates (u, v)
        let u0 = (startPoint.x - origin.x) / cs
        let v0 = (startPoint.y - origin.y) / cs
        let u1 = (endPoint.x - origin.x) / cs
        let v1 = (endPoint.y - origin.y) / cs

        let col0 = max(0, min(gridSize.width - 1, Int(floor(u0))))
        let row0 = max(0, min(gridSize.height - 1, Int(floor(v0))))
        let col1 = max(0, min(gridSize.width - 1, Int(floor(u1))))
        let row1 = max(0, min(gridSize.height - 1, Int(floor(v1))))

        // If both points reside within the same cell, no boundary is crossed
        if col0 == col1 && row0 == row1 {
            return []
        }

        let du = u1 - u0
        let dv = v1 - v0

        let stepX = du > 0 ? 1 : (du < 0 ? -1 : 0)
        let stepY = dv > 0 ? 1 : (dv < 0 ? -1 : 0)

        // Calculate initial distance to next grid boundary in parametric t [0, 1]
        var tMaxX: Double
        if stepX > 0 {
            let nextBoundX = Double(col0 + 1)
            tMaxX = (nextBoundX - Double(u0)) / Double(du)
        } else if stepX < 0 {
            let nextBoundX = Double(col0)
            tMaxX = (nextBoundX - Double(u0)) / Double(du)
        } else {
            tMaxX = Double.infinity
        }

        var tMaxY: Double
        if stepY > 0 {
            let nextBoundY = Double(row0 + 1)
            tMaxY = (nextBoundY - Double(v0)) / Double(dv)
        } else if stepY < 0 {
            let nextBoundY = Double(row0)
            tMaxY = (nextBoundY - Double(v0)) / Double(dv)
        } else {
            tMaxY = Double.infinity
        }

        let tDeltaX = stepX != 0 ? abs(1.0 / Double(du)) : Double.infinity
        let tDeltaY = stepY != 0 ? abs(1.0 / Double(dv)) : Double.infinity

        var currentCol = col0
        var currentRow = row0
        var result: [GridCoord] = []
        var iterations = 0
        let maxIterations = (gridSize.width + gridSize.height) * 2
        let epsilon = 1e-6

        while (currentCol != col1 || currentRow != row1) && iterations < maxIterations {
            iterations += 1

            let isNearCorner = abs(tMaxX - tMaxY) < epsilon && tMaxX <= 1.0 + epsilon

            if isNearCorner {
                // Exact corner crossing tie-break:
                // 1. Prefer current axis intent if active
                // 2. Otherwise prefer dominant physical pointer delta
                let preferHorizontal: Bool
                if let axis = currentAxis {
                    preferHorizontal = (axis == .horizontal)
                } else {
                    preferHorizontal = abs(du) >= abs(dv)
                }

                if preferHorizontal {
                    currentCol += stepX
                    if currentCol >= 0 && currentCol < gridSize.width {
                        result.append(GridCoord(x: currentCol, y: currentRow))
                    }
                    tMaxX += tDeltaX

                    if currentRow != row1 {
                        currentRow += stepY
                        if currentRow >= 0 && currentRow < gridSize.height {
                            result.append(GridCoord(x: currentCol, y: currentRow))
                        }
                        tMaxY += tDeltaY
                    }
                } else {
                    currentRow += stepY
                    if currentRow >= 0 && currentRow < gridSize.height {
                        result.append(GridCoord(x: currentCol, y: currentRow))
                    }
                    tMaxY += tDeltaY

                    if currentCol != col1 {
                        currentCol += stepX
                        if currentCol >= 0 && currentCol < gridSize.width {
                            result.append(GridCoord(x: currentCol, y: currentRow))
                        }
                        tMaxX += tDeltaX
                    }
                }
            } else if tMaxX < tMaxY {
                currentCol += stepX
                tMaxX += tDeltaX
                if currentCol >= 0 && currentCol < gridSize.width {
                    result.append(GridCoord(x: currentCol, y: currentRow))
                }
            } else {
                currentRow += stepY
                tMaxY += tDeltaY
                if currentRow >= 0 && currentRow < gridSize.height {
                    result.append(GridCoord(x: currentCol, y: currentRow))
                }
            }
        }

        return result
    }

    /// Generates a strictly orthogonal path between two coordinates, resolving any multi-cell jump.
    public static func orthogonalPath(
        from startCoord: GridCoord,
        to targetCoord: GridCoord,
        preferredAxis: GridDirection.Axis? = nil
    ) -> [GridCoord] {
        if startCoord == targetCoord { return [] }

        var path: [GridCoord] = []
        var current = startCoord

        let dx = targetCoord.x - startCoord.x
        let dy = targetCoord.y - startCoord.y

        let stepX = dx > 0 ? 1 : (dx < 0 ? -1 : 0)
        let stepY = dy > 0 ? 1 : (dy < 0 ? -1 : 0)

        let preferX: Bool
        if let axis = preferredAxis {
            preferX = (axis == .horizontal)
        } else {
            preferX = abs(dx) >= abs(dy)
        }

        if preferX {
            while current.x != targetCoord.x {
                current = GridCoord(x: current.x + stepX, y: current.y)
                path.append(current)
            }
            while current.y != targetCoord.y {
                current = GridCoord(x: current.x, y: current.y + stepY)
                path.append(current)
            }
        } else {
            while current.y != targetCoord.y {
                current = GridCoord(x: current.x, y: current.y + stepY)
                path.append(current)
            }
            while current.x != targetCoord.x {
                current = GridCoord(x: current.x + stepX, y: current.y)
                path.append(current)
            }
        }

        return path
    }
}
