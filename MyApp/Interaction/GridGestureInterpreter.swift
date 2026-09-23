import SwiftUI

/// Interprets touch gestures on the board with precise orthogonal stepping and snapshot undo tracking.
@MainActor
public final class GridGestureInterpreter {
    private var isStrokeActive: Bool = false
    private var lastHeadCoord: GridCoord?

    public init() {}

    /// Begins a stroke when the player touches down on the board.
    public func beginStroke(
        at point: CGPoint,
        geometry: BoardGeometry,
        state: inout PuzzleState,
        history: inout MoveHistory
    ) {
        guard let coord = geometry.coord(for: point) else { return }

        // Save history snapshot before making changes
        history.pushSnapshot(state)

        let result = PuzzleRules.startStroke(state: &state, at: coord)
        switch result {
        case .started, .continued:
            isStrokeActive = true
            lastHeadCoord = coord
            HapticService.shared.terminalTouchDown()
            AudioService.shared.playTerminalGrab()
        case .ignored:
            isStrokeActive = false
            lastHeadCoord = nil
            // No changes made; remove redundant snapshot
            _ = history.undo(currentState: state)
        }
    }

    /// Continues dragging, stepping towards the current pointer cell one orthogonal unit at a time.
    public func continueStroke(
        to point: CGPoint,
        geometry: BoardGeometry,
        state: inout PuzzleState
    ) {
        guard isStrokeActive,
              let activeLineId = state.activeLineId,
              let activePath = state.paths[activeLineId],
              let currentHead = activePath.head,
              let targetCell = geometry.coord(for: point) else { return }

        if currentHead == targetCell { return }

        // Step orthogonally towards targetCell cell-by-cell
        var stepHead = currentHead
        var safetyLimit = 0
        let maxSteps = state.gridSize.width + state.gridSize.height

        while stepHead != targetCell && safetyLimit < maxSteps {
            safetyLimit += 1

            let dx = targetCell.x - stepHead.x
            let dy = targetCell.y - stepHead.y

            let nextX: Int
            let nextY: Int

            // Step in the axis of greater distance, or based on pixel offset within the cell
            if abs(dx) >= abs(dy) && dx != 0 {
                nextX = stepHead.x + (dx > 0 ? 1 : -1)
                nextY = stepHead.y
            } else if dy != 0 {
                nextX = stepHead.x
                nextY = stepHead.y + (dy > 0 ? 1 : -1)
            } else {
                break
            }

            let nextCoord = GridCoord(x: nextX, y: nextY)
            let result = PuzzleRules.dragStep(state: &state, to: nextCoord)

            switch result {
            case .extended:
                HapticService.shared.cellStep()
                stepHead = nextCoord
            case .connected:
                HapticService.shared.lineConnected()
                AudioService.shared.playConnectionLocked()
                stepHead = nextCoord
                // Stroke is locked to target terminal
                return
            case .cut:
                HapticService.shared.lineCut()
                AudioService.shared.playRouteCut()
                stepHead = nextCoord
            case .backtracked:
                HapticService.shared.cellStep()
                stepHead = nextCoord
            case .blocked, .noChange:
                // Obstacle encountered (e.g. enemy terminal or edge)
                return
            }
        }

        lastHeadCoord = stepHead
    }

    /// Ends the stroke on finger release.
    public func endStroke(state: inout PuzzleState) {
        guard isStrokeActive else { return }
        let result = PuzzleRules.endStroke(state: &state)
        switch result {
        case .completed(_, _, let puzzleSolved):
            if puzzleSolved {
                HapticService.shared.boardCompleted()
                AudioService.shared.playPressureStabilized()
            }
        case .cancelled:
            break
        }
        isStrokeActive = false
        lastHeadCoord = nil
    }
}
