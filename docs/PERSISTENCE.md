# PIPEWORK — Persistence & State Storage Specification

## 1. Storage Strategy
PIPEWORK stores player progression, game settings, and diagnostic statistics locally via structured JSON files in the user's `Application Support` directory, backed with atomic file writes and schema versioning.

---

## 2. Data Schema & Models

```swift
public struct PlayerProfile: Codable, Sendable {
    public var version: Int = 1
    public var completedLevels: [String: LevelProgressRecord] // levelId -> progress
    public var unlockedPacks: Set<String>
    public var dailyRecords: [String: DailyRecord]           // YYYY-MM-DD -> record
    public var dailyStreak: Int
    public var bestDailyStreak: Int
    public var lastCompletedDailyDate: String?
    public var settings: GameSettings
    public var statistics: PlayerStatistics
}

public struct LevelProgressRecord: Codable, Sendable {
    public let levelId: String
    public var completed: Bool
    public var bestMoves: Int
    public var bestTimeSeconds: Double
    public var hintsUsed: Int
    public var firstCompletedAt: Date
    public var lastCompletedAt: Date
}

public struct GameSettings: Codable, Sendable {
    public var hapticsEnabled: Bool = true
    public var soundEnabled: Bool = true
    public var colorLabelsEnabled: Bool = false
    public var reduceMotionOverride: Bool = false
    public var soundVolume: Double = 0.8
}
```

---

## 3. Schema Migration
- Current version: `2`.
- Migrations check `version` on load and apply linear transform steps (`migrateFrom1To2()`, etc.) before persisting back to disk.
- Atomic writes via `Data.write(to:options: .atomic)`.

Version 2 adds `lastPlayedLevelId`, `highestUnlockedLevelIndex`, and assisted-best metadata. Decoding uses explicit defaults so version-1 saves remain valid. Continue prioritizes an unfinished last-played level, then the first incomplete unlocked level, then the most recently played level.
