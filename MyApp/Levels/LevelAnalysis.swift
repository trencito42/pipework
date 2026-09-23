import Foundation

public enum DifficultyTier: String, Codable, Sendable, CaseIterable {
    case calibration
    case standard
    case advanced
    case expert
}

public struct DifficultyReport: Sendable, Equatable {
    public let score: Double
    public let tier: DifficultyTier
    public let solverNodes: Int
    public let branchingScore: Double
    public let congestionScore: Double
    public let ambiguityScore: Double
    public let topologyScore: Double
}

public enum LevelTopology {
    public static func d4CanonicalHash(for level: LevelDefinition) -> String {
        let variants = (0..<8).map { transform in
            level.pairs.map { pair -> String in
                let endpoints = [
                    transformed(pair.terminalA, size: level.size, transform: transform),
                    transformed(pair.terminalB, size: level.size, transform: transform)
                ].sorted()
                return "\(endpoints[0].x),\(endpoints[0].y)-\(endpoints[1].x),\(endpoints[1].y)"
            }
            .sorted()
            .joined(separator: "|")
        }
        return "\(level.size):\(variants.min() ?? "")"
    }

    private static func transformed(_ point: GridCoord, size: Int, transform: Int) -> GridCoord {
        let m = size - 1
        switch transform {
        case 0: return point
        case 1: return GridCoord(x: m - point.y, y: point.x)
        case 2: return GridCoord(x: m - point.x, y: m - point.y)
        case 3: return GridCoord(x: point.y, y: m - point.x)
        case 4: return GridCoord(x: m - point.x, y: point.y)
        case 5: return GridCoord(x: point.x, y: m - point.y)
        case 6: return GridCoord(x: point.y, y: point.x)
        default: return GridCoord(x: m - point.y, y: m - point.x)
        }
    }
}

public enum DifficultyAnalyzer {
    public static func analyze(_ level: LevelDefinition) -> DifficultyReport {
        let solve = PuzzleSolver(gridSize: GridSize(dimension: level.size), pairs: level.pairs)
            .solveFullBoard(maxSolutions: 2)
        let quality = LevelQualityScorer.evaluate(level)
        let distances = level.pairs.map { Double($0.terminalA.manhattanDistance(to: $0.terminalB)) }
        let averageDistance = distances.reduce(0, +) / Double(max(1, distances.count))
        let interiorRatio = Double(quality.internalEndpointsCount) / Double(max(1, level.pairs.count * 2))
        let solverScore = min(1, log10(Double(max(1, solve.exploredNodes))) / 4.7)
        let branching = min(1, solverScore * 0.75 + quality.pathLengthVariance.squareRoot() / 12)
        let congestion = min(1, interiorRatio * 0.55 + Double(level.pairs.count) / Double(max(1, level.size)) * 0.3)
        let ambiguity = min(1, averageDistance / Double(max(1, level.size * 2)) + branching * 0.45)
        let topology = min(1, quality.score * 0.7 + Double(quality.totalTurns) / Double(max(1, level.size * level.size)) * 0.3)
        let score = 100 * (solverScore * 0.42 + branching * 0.2 + congestion * 0.14 + ambiguity * 0.12 + topology * 0.12)
        let tier: DifficultyTier
        switch score {
        case ..<25: tier = .calibration
        case ..<48: tier = .standard
        case ..<72: tier = .advanced
        default: tier = .expert
        }
        return DifficultyReport(score: score, tier: tier, solverNodes: solve.exploredNodes, branchingScore: branching, congestionScore: congestion, ambiguityScore: ambiguity, topologyScore: topology)
    }
}

public struct ContentAuditRecord: Sendable {
    public let levelId: String
    public let gridSize: Int
    public let pairCount: Int
    public let par: Int
    public let d4Hash: String
    public let difficulty: DifficultyReport
    public let quality: LevelQualityScorer.QualityReport
}

public enum ContentAudit {
    public static func scan(_ packs: [LevelPack] = LevelRepository.allPacks) -> [ContentAuditRecord] {
        packs.flatMap(\.levels).map { level in
            ContentAuditRecord(levelId: level.id, gridSize: level.size, pairCount: level.pairs.count, par: level.parMoves, d4Hash: LevelTopology.d4CanonicalHash(for: level), difficulty: DifficultyAnalyzer.analyze(level), quality: LevelQualityScorer.evaluate(level))
        }
    }

    public static func duplicateGroups(_ records: [ContentAuditRecord]) -> [[String]] {
        Dictionary(grouping: records, by: \.d4Hash).values
            .filter { $0.count > 1 }
            .map { $0.map(\.levelId).sorted() }
            .sorted { ($0.first ?? "") < ($1.first ?? "") }
    }
}
