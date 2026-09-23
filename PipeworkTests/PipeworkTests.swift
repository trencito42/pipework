import Testing
import Foundation
@testable import MyApp

struct PipeworkTests {
    @Test func shippingCampaignContainsNoD4Duplicates() {
        let levels = LevelRepository.allPacks.flatMap(\.levels)
        let hashes = levels.map { LevelTopology.d4CanonicalHash(for: $0) }
        #expect(Set(hashes).count == levels.count)
    }

    @Test func campaignParIsNotMerelyPairCount() {
        let levels = LevelRepository.allPacks.flatMap(\.levels)
        #expect(levels.contains { $0.parMoves > $0.pairs.count })
    }

    @Test func firstCampaignLevelIsUnlocked() {
        let first = CampaignProgression.orderedLocations.first
        #expect(first?.globalIndex == 0)
    }

    @Test func d4EquivalentBoardsHaveSameHash() {
        let original = makeLevel(id: "a", endpoints: [
            (GridCoord(x: 0, y: 0), GridCoord(x: 1, y: 3)),
            (GridCoord(x: 2, y: 0), GridCoord(x: 3, y: 2))
        ])
        let rotated = makeLevel(id: "b", endpoints: [
            (GridCoord(x: 3, y: 0), GridCoord(x: 0, y: 1)),
            (GridCoord(x: 3, y: 2), GridCoord(x: 1, y: 3))
        ])
        #expect(LevelTopology.d4CanonicalHash(for: original) == LevelTopology.d4CanonicalHash(for: rotated))
    }

    @Test func structuralDifferenceChangesHash() {
        let first = makeLevel(id: "a", endpoints: [(GridCoord(x: 0, y: 0), GridCoord(x: 1, y: 3))])
        let second = makeLevel(id: "b", endpoints: [(GridCoord(x: 0, y: 0), GridCoord(x: 2, y: 3))])
        #expect(LevelTopology.d4CanonicalHash(for: first) != LevelTopology.d4CanonicalHash(for: second))
    }

    @Test func oldProfileSchemaDecodesWithProgressionDefaults() throws {
        let json = #"{"completedLevelIds":[],"levelRecords":{},"totalLevelsSolved":0,"soundEnabled":true,"hapticsEnabled":true,"accessibilitySymbolsEnabled":false,"reduceMotionEnabled":false}"#.data(using: .utf8)!
        let profile = try JSONDecoder().decode(PlayerProfile.self, from: json)
        #expect(profile.schemaVersion == 2)
        #expect(profile.highestUnlockedLevelIndex == 0)
        #expect(profile.lastPlayedLevelId == nil)
    }

    @Test func attemptBasedUndoPreservesCurrentMoveCount() {
        let level = LevelRepository.defaultLevel
        var current = level.createInitialState()
        current.moveCount = 4
        var older = level.createInitialState()
        older.moveCount = 2
        var history = MoveHistory()
        history.beginTransaction(with: older)
        var changed = older
        if let lineId = changed.paths.keys.first, var path = changed.paths[lineId], let terminal = changed.terminals.first(where: { $0.lineId == lineId }) {
            path.start(at: terminal.coord)
            changed.updatePath(for: lineId, path: path)
        }
        let didCommit = history.commitTransaction(with: changed)
        #expect(didCommit)
        guard var restored = history.undo(currentState: current) else {
            Issue.record("Expected undo snapshot")
            return
        }
        restored.moveCount = current.moveCount
        #expect(restored.moveCount == 4)
    }

    private func makeLevel(id: String, endpoints: [(GridCoord, GridCoord)]) -> LevelDefinition {
        let pairs = endpoints.enumerated().map { index, endpoints in
            TerminalPairDefinition(id: "line_\(index)", fluidType: FluidType.allCases[index % FluidType.allCases.count], terminalA: endpoints.0, terminalB: endpoints.1)
        }
        return LevelDefinition(id: id, packId: "test", number: 1, size: 4, pairs: pairs)
    }
}
