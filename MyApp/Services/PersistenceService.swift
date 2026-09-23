import Foundation
import SwiftUI
import Combine

public struct CompletionOutcome: Sendable, Equatable {
    public let previousBest: Int?
    public let bestMoves: Int
    public let stars: Int
    public let isNewBest: Bool
    public let isFirstCompletion: Bool
    public let isAssisted: Bool
    public let isPerfect: Bool
}

/// Records completion state and metrics for a single level.
public struct LevelProgress: Codable, Sendable, Equatable {
    public let levelId: String
    public var isCompleted: Bool
    public var bestMoves: Int?
    public var parMoves: Int
    public var starsEarned: Int
    public var bestWasAssisted: Bool
    public var completedAt: Date?

    public init(
        levelId: String,
        isCompleted: Bool = false,
        bestMoves: Int? = nil,
        parMoves: Int = 0,
        starsEarned: Int = 0,
        completedAt: Date? = nil,
        bestWasAssisted: Bool = false
    ) {
        self.levelId = levelId
        self.isCompleted = isCompleted
        self.bestMoves = bestMoves
        self.parMoves = parMoves
        self.starsEarned = starsEarned
        self.completedAt = completedAt
        self.bestWasAssisted = bestWasAssisted
    }

    private enum CodingKeys: String, CodingKey {
        case levelId, isCompleted, bestMoves, parMoves, starsEarned, completedAt, bestWasAssisted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        levelId = try container.decode(String.self, forKey: .levelId)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        bestMoves = try container.decodeIfPresent(Int.self, forKey: .bestMoves)
        parMoves = try container.decodeIfPresent(Int.self, forKey: .parMoves) ?? 0
        starsEarned = try container.decodeIfPresent(Int.self, forKey: .starsEarned) ?? 0
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        bestWasAssisted = try container.decodeIfPresent(Bool.self, forKey: .bestWasAssisted) ?? false
    }
}

/// Global player profile data.
public struct PlayerProfile: Codable, Sendable {
    public var schemaVersion: Int
    public var completedLevelIds: Set<String>
    public var levelRecords: [String: LevelProgress]
    public var totalLevelsSolved: Int
    public var soundEnabled: Bool
    public var hapticsEnabled: Bool
    public var accessibilitySymbolsEnabled: Bool
    public var reduceMotionEnabled: Bool
    public var lastPlayedLevelId: String?
    public var highestUnlockedLevelIndex: Int

    public var totalStarsEarned: Int {
        levelRecords.values.reduce(0) { $0 + $1.starsEarned }
    }

    public static let initial = PlayerProfile(
        schemaVersion: 2,
        completedLevelIds: [],
        levelRecords: [:],
        totalLevelsSolved: 0,
        soundEnabled: true,
        hapticsEnabled: true,
        accessibilitySymbolsEnabled: false,
        reduceMotionEnabled: false,
        lastPlayedLevelId: nil,
        highestUnlockedLevelIndex: 0
    )

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, completedLevelIds, levelRecords, totalLevelsSolved
        case soundEnabled, hapticsEnabled, accessibilitySymbolsEnabled, reduceMotionEnabled
        case lastPlayedLevelId, highestUnlockedLevelIndex
    }

    public init(
        schemaVersion: Int,
        completedLevelIds: Set<String>,
        levelRecords: [String: LevelProgress],
        totalLevelsSolved: Int,
        soundEnabled: Bool,
        hapticsEnabled: Bool,
        accessibilitySymbolsEnabled: Bool,
        reduceMotionEnabled: Bool,
        lastPlayedLevelId: String?,
        highestUnlockedLevelIndex: Int
    ) {
        self.schemaVersion = schemaVersion
        self.completedLevelIds = completedLevelIds
        self.levelRecords = levelRecords
        self.totalLevelsSolved = totalLevelsSolved
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.accessibilitySymbolsEnabled = accessibilitySymbolsEnabled
        self.reduceMotionEnabled = reduceMotionEnabled
        self.lastPlayedLevelId = lastPlayedLevelId
        self.highestUnlockedLevelIndex = highestUnlockedLevelIndex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        completedLevelIds = try container.decodeIfPresent(Set<String>.self, forKey: .completedLevelIds) ?? []
        levelRecords = try container.decodeIfPresent([String: LevelProgress].self, forKey: .levelRecords) ?? [:]
        totalLevelsSolved = try container.decodeIfPresent(Int.self, forKey: .totalLevelsSolved) ?? completedLevelIds.count
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        accessibilitySymbolsEnabled = try container.decodeIfPresent(Bool.self, forKey: .accessibilitySymbolsEnabled) ?? false
        reduceMotionEnabled = try container.decodeIfPresent(Bool.self, forKey: .reduceMotionEnabled) ?? false
        lastPlayedLevelId = try container.decodeIfPresent(String.self, forKey: .lastPlayedLevelId)
        highestUnlockedLevelIndex = try container.decodeIfPresent(Int.self, forKey: .highestUnlockedLevelIndex) ?? completedLevelIds.count
        schemaVersion = 2
    }
}

/// Manages persistent storage of player progress, records, and preferences.
@MainActor
public final class PersistenceService: ObservableObject {
    public static let shared = PersistenceService()

    private let saveKey = "pipework_player_profile_v1"
    private let fileURL: URL

    @Published public private(set) var profile: PlayerProfile

    private init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.fileURL = paths[0].appendingPathComponent("pipework_save.json")
        let loadedProfile = Self.load(from: fileURL, saveKey: saveKey)
        self.profile = loadedProfile
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

    @discardableResult
    public func recordLevelCompletion(levelId: String, moves: Int, parMoves: Int, assisted: Bool) -> CompletionOutcome {
        var record = profile.levelRecords[levelId] ?? LevelProgress(levelId: levelId, parMoves: parMoves)
        let previousBest = record.bestMoves
        let isFirstCompletion = !record.isCompleted
        record.isCompleted = true
        record.completedAt = Date()

        if let previousBest = record.bestMoves {
            record.bestMoves = min(previousBest, moves)
        } else {
            record.bestMoves = moves
        }

        let stars: Int
        if moves <= parMoves && !assisted {
            stars = 3
        } else if moves <= parMoves + 2 || assisted {
            stars = 2
        } else {
            stars = 1
        }
        record.starsEarned = max(record.starsEarned, stars)
        if previousBest.map({ moves < $0 }) ?? true {
            record.bestWasAssisted = assisted
        }

        profile.levelRecords[levelId] = record
        if !profile.completedLevelIds.contains(levelId) {
            profile.completedLevelIds.insert(levelId)
            profile.totalLevelsSolved += 1
        }

        profile.lastPlayedLevelId = levelId
        profile.highestUnlockedLevelIndex = max(profile.highestUnlockedLevelIndex, CampaignProgression.index(of: levelId) + 1)

        save()
        let bestMoves = record.bestMoves ?? moves
        return CompletionOutcome(
            previousBest: previousBest,
            bestMoves: bestMoves,
            stars: stars,
            isNewBest: previousBest.map { moves < $0 } ?? false,
            isFirstCompletion: isFirstCompletion,
            isAssisted: assisted,
            isPerfect: !assisted && moves <= parMoves
        )
    }

    public func markLevelPlayed(_ levelId: String) {
        profile.lastPlayedLevelId = levelId
        save()
    }

    public func isLevelUnlocked(_ levelId: String) -> Bool {
        CampaignProgression.index(of: levelId) <= profile.highestUnlockedLevelIndex
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
        }
        if let h = haptics {
            profile.hapticsEnabled = h
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
        save()
    }
}
