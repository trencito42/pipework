import Foundation

/// Validates mathematical integrity, uniqueness, coverage constraints, and design quality of PIPEWORK level definitions.
public enum LevelValidator {

    public struct ValidationReport: Sendable, CustomStringConvertible {
        public let levelId: String
        public let coveredCellCount: Int
        public let totalCellCount: Int
        public let fullBoardSolutionCount: Int
        public let hasPrematureRouting: Bool
        public let prematureCoverageCount: Int?
        public let isUniqueFullBoard: Bool
        public let qualityScore: Double
        public let isAccepted: Bool
        public let rejectionReason: String?

        public var description: String {
            let lines = [
                "Level: \(levelId)",
                "Canonical coverage: \(coveredCellCount)/\(totalCellCount)",
                "Full-board solutions found: \(fullBoardSolutionCount)",
                "Premature complete routing found: \(hasPrematureRouting ? "YES (coverage: \(prematureCoverageCount ?? 0)/\(totalCellCount))" : "NO")",
                "Unique full-board solution: \(isUniqueFullBoard ? "YES" : "NO")",
                String(format: "Quality score: %.2f", qualityScore),
                isAccepted ? "ACCEPTED" : "REJECTED: \(rejectionReason ?? "Unknown")"
            ]
            return lines.joined(separator: "\n")
        }
    }

    public enum ValidationError: Error, CustomStringConvertible {
        case emptyPairs
        case outOfBounds(GridCoord)
        case duplicateTerminal(GridCoord)
        case missingCanonicalSolution
        case pathDiscontinuous(String)
        case pathSelfIntersects(String)
        case pathsOverlap(GridCoord)
        case endpointsMismatch(String)
        case incompleteBoardCoverage(covered: Int, total: Int)
        case noFullBoardSolution
        case notUniquelySolvable(solutions: Int)
        case prematureCompleteRoutingExists(covered: Int, total: Int)
        case qualityFilterFailed(reasons: [String])

        public var description: String {
            switch self {
            case .emptyPairs:
                return "Level contains no terminal pairs."
            case .outOfBounds(let coord):
                return "Coordinate \(coord) is outside grid bounds."
            case .duplicateTerminal(let coord):
                return "Multiple terminals share coordinate \(coord)."
            case .missingCanonicalSolution:
                return "Level lacks a canonical solution."
            case .pathDiscontinuous(let line):
                return "Canonical path for '\(line)' contains non-adjacent steps."
            case .pathSelfIntersects(let line):
                return "Canonical path for '\(line)' self-intersects."
            case .pathsOverlap(let coord):
                return "Multiple canonical paths overlap at \(coord)."
            case .endpointsMismatch(let line):
                return "Canonical path endpoints do not match defined pair terminals for '\(line)'."
            case .incompleteBoardCoverage(let covered, let total):
                return "Canonical solution covers \(covered)/\(total) cells. 100% full-board coverage required."
            case .noFullBoardSolution:
                return "No 100% full-board coverage solution exists for this endpoint layout."
            case .notUniquelySolvable(let count):
                return "Level has \(count) full-board solutions. Exactly 1 unique solution required."
            case .prematureCompleteRoutingExists(let covered, let total):
                return "Level allows all pairs to connect with only \(covered)/\(total) cells. allPairsConnected => fullBoardCoverage violated."
            case .qualityFilterFailed(let reasons):
                return "Level failed quality filter: \(reasons.joined(separator: "; "))"
            }
        }
    }

    /// Performs strict validation on a level definition and returns a comprehensive validation report.
    @discardableResult
    public static func validate(
        _ level: LevelDefinition,
        enforceUniqueSolution: Bool = true,
        enforceNoPrematureRouting: Bool = true,
        enforceQualityFilter: Bool = false
    ) throws -> ValidationReport {
        let gridSize = GridSize(dimension: level.size)
        guard !level.pairs.isEmpty else {
            throw ValidationError.emptyPairs
        }

        var terminalLocations = Set<GridCoord>()
        for pair in level.pairs {
            guard gridSize.contains(pair.terminalA) else { throw ValidationError.outOfBounds(pair.terminalA) }
            guard gridSize.contains(pair.terminalB) else { throw ValidationError.outOfBounds(pair.terminalB) }

            if !terminalLocations.insert(pair.terminalA).inserted {
                throw ValidationError.duplicateTerminal(pair.terminalA)
            }
            if !terminalLocations.insert(pair.terminalB).inserted {
                throw ValidationError.duplicateTerminal(pair.terminalB)
            }
        }

        guard let canonical = level.canonicalSolution, !canonical.isEmpty else {
            throw ValidationError.missingCanonicalSolution
        }

        var occupiedCells = Set<GridCoord>()
        let pairMap = Dictionary(uniqueKeysWithValues: level.pairs.map { ($0.id, $0) })

        for pathDef in canonical {
            let coords = pathDef.path
            guard let pair = pairMap[pathDef.lineId] else {
                throw ValidationError.endpointsMismatch(pathDef.lineId)
            }

            guard coords.count >= 2 else {
                throw ValidationError.pathDiscontinuous(pathDef.lineId)
            }

            let start = coords.first!
            let end = coords.last!
            let validEndpoints = (start == pair.terminalA && end == pair.terminalB) || (start == pair.terminalB && end == pair.terminalA)
            guard validEndpoints else {
                throw ValidationError.endpointsMismatch(pathDef.lineId)
            }

            var visitedInPath = Set<GridCoord>()
            for i in 0..<coords.count {
                let current = coords[i]
                guard gridSize.contains(current) else {
                    throw ValidationError.outOfBounds(current)
                }

                if !visitedInPath.insert(current).inserted {
                    throw ValidationError.pathSelfIntersects(pathDef.lineId)
                }

                if i > 0 {
                    let prev = coords[i - 1]
                    guard prev.isAdjacent(to: current) else {
                        throw ValidationError.pathDiscontinuous(pathDef.lineId)
                    }
                }

                if !occupiedCells.insert(current).inserted {
                    throw ValidationError.pathsOverlap(current)
                }
            }
        }

        // 1. Check full 100% canonical board coverage
        if occupiedCells.count != gridSize.totalCells {
            throw ValidationError.incompleteBoardCoverage(
                covered: occupiedCells.count,
                total: gridSize.totalCells
            )
        }

        // 2. Full board solver check (Solver A)
        let solver = PuzzleSolver(gridSize: gridSize, pairs: level.pairs)
        let fullBoardResult = solver.solveFullBoard(maxSolutions: 2)

        guard fullBoardResult.isSolvable else {
            throw ValidationError.noFullBoardSolution
        }

        if enforceUniqueSolution && fullBoardResult.solutionCount != 1 {
            throw ValidationError.notUniquelySolvable(solutions: fullBoardResult.solutionCount)
        }

        // 3. Premature completion check (Solver B)
        let prematureResult = solver.findPrematureSolution()
        if enforceNoPrematureRouting, let premature = prematureResult {
            throw ValidationError.prematureCompleteRoutingExists(
                covered: premature.coveredCellCount,
                total: gridSize.totalCells
            )
        }

        // 4. Quality filter check
        let qualityReport = LevelQualityScorer.evaluate(level)
        if enforceQualityFilter && !qualityReport.passesQualityFilter {
            throw ValidationError.qualityFilterFailed(reasons: qualityReport.rejectionReasons)
        }

        return ValidationReport(
            levelId: level.id,
            coveredCellCount: occupiedCells.count,
            totalCellCount: gridSize.totalCells,
            fullBoardSolutionCount: fullBoardResult.solutionCount,
            hasPrematureRouting: prematureResult != nil,
            prematureCoverageCount: prematureResult?.coveredCellCount,
            isUniqueFullBoard: fullBoardResult.solutionCount == 1,
            qualityScore: qualityReport.score,
            isAccepted: true,
            rejectionReason: nil
        )
    }
}
