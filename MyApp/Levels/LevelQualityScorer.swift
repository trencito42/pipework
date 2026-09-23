import Foundation

/// Evaluates the visual, topological, and structural design quality of a PIPEWORK level.
/// Rejects trivial, boring, or stripe-heavy layouts in favor of interlocking paths and meaningful bottlenecks.
public enum LevelQualityScorer {

    public struct QualityReport: Sendable {
        public let score: Double
        public let totalTurns: Int
        public let averagePathLength: Double
        public let pathLengthVariance: Double
        public let internalEndpointsCount: Int
        public let isStripeHeavy: Bool
        public let hasTrivialAdjacentPairs: Bool
        public let passesQualityFilter: Bool
        public let rejectionReasons: [String]
    }

    /// Evaluates the quality of a level definition and its canonical paths.
    public static func evaluate(_ level: LevelDefinition) -> QualityReport {
        guard let canonical = level.canonicalSolution, !canonical.isEmpty else {
            return QualityReport(
                score: 0.0,
                totalTurns: 0,
                averagePathLength: 0.0,
                pathLengthVariance: 0.0,
                internalEndpointsCount: 0,
                isStripeHeavy: true,
                hasTrivialAdjacentPairs: true,
                passesQualityFilter: false,
                rejectionReasons: ["Missing canonical solution"]
            )
        }

        let gridSize = GridSize(dimension: level.size)
        var totalTurns = 0
        var pathLengths: [Double] = []
        var straightSegmentsCount = 0
        var totalSegmentsCount = 0

        for pathDef in canonical {
            let coords = pathDef.path
            pathLengths.append(Double(coords.count))

            var turnsInPath = 0
            if coords.count >= 3 {
                for i in 1..<(coords.count - 1) {
                    let prev = coords[i - 1]
                    let curr = coords[i]
                    let next = coords[i + 1]

                    let dir1 = prev.direction(to: curr)
                    let dir2 = curr.direction(to: next)

                    totalSegmentsCount += 1
                    if dir1 != dir2 {
                        turnsInPath += 1
                    } else {
                        straightSegmentsCount += 1
                    }
                }
            }
            totalTurns += turnsInPath
        }

        let avgLength = pathLengths.reduce(0.0, +) / Double(pathLengths.count)
        let variance = pathLengths.map { pow($0 - avgLength, 2) }.reduce(0.0, +) / Double(pathLengths.count)

        // Internal endpoints (not on the border perimeter)
        var internalEndpoints = 0
        for pair in level.pairs {
            if !isBorderCoord(pair.terminalA, in: gridSize) { internalEndpoints += 1 }
            if !isBorderCoord(pair.terminalB, in: gridSize) { internalEndpoints += 1 }
        }

        // Trivial adjacent endpoints check (length 2 straight path along border)
        var trivialAdjacentCount = 0
        for pathDef in canonical {
            if pathDef.path.count == 2 {
                let p0 = pathDef.path[0]
                let p1 = pathDef.path[1]
                if isBorderCoord(p0, in: gridSize) && isBorderCoord(p1, in: gridSize) {
                    trivialAdjacentCount += 1
                }
            }
        }

        // Stripe-heavy layout detection (too many straight parallel lines)
        let straightRatio = totalSegmentsCount > 0 ? Double(straightSegmentsCount) / Double(totalSegmentsCount) : 0.0
        let isStripeHeavy = straightRatio > 0.85 && totalTurns < level.pairs.count

        // Base score calculation (0.0 to 1.0)
        var score: Double = 0.50

        // Bonus for turns (interlocking paths)
        let turnsPerPair = Double(totalTurns) / Double(max(1, level.pairs.count))
        score += min(0.25, turnsPerPair * 0.08)

        // Bonus for path length variance
        score += min(0.15, sqrt(variance) * 0.04)

        // Bonus for internal endpoints (forces paths into center)
        let internalRatio = Double(internalEndpoints) / Double(max(1, level.pairs.count * 2))
        score += min(0.15, internalRatio * 0.20)

        // Penalties
        var reasons: [String] = []
        if isStripeHeavy {
            score -= 0.35
            reasons.append("Layout is stripe-heavy with excessive straight parallel paths.")
        }

        if trivialAdjacentCount > (level.pairs.count / 2) {
            score -= 0.20
            reasons.append("Too many trivial adjacent endpoint pairs.")
        }

        if totalTurns < max(2, level.pairs.count - 1) {
            score -= 0.25
            reasons.append("Insufficient path turns / interlocking complexity.")
        }

        let clampedScore = max(0.0, min(1.0, score))
        let passes = clampedScore >= 0.55 && !isStripeHeavy && reasons.isEmpty

        return QualityReport(
            score: clampedScore,
            totalTurns: totalTurns,
            averagePathLength: avgLength,
            pathLengthVariance: variance,
            internalEndpointsCount: internalEndpoints,
            isStripeHeavy: isStripeHeavy,
            hasTrivialAdjacentPairs: trivialAdjacentCount > 0,
            passesQualityFilter: passes,
            rejectionReasons: reasons
        )
    }

    private static func isBorderCoord(_ coord: GridCoord, in gridSize: GridSize) -> Bool {
        coord.x == 0 || coord.y == 0 || coord.x == gridSize.width - 1 || coord.y == gridSize.height - 1
    }
}
