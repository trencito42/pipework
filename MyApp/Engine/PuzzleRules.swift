import Foundation

/// Result types for engine interaction steps.
public enum StrokeStartResult: Sendable, Equatable {
    case started(lineId: String, startingCoord: GridCoord)
    case continued(lineId: String, headCoord: GridCoord)
    case ignored(reason: String)
}

public enum DragStepResult: Sendable, Equatable {
    case extended(lineId: String, newHead: GridCoord)
    case connected(lineId: String, terminal: GridCoord)
    case backtracked(lineId: String, currentHead: GridCoord)
    case cut(severedLineId: String, activeLineId: String, newHead: GridCoord)
    case blocked(reason: String)
    case noChange
}

public enum StrokeEndResult: Sendable, Equatable {
    case completed(lineId: String, isConnected: Bool, puzzleSolved: Bool)
    case cancelled
}

/// Pure Swift engine evaluator for touch actions and board transformations.
public enum PuzzleRules {

    /// Initiates a drawing stroke at the given coordinate.
    @discardableResult
    public static func startStroke(
        state: inout PuzzleState,
        at coord: GridCoord
    ) -> StrokeStartResult {
        guard state.gridSize.contains(coord) else {
            return .ignored(reason: "Coordinate out of bounds")
        }

        // Case 1: Touched a terminal socket
        if let terminal = state.terminal(at: coord) {
            let lineId = terminal.lineId
            guard var path = state.paths[lineId] else {
                return .ignored(reason: "Missing path definition for line \(lineId)")
            }

            // Start fresh path anchored at this touched terminal
            path.start(at: coord)
            state.updatePath(for: lineId, path: path)
            state.activeLineId = lineId
            return .started(lineId: lineId, startingCoord: coord)
        }

        // Case 2: Touched an existing intermediate line path
        if let occupyingLineId = state.lineOccupying(coord),
           var path = state.paths[occupyingLineId],
           let index = path.firstIndex(of: coord) {
            // Truncate path to make this touched cell the leading head
            path.truncate(keepingUpToIndex: index)
            state.updatePath(for: occupyingLineId, path: path)
            state.activeLineId = occupyingLineId
            return .continued(lineId: occupyingLineId, headCoord: coord)
        }

        return .ignored(reason: "Empty cell touched without active line")
    }

    /// Advances the active stroke by one orthogonal step towards targetCoord.
    @discardableResult
    public static func dragStep(
        state: inout PuzzleState,
        to targetCoord: GridCoord
    ) -> DragStepResult {
        guard let activeLineId = state.activeLineId,
              var activePath = state.paths[activeLineId],
              let currentHead = activePath.head else {
            return .blocked(reason: "No active stroke")
        }

        // Bounds check
        guard state.gridSize.contains(targetCoord) else {
            return .blocked(reason: "Target out of bounds")
        }

        // Ignore if already at target
        if currentHead == targetCoord {
            return .noChange
        }

        // Must be orthogonally adjacent
        guard currentHead.isAdjacent(to: targetCoord) else {
            return .blocked(reason: "Non-adjacent step")
        }

        // If line is already connected to its destination terminal, do not extend further unless backtracking
        if activePath.isConnected {
            // Check if user is backtracking from the connected terminal
            if activePath.coordinates.count >= 2 && activePath.coordinates[activePath.coordinates.count - 2] == targetCoord {
                activePath.popLast()
                state.updatePath(for: activeLineId, path: activePath)
                return .backtracked(lineId: activeLineId, currentHead: targetCoord)
            }
            return .blocked(reason: "Line already connected")
        }

        // Check if targetCoord is part of active line's own path (Backtracking / Redrawing)
        if let selfIndex = activePath.firstIndex(of: targetCoord) {
            // Check if stepping back to immediate predecessor (1-cell backtrack)
            if selfIndex == activePath.coordinates.count - 2 {
                activePath.popLast()
                state.updatePath(for: activeLineId, path: activePath)
                return .backtracked(lineId: activeLineId, currentHead: targetCoord)
            } else {
                // Deep backtrack / truncate to earlier node
                activePath.truncate(keepingUpToIndex: selfIndex)
                state.updatePath(for: activeLineId, path: activePath)
                return .backtracked(lineId: activeLineId, currentHead: targetCoord)
            }
        }

        // Check if targetCoord contains a terminal socket
        if let targetTerminal = state.terminal(at: targetCoord) {
            // Check if it belongs to another line
            if targetTerminal.lineId != activeLineId {
                return .blocked(reason: "Cannot cross or enter enemy terminal")
            }

            // Belongs to active line: must be the target terminal (opposite of root)
            if targetCoord == activePath.targetTerminal {
                activePath.append(targetCoord)
                state.updatePath(for: activeLineId, path: activePath)
                return .connected(lineId: activeLineId, terminal: targetCoord)
            } else {
                // Starting terminal: already handled by selfIndex check or ignored
                return .blocked(reason: "Cannot self-intersect starting terminal")
            }
        }

        // Check if targetCoord is occupied by another line (Auto-Cut Handling)
        var severedLineId: String? = nil
        if let otherLineId = state.lineOccupying(targetCoord), otherLineId != activeLineId {
            guard var otherPath = state.paths[otherLineId] else {
                return .blocked(reason: "Invalid conflicting state")
            }

            // Sever the other path before targetCoord
            otherPath.truncate(before: targetCoord)
            state.updatePath(for: otherLineId, path: otherPath)
            severedLineId = otherLineId
        }

        // Append targetCoord to active path
        activePath.append(targetCoord)
        state.updatePath(for: activeLineId, path: activePath)

        if let severed = severedLineId {
            return .cut(severedLineId: severed, activeLineId: activeLineId, newHead: targetCoord)
        } else {
            return .extended(lineId: activeLineId, newHead: targetCoord)
        }
    }

    /// Finalizes the current drawing stroke.
    @discardableResult
    public static func endStroke(state: inout PuzzleState) -> StrokeEndResult {
        guard let activeLineId = state.activeLineId,
              let activePath = state.paths[activeLineId] else {
            state.activeLineId = nil
            return .cancelled
        }

        state.moveCount += 1
        state.activeLineId = nil
        let isConnected = activePath.isConnected
        let isSolved = state.isSolved

        return .completed(
            lineId: activeLineId,
            isConnected: isConnected,
            puzzleSolved: isSolved
        )
    }
}
