import Foundation

/// Validates mathematical integrity and solution-first rules of PIPEWORK puzzle definitions.
public enum LevelValidator {

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
        case notUniquelySolvable(solutions: Int)

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
            case .notUniquelySolvable(let count):
                return "Level has \(count) solutions. Exactly 1 unique solution required."
            }
        }
    }

    /// Performs strict validation on a level definition.
    public static func validate(
        _ level: LevelDefinition,
        enforceUniqueSolution: Bool = false
    ) throws {
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

            // Check endpoints match
            let start = coords.first!
            let end = coords.last!
            let validEndpoints = (start == pair.terminalA && end == pair.terminalB) || (start == pair.terminalB && end == pair.terminalA)
            guard validEndpoints else {
                throw ValidationError.endpointsMismatch(pathDef.lineId)
            }

            // Check continuity and self-intersection
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

        // Check full 100% board coverage
        if occupiedCells.count != gridSize.totalCells {
            throw ValidationError.incompleteBoardCoverage(
                covered: occupiedCells.count,
                total: gridSize.totalCells
            )
        }

        // Check CSP uniqueness if requested
        if enforceUniqueSolution {
            let solver = PuzzleSolver(gridSize: gridSize, pairs: level.pairs)
            let result = solver.solve(maxSolutions: 2)
            if !result.isSolvable || result.solutionCount != 1 {
                throw ValidationError.notUniquelySolvable(solutions: result.solutionCount)
            }
        }
    }
}
