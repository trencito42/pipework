import Foundation

/// Represents a collection of levels grouped by sector or difficulty.
public struct LevelPack: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let gridSize: Int
    public let order: Int
    public let levels: [LevelDefinition]

    public init(
        id: String,
        name: String,
        subtitle: String,
        gridSize: Int,
        order: Int,
        levels: [LevelDefinition]
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.gridSize = gridSize
        self.order = order
        self.levels = levels
    }
}
