import Foundation
import Combine

/// Records completion state and metrics for a single level.
public struct LevelProgress: Codable, Sendable, Equatable {
    public let levelId: String
    public var isCompleted: Bool
    public var bestMoves: Int?
    public var parMoves: Int
    public var starsEarned: Int
    public var completedAt: Date?

    public init(
        levelId: String,
        isCompleted: Bool = false,
        bestMoves: Int? = nil,
        parMoves: Int = 0,
        starsEarned: Int = 0,
        completedAt: Date? = nil
    ) {
        self.levelId = levelId
        self.isCompleted = isCompleted
        self.bestMoves = bestMoves
        self.parMoves = parMoves
        self.starsEarned = starsEarned
        self.completedAt = completedAt
    }
}

/// Global player profile data.
public struct PlayerProfile: Codable, Sendable {
    public var completedLevelIds: Set<String>
    public var levelRecords: [String: LevelProgress]
    public var totalLevelsSolved: Int
    public var soundEnabled: Bool
    public var hapticsEnabled: Bool
    public var accessibilitySymbolsEnabled: Bool
    public var reduceMotionEnabled: Bool

    public static let initial = PlayerProfile(
        completedLevelIds: [],
        levelRecords: [:],
        totalLevelsSolved: 0,
        soundEnabled: true,
        hapticsEnabled: true,
        accessibilitySymbolsEnabled: false,
        reduceMotionEnabled: false
    )
}

/// Manages atomic JSON saving and loading of game progression.
@MainActor
public final class PersistenceService: ObservableObject {
    public static let shared = PersistenceService()

    @Published public private(set) var profile: PlayerProfile

    private let saveKey = "com.blipmade.pipework.saveData"
    private let fileURL: URL

    private init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.fileURL = paths[0].appendingPathComponent("pipework_save.json")
        let loadedProfile = Self.load(from: fileURL, saveKey: saveKey)
        self.profile = loadedProfile

        // Immediately propagate loaded settings to hardware services
        AudioService.shared.isEnabled = loadedProfile.soundEnabled
        HapticService.shared.isEnabled = loadedProfile.hapticsEnabled
    }

    private static func load(from url: URL, saveKey: String) -> PlayerProfile {
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            return decoded
        }
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            return decoded
        }
        return .initial
    }

    public func save() {
        if let encoded = try? JSONEncoder().encode(profile) {
            try? encoded.write(to: fileURL, options: .atomic)
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    public func recordLevelCompletion(levelId: String, moves: Int, parMoves: Int) {
        var record = profile.levelRecords[levelId] ?? LevelProgress(levelId: levelId, parMoves: parMoves)
        record.isCompleted = true
        record.completedAt = Date()

        if let previousBest = record.bestMoves {
            record.bestMoves = min(previousBest, moves)
        } else {
            record.bestMoves = moves
        }

        let stars: Int
        if moves <= parMoves {
            stars = 3
        } else if moves <= parMoves + 2 {
            stars = 2
        } else {
            stars = 1
        }
        record.starsEarned = max(record.starsEarned, stars)

        profile.levelRecords[levelId] = record
        if !profile.completedLevelIds.contains(levelId) {
            profile.completedLevelIds.insert(levelId)
            profile.totalLevelsSolved += 1
        }

        save()
    }

    public func isLevelCompleted(_ levelId: String) -> Bool {
        profile.completedLevelIds.contains(levelId)
    }

    public func getRecord(for levelId: String) -> LevelProgress? {
        profile.levelRecords[levelId]
    }

    public func updateSettings(
        sound: Bool? = nil,
        haptics: Bool? = nil,
        accessibility: Bool? = nil,
        reduceMotion: Bool? = nil
    ) {
        if let s = sound {
            profile.soundEnabled = s
            AudioService.shared.isEnabled = s
        }
        if let h = haptics {
            profile.hapticsEnabled = h
            HapticService.shared.isEnabled = h
        }
        if let a = accessibility {
            profile.accessibilitySymbolsEnabled = a
        }
        if let r = reduceMotion {
            profile.reduceMotionEnabled = r
        }
        save()
    }

    public func resetProgress() {
        profile = .initial
        AudioService.shared.isEnabled = profile.soundEnabled
        HapticService.shared.isEnabled = profile.hapticsEnabled
        save()
    }
}
