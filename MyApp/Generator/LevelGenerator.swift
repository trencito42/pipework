import Foundation

/// Solution-first puzzle generator creating validated, 100% full-board coverage, uniquely solvable puzzles
/// with certified immunity to premature partial-coverage routing.
public enum LevelGenerator {

    /// Generates a certified production-ready level satisfying:
    /// 1. 100% Canonical full-board coverage
    /// 2. Exactly 1 unique full-board solution (Solver A)
    /// 3. Zero premature complete routings (Solver B)
    /// 4. High topological quality score
    public static func generateLevel(
        size: Int,
        pairCount: Int,
        packId: String = "curated",
        levelNumber: Int = 1,
        maxAttempts: Int = 200
    ) -> LevelDefinition {
        let gridSize = GridSize(dimension: size)
        let fluids: [FluidType] = [.coolant, .fuel, .chemical, .pressure, .thermal, .auxiliary, .plasma]

        for _ in 0..<maxAttempts {
            if let candidate = attemptGenerate(gridSize: gridSize, pairCount: pairCount, fluids: fluids, packId: packId, levelNumber: levelNumber) {
                // Strict validation through LevelValidator
                do {
                    try LevelValidator.validate(
                        candidate,
                        enforceUniqueSolution: true,
                        enforceNoPrematureRouting: true,
                        enforceQualityFilter: true
                    )
                    return candidate
                } catch {
                    // Candidate failed one of the strict tests, continue searching
                    continue
                }
            }
        }

        // Fallback to default certified level if random attempt limit reached
        return LevelRepository.defaultLevel
    }

    private static func attemptGenerate(
        gridSize: GridSize,
        pairCount: Int,
        fluids: [FluidType],
        packId: String,
        levelNumber: Int
    ) -> LevelDefinition? {
        var occupancy: [[Int?]] = Array(repeating: Array(repeating: nil, count: gridSize.height), count: gridSize.width)
        var paths: [[GridCoord]] = []

        // 1. Seed initial start points
        var availableCoords: [GridCoord] = []
        for x in 0..<gridSize.width {
            for y in 0..<gridSize.height {
                availableCoords.append(GridCoord(x: x, y: y))
            }
        }
        availableCoords.shuffle()

        guard availableCoords.count >= pairCount else { return nil }

        for p in 0..<pairCount {
            let seed = availableCoords[p]
            occupancy[seed.x][seed.y] = p
            paths.append([seed])
        }

        // 2. Grow paths to cover all cells (Randomized Snake & Expansion)
        var unassignedCount = gridSize.totalCells - pairCount
        var growthStuck = 0

        while unassignedCount > 0 && growthStuck < 200 {
            var grownAny = false
            for p in 0..<pairCount {
                let head = paths[p].last!
                let emptyNeighbors = head.orthogonalNeighbors(in: gridSize).filter { occupancy[$0.x][$0.y] == nil }

                if let next = emptyNeighbors.randomElement() {
                    occupancy[next.x][next.y] = p
                    paths[p].append(next)
                    unassignedCount -= 1
                    grownAny = true
                }
            }

            if !grownAny {
                growthStuck += 1
            }
        }

        guard unassignedCount == 0 else { return nil }

        // 3. Ensure all paths have at least 3 cells for good quality
        for path in paths {
            if path.count < 3 { return nil }
        }

        // 4. Construct pairs and canonical paths
        var pairs: [TerminalPairDefinition] = []
        var canonicalSolution: [CanonicalPathDefinition] = []

        for p in 0..<pairCount {
            let path = paths[p]
            let fluid = fluids[p % fluids.count]
            let lineId = fluid.rawValue
            let start = path.first!
            let end = path.last!

            pairs.append(
                TerminalPairDefinition(
                    id: lineId,
                    fluidType: fluid,
                    terminalA: start,
                    terminalB: end
                )
            )

            canonicalSolution.append(
                CanonicalPathDefinition(
                    lineId: lineId,
                    path: path
                )
            )
        }

        let report = LevelQualityScorer.evaluate(
            LevelDefinition(
                id: "\(packId)-\(levelNumber)",
                packId: packId,
                number: levelNumber,
                size: gridSize.width,
                pairs: pairs,
                canonicalSolution: canonicalSolution,
                parMoves: pairCount,
                difficultyScore: Double(pairCount) * 0.8,
                signature: "candidate"
            )
        )

        return LevelDefinition(
            id: "\(packId)-\(levelNumber)",
            packId: packId,
            number: levelNumber,
            size: gridSize.width,
            pairs: pairs,
            canonicalSolution: canonicalSolution,
            parMoves: pairCount,
            difficultyScore: report.score * 5.0,
            signature: "gen_\(gridSize.width)x\(gridSize.height)_\(levelNumber)"
        )
    }
}
