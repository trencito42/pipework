import Foundation

/// Manages undo and history snapshots for a puzzle session.
public struct MoveHistory: Sendable {
    private var undoStack: [PuzzleState]
    private var redoStack: [PuzzleState]
    public let maxHistoryDepth: Int

    public init(maxHistoryDepth: Int = 50) {
        self.undoStack = []
        self.redoStack = []
        self.maxHistoryDepth = maxHistoryDepth
    }

    public var canUndo: Bool {
        !undoStack.isEmpty
    }

    public var canRedo: Bool {
        !redoStack.isEmpty
    }

    /// Pushes the state prior to a new user action.
    public mutating func pushSnapshot(_ state: PuzzleState) {
        undoStack.append(state)
        if undoStack.count > maxHistoryDepth {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    /// Reverts to the most recent previous state, pushing currentState to redo stack.
    public mutating func undo(currentState: PuzzleState) -> PuzzleState? {
        guard let previous = undoStack.popLast() else { return nil }
        redoStack.append(currentState)
        return previous
    }

    /// Reapplies a previously undone state, pushing currentState to undo stack.
    public mutating func redo(currentState: PuzzleState) -> PuzzleState? {
        guard let next = redoStack.popLast() else { return nil }
        undoStack.append(currentState)
        return next
    }

    /// Clears all undo and redo history.
    public mutating func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
