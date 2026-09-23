import CoreGraphics
import Foundation

/// Result of committing a stroke transaction.
public struct StrokeCommitResult: Sendable, Equatable {
    public let didMutate: Bool
    public let didConnectLine: Bool
    public let moveCountIncremented: Bool
    public let isPuzzleSolved: Bool

    public init(
        didMutate: Bool,
        didConnectLine: Bool,
        moveCountIncremented: Bool,
        isPuzzleSolved: Bool
    ) {
        self.didMutate = didMutate
        self.didConnectLine = didConnectLine
        self.moveCountIncremented = moveCountIncremented
        self.isPuzzleSolved = isPuzzleSolved
    }
}

/// Mode describing how an armed stroke will mutate the board once drag movement actually begins.
public enum ArmedMode: Sendable, Equatable {
    case newFromTerminal(lineId: String, startCoord: GridCoord)
    case resumeFromHead(lineId: String, headCoord: GridCoord)
    case truncateFromMiddle(lineId: String, cutCoord: GridCoord, cutIndex: Int)
}

/// Explicit lifecycle phase of a touch stroke.
public enum StrokePhase: Sendable, Equatable {
    case idle
    case armed(lineId: String, startCoord: GridCoord, mode: ArmedMode, startPoint: CGPoint)
    case dragging(lineId: String, lastAcceptedHead: GridCoord)
}

/// Interprets continuous physical touch trajectories into exact orthogonal grid steps and transactional moves.
@MainActor
public final class GridGestureInterpreter {
    public private(set) var phase: StrokePhase = .idle
    public private(set) var currentAxis: GridDirection.Axis? = nil
    private var previousPointerPoint: CGPoint?
    public let feedbackController: TouchFeedbackController

    public var isStrokeActive: Bool {
        phase != .idle
    }

    public var acceptedPipeHead: GridCoord? {
        switch phase {
        case .idle:
            return nil
        case .armed(_, let startCoord, _, _):
            return startCoord
        case .dragging(_, let lastAcceptedHead):
            return lastAcceptedHead
        }
    }

    public init(feedbackController: TouchFeedbackController) {
        self.feedbackController = feedbackController
    }

    public convenience init() {
        self.init(feedbackController: TouchFeedbackController.shared)
    }

    /// Begins a stroke non-destructively when the player touches down on the board.
    public func beginStroke(
        at point: CGPoint,
        geometry: BoardGeometry,
        state: inout PuzzleState,
        history: inout MoveHistory
    ) {
        feedbackController.prepare()
        guard let startCoord = geometry.coord(for: point) else {
            phase = .idle
            previousPointerPoint = nil
            currentAxis = nil
            return
        }

        // Check if starting at a terminal or existing pipe
        if let terminal = state.terminalLookup[startCoord] {
            let lineId = terminal.lineId
            var mode: ArmedMode = .newFromTerminal(lineId: lineId, startCoord: startCoord)

            if let existingPath = state.paths[lineId], !existingPath.coordinates.isEmpty {
                if existingPath.head == startCoord || existingPath.root == startCoord {
                    mode = .resumeFromHead(lineId: lineId, headCoord: startCoord)
                } else {
                    mode = .newFromTerminal(lineId: lineId, startCoord: startCoord)
                }
            }

            phase = .armed(lineId: lineId, startCoord: startCoord, mode: mode, startPoint: point)
            previousPointerPoint = point
            currentAxis = nil
            history.beginTransaction(with: state)
            feedbackController.handle(.terminalPickup)
            return
        }

        // Check if touching inside an existing line path
        for (lineId, path) in state.paths {
            if let idx = path.coordinates.firstIndex(of: startCoord) {
                let mode: ArmedMode
                if idx == path.coordinates.count - 1 {
                    mode = .resumeFromHead(lineId: lineId, headCoord: startCoord)
                } else {
                    mode = .truncateFromMiddle(lineId: lineId, cutCoord: startCoord, cutIndex: idx)
                }

                phase = .armed(lineId: lineId, startCoord: startCoord, mode: mode, startPoint: point)
                previousPointerPoint = point
                currentAxis = nil
                history.beginTransaction(with: state)
                feedbackController.handle(.terminalPickup)
                return
            }
        }

        // Empty non-socket cell tap
        phase = .idle
        previousPointerPoint = nil
        currentAxis = nil
    }

    /// Continues dragging the finger across the board.
    public func continueStroke(
        to point: CGPoint,
        geometry: BoardGeometry,
        state: inout PuzzleState
    ) {
        switch phase {
        case .idle:
            return

        case .armed(let lineId, let startCoord, let mode, let startPoint):
            let deadband: CGFloat = geometry.cellSize * 0.25
            let dx = point.x - startPoint.x
            let dy = point.y - startPoint.y
            let dist = hypot(dx, dy)

            guard dist >= deadband else {
                return
            }

            // Exceeded deadband: mutate board according to armed mode
            switch mode {
            case .newFromTerminal(let lId, let sCoord):
                var path = state.paths[lId] ?? PipePath(
                    lineId: lId,
                    fluidType: state.terminalLookup[sCoord]?.fluidType ?? .coolant,
                    terminalA: sCoord,
                    terminalB: sCoord
                )
                path.clear()
                path.start(at: sCoord)
                state.updatePath(for: lId, path: path)

            case .resumeFromHead:
                break

            case .truncateFromMiddle(let lId, _, let cutIndex):
                if var path = state.paths[lId] {
                    path.truncate(keepingUpToIndex: cutIndex)
                    state.updatePath(for: lId, path: path)
                }
            }

            state.activeLineId = lineId
            phase = .dragging(lineId: lineId, lastAcceptedHead: startCoord)
            currentAxis = abs(dx) >= abs(dy) ? .horizontal : .vertical

            // Immediately process trajectory from startPoint to current point
            let crossed = ContinuousGridTraverser.crossedCells(
                from: startPoint,
                to: point,
                geometry: geometry,
                currentAxis: currentAxis
            )

            var head = startCoord
            for step in crossed {
                head = processStep(to: step, lineId: lineId, currentHead: head, state: &state)
            }

            phase = .dragging(lineId: lineId, lastAcceptedHead: head)
            previousPointerPoint = point

        case .dragging(let lineId, let lastHead):
            let fromPoint = previousPointerPoint ?? geometry.center(for: lastHead)
            let crossed = ContinuousGridTraverser.crossedCells(
                from: fromPoint,
                to: point,
                geometry: geometry,
                currentAxis: currentAxis
            )

            var head = lastHead
            for step in crossed {
                head = processStep(to: step, lineId: lineId, currentHead: head, state: &state)
            }

            phase = .dragging(lineId: lineId, lastAcceptedHead: head)
            previousPointerPoint = point
        }
    }

    /// Ends the stroke cleanly and atomically commits or discards the move.
    @discardableResult
    public func endStroke(
        at finalPoint: CGPoint? = nil,
        geometry: BoardGeometry? = nil,
        state: inout PuzzleState,
        history: inout MoveHistory
    ) -> StrokeCommitResult {
        if let finalPoint = finalPoint, let geometry = geometry {
            continueStroke(to: finalPoint, geometry: geometry, state: &state)
        }

        switch phase {
        case .idle:
            phase = .idle
            previousPointerPoint = nil
            currentAxis = nil
            feedbackController.resetStrokeState()
            return StrokeCommitResult(didMutate: false, didConnectLine: false, moveCountIncremented: false, isPuzzleSolved: false)

        case .armed:
            _ = history.rollbackTransaction()
            phase = .idle
            previousPointerPoint = nil
            currentAxis = nil
            feedbackController.resetStrokeState()
            return StrokeCommitResult(didMutate: false, didConnectLine: false, moveCountIncremented: false, isPuzzleSolved: false)

        case .dragging(let lineId, _):
            state.activeLineId = nil
            phase = .idle
            previousPointerPoint = nil
            currentAxis = nil
            feedbackController.resetStrokeState()

            let hasMutated = history.commitTransaction(with: state)
            let isConnected = state.paths[lineId]?.isConnected ?? false

            if hasMutated {
                state.moveCount += 1
            }

            let isSolved = state.isSolved
            if isSolved {
                feedbackController.handle(.boardCompleted)
            }

            return StrokeCommitResult(
                didMutate: hasMutated,
                didConnectLine: isConnected,
                moveCountIncremented: hasMutated,
                isPuzzleSolved: isSolved
            )
        }
    }

    /// Cancels an in-flight gesture (e.g. system gesture interrupt or touch cancelled).
    public func cancelStroke(
        state: inout PuzzleState,
        history: inout MoveHistory
    ) {
        if let restored = history.rollbackTransaction() {
            state = restored
        }
        state.activeLineId = nil
        phase = .idle
        previousPointerPoint = nil
        currentAxis = nil
        feedbackController.resetStrokeState()
    }

    // MARK: - Step Reconciliation

    private func processStep(
        to target: GridCoord,
        lineId: String,
        currentHead: GridCoord,
        state: inout PuzzleState
    ) -> GridCoord {
        guard target != currentHead else { return currentHead }

        // Update axis intent
        if let dir = currentHead.direction(to: target) {
            currentAxis = dir.axis
        }

        let stepResult = PuzzleRules.dragStep(state: &state, to: target)
        switch stepResult {
        case .extended:
            feedbackController.handle(.stepForward(target))
            return target

        case .backtracked:
            feedbackController.handle(.stepBackward(target))
            return target

        case .connected:
            feedbackController.handle(.lineConnected)
            return target

        case .cut:
            feedbackController.handle(.routeCut)
            return target

        case .blocked:
            feedbackController.handle(.blocked(target))
            return currentHead

        case .noChange:
            return currentHead
        }
    }
}
