import SwiftUI

/// Interprets touch gestures on the board and performs Manhattan raycasting and step-by-step interpolation.
@MainActor
public final class GridGestureInterpreter {
    private var lastTouchedCoord: GridCoord?
    private var isDragging: Bool = false

    public init() {}

    /// Handles touch down at a specific point on the board.
    public func handleTouchDown(
        at point: CGPoint,
        geometry: BoardGeometry,
        state: inout PuzzleState
    ) {
        guard let coord = geometry.coord(for: point) else { return }

        let result = PuzzleRules.startStroke(state: &state, at: coord)
        switch result {
        case .started, .continued:
            lastTouchedCoord = coord
            isDragging = true
            HapticService.shared.terminalTouchDown()
            AudioService.shared.playTerminalGrab()
        case .ignored:
            lastTouchedCoord = nil
            isDragging = false
        }
    }

    /// Handles continuous drag movement, interpolating missing cells if finger moved rapidly.
    public func handleTouchMoved(
        to point: CGPoint,
        geometry: BoardGeometry,
        state: inout PuzzleState
    ) {
        guard isDragging, let targetCoord = geometry.coord(for: point) else { return }
        guard let startCoord = lastTouchedCoord else {
            lastTouchedCoord = targetCoord
            return
        }

        if startCoord == targetCoord { return }

        // Interpolate orthogonal path from startCoord to targetCoord to avoid skipping cells during fast swipes
        let intermediateSteps = interpolateSteps(from: startCoord, to: targetCoord)

        for step in intermediateSteps {
            let stepResult = PuzzleRules.dragStep(state: &state, to: step)
            switch stepResult {
            case .extended:
                HapticService.shared.cellStep()
            case .connected:
                HapticService.shared.lineConnected()
                AudioService.shared.playConnectionLocked()
            case .cut:
                HapticService.shared.lineCut()
                AudioService.shared.playRouteCut()
            case .backtracked:
                HapticService.shared.cellStep()
            case .blocked, .noChange:
                break
            }
        }

        lastTouchedCoord = targetCoord
    }

    /// Handles finger release.
    public func handleTouchEnded(state: inout PuzzleState) {
        guard isDragging else { return }
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
        isDragging = false
        lastTouchedCoord = nil
    }

    /// Calculates a list of orthogonal single-cell steps between two arbitrary coordinates.
    private func interpolateSteps(from: GridCoord, to: GridCoord) -> [GridCoord] {
        var steps: [GridCoord] = []
        var currentX = from.x
        var currentY = from.y

        // Step along X first
        while currentX != to.x {
            currentX += (to.x > currentX) ? 1 : -1
            steps.append(GridCoord(x: currentX, y: currentY))
        }

        // Then step along Y
        while currentY != to.y {
            currentY += (to.y > currentY) ? 1 : -1
            steps.append(GridCoord(x: currentX, y: currentY))
        }

        return steps
    }
}
