import CoreGraphics
import Foundation

/// Interprets continuous physical touch trajectories into exact orthogonal grid steps and transactional moves.
@MainActor
public final class GridGestureInterpreter {
    private var isStrokeActive: Bool = false
    private var previousPointerPoint: CGPoint?
    private var acceptedPipeHead: GridCoord?

    public init() {}

    /// Begins a stroke when the player touches down on the board.
    public func beginStroke(
        at point: CGPoint,
        geometry: BoardGeometry,
        state: inout PuzzleState,
        history: inout MoveHistory
    ) {
        guard let startCoord = geometry.coord(for: point) else { return }

        // Capture pre-stroke snapshot for undo and transaction validation
        history.beginTransaction(with: state)

        let result = PuzzleRules.startStroke(state: &state, at: startCoord)
        switch result {
        case .started, .continued:
            isStrokeActive = true
            previousPointerPoint = point
            acceptedPipeHead = startCoord
            HapticService.shared.terminalTouchDown()
            AudioService.shared.playTerminalGrab()
        case .ignored:
            isStrokeActive = false
            previousPointerPoint = nil
            acceptedPipeHead = nil
            history.discardTransaction()
        }
    }

    /// Processes continuous finger movement across the board using 2D boundary raycasting.
    public func continueStroke(
        to point: CGPoint,
        geometry: BoardGeometry,
        state: inout PuzzleState
    ) {
        guard isStrokeActive, let prevPoint = previousPointerPoint else {
            previousPointerPoint = point
            return
        }

        previousPointerPoint = point

        // Calculate chronological sequence of crossed orthogonal cell boundaries
        let crossed = ContinuousGridTraverser.crossedCells(
            from: prevPoint,
            to: point,
            geometry: geometry
        )

        for nextCoord in crossed {
            let stepResult = PuzzleRules.dragStep(state: &state, to: nextCoord)
            switch stepResult {
            case .extended:
                acceptedPipeHead = nextCoord
                HapticService.shared.cellStep()
            case .connected:
                acceptedPipeHead = nextCoord
                HapticService.shared.lineConnected()
                AudioService.shared.playConnectionLocked()
            case .cut:
                acceptedPipeHead = nextCoord
                HapticService.shared.lineCut()
                AudioService.shared.playRouteCut()
            case .backtracked:
                acceptedPipeHead = nextCoord
                HapticService.shared.cellStep()
            case .blocked, .noChange:
                // Blocked step keeps pointer moving without desyncing
                break
            }
        }
    }

    /// Finalizes the stroke on finger release and commits transactionally.
    public func endStroke(
        state: inout PuzzleState,
        history: inout MoveHistory
    ) {
        guard isStrokeActive else { return }

        // If the stroke ended with only 1 cell (just the socket itself with no extension),
        // and it was not previously connected, clean it up so it is a true no-op
        if let activeLineId = state.activeLineId,
           let path = state.paths[activeLineId],
           path.coordinates.count <= 1 {
            var cleared = path
            cleared.clear()
            state.updatePath(for: activeLineId, path: cleared)
        }

        let endResult = PuzzleRules.endStroke(state: &state)
        let didMutate = history.commitTransaction(with: state)

        if didMutate {
            state.moveCount += 1
        }

        switch endResult {
        case .completed(_, _, let puzzleSolved):
            if puzzleSolved {
                HapticService.shared.boardCompleted()
                AudioService.shared.playPressureStabilized()
            }
        case .cancelled:
            break
        }

        isStrokeActive = false
        previousPointerPoint = nil
        acceptedPipeHead = nil
    }
}
