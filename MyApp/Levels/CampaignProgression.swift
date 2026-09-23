import Foundation

public enum CampaignProgression {
    public struct Location: Sendable {
        public let pack: LevelPack
        public let level: LevelDefinition
        public let globalIndex: Int
    }

    public static var orderedLocations: [Location] {
        var index = 0
        return LevelRepository.allPacks.sorted { $0.order < $1.order }.flatMap { pack in
            pack.levels.sorted { $0.number < $1.number }.map { level in
                defer { index += 1 }
                return Location(pack: pack, level: level, globalIndex: index)
            }
        }
    }

    public static func index(of levelId: String) -> Int {
        orderedLocations.first(where: { $0.level.id == levelId })?.globalIndex ?? 0
    }

    public static func location(for levelId: String) -> Location? {
        orderedLocations.first { $0.level.id == levelId }
    }

    public static func continueLocation(profile: PlayerProfile) -> Location? {
        let locations = orderedLocations
        if let lastId = profile.lastPlayedLevelId,
           let last = locations.first(where: { $0.level.id == lastId }),
           !profile.completedLevelIds.contains(lastId) {
            return last
        }
        if let firstIncomplete = locations.first(where: {
            $0.globalIndex <= profile.highestUnlockedLevelIndex && !profile.completedLevelIds.contains($0.level.id)
        }) {
            return firstIncomplete
        }
        if let lastId = profile.lastPlayedLevelId,
           let last = locations.first(where: { $0.level.id == lastId }) {
            return last
        }
        return locations.first
    }

    public static func chapterNumber(for level: LevelDefinition, chapterSize: Int = 10) -> Int {
        max(1, ((level.number - 1) / chapterSize) + 1)
    }
}
