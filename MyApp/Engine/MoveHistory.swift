import Foundation

/// Transactional undo/redo history manager for PIPEWORK.
public struct MoveHistory: Sendable {
    private var undoStack: [PuzzleState]
    private var redoStack: [PuzzleState]
    private var transactionSnapshot: PuzzleState?
    public let maxHistoryDepth: Int

    public init(maxHistoryDepth: Int = 50) {
        self.undoStack = []
        self.redoStack = []
        self.transactionSnapshot = nil
        self.maxHistoryDepth = maxHistoryDepth
    }

    public var canUndo: Bool {
        !undoStack.isEmpty
    }

    public var canRedo: Bool {
        !redoStack.isEmpty
    }

    public var isInTransaction: Bool {
        transactionSnapshot != nil
    }

    /// Begins a gesture stroke transaction, capturing pre-stroke state.
    public mutating func beginTransaction(with state: PuzzleState) {
        transactionSnapshot = state
    }

    /// Commits the active transaction if the board state actually changed.
    /// Returns true if a move was committed (state changed), false if discarded (no-op).
    @discardableResult
    public mutating func commitTransaction(with finalState: PuzzleState) -> Bool {
        guard let initial = transactionSnapshot else { return false }
        transactionSnapshot = nil

        // Check if paths actually changed
        if initial.paths == finalState.paths {
            // No logical change occurred; do not record a move or push undo history
            return false
        }

        undoStack.append(initial)
        if undoStack.count > maxHistoryDepth {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
        return true
    }

    /// Discards the current transaction without recording an undo snapshot.
    public mutating func discardTransaction() {
        transactionSnapshot = nil
    }

    /// Atomically rolls back the active transaction and returns the pre-stroke snapshot.
    public mutating func rollbackTransaction() -> PuzzleState? {
        let snapshot = transactionSnapshot
        transactionSnapshot = nil
        return snapshot
    }

    /// Reverts to the previous state prior to the last committed gesture.
    public mutating func undo(currentState: PuzzleState) -> PuzzleState? {
        guard let previous = undoStack.popLast() else { return nil }
        redoStack.append(currentState)
        return previous
    }

    /// Reapplies a previously undone state.
    public mutating func redo(currentState: PuzzleState) -> PuzzleState? {
        guard let next = redoStack.popLast() else { return nil }
        undoStack.append(currentState)
        return next
    }

    /// Clears all undo and redo history.
    public mutating func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
        transactionSnapshot = nil
    }
}
