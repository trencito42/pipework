import Foundation

/// Static repository of curated, certified, solution-first level packs.
/// Every shipped level is mathematically verified to satisfy:
/// 1. 100% full-board canonical coverage.
/// 2. Exactly one unique full-board solution.
/// 3. Zero premature complete routings (allPairsConnected => fullBoardCoverage).
/// 4. High topological turn count and quality score.
public enum LevelRepository {

    public static let allPacks: [LevelPack] = {
        if let url = Bundle.main.url(forResource: "LevelData", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let packs = try? JSONDecoder().decode([LevelPack].self, from: data) {
            return packs
        }

        // Fallback for previews or standalone test runners
        let devPath = "/Users/stefan/Library/Developer/Xcode/UntitledProjects/Untitled Project/MyApp/Levels/LevelData.json"
        if let devData = try? Data(contentsOf: URL(fileURLWithPath: devPath)),
           let devPacks = try? JSONDecoder().decode([LevelPack].self, from: devData) {
            return devPacks
        }

        // Hardcoded safe minimum backup
        return [fallback5x5Pack, fallback6x6Pack, fallback7x7Pack]
    }()

    public static var defaultLevel: LevelDefinition {
        allPacks.first?.levels.first ?? fallback5x5Pack.levels[0]
    }

    public static var sector5x5Pack: LevelPack {
        allPacks.first(where: { $0.gridSize == 5 }) ?? fallback5x5Pack
    }

    public static var sector6x6Pack: LevelPack {
        allPacks.first(where: { $0.gridSize == 6 }) ?? fallback6x6Pack
    }

    public static var sector7x7Pack: LevelPack {
        allPacks.first(where: { $0.gridSize == 7 }) ?? fallback7x7Pack
    }

    // MARK: - Hardcoded Fallback Seed Packs

    private static let fallback5x5Pack: LevelPack = {
        let level1 = LevelDefinition(
            id: "5x5-001",
            packId: "sector-5x5",
            number: 1,
            size: 5,
            pairs: [
                TerminalPairDefinition(id: "coolant", fluidType: .coolant, terminalA: GridCoord(x: 0, y: 0), terminalB: GridCoord(x: 2, y: 4)),
                TerminalPairDefinition(id: "fuel", fluidType: .fuel, terminalA: GridCoord(x: 3, y: 1), terminalB: GridCoord(x: 3, y: 3)),
                TerminalPairDefinition(id: "chemical", fluidType: .chemical, terminalA: GridCoord(x: 1, y: 0), terminalB: GridCoord(x: 4, y: 1)),
                TerminalPairDefinition(id: "pressure", fluidType: .pressure, terminalA: GridCoord(x: 2, y: 2), terminalB: GridCoord(x: 3, y: 4))
            ],
            canonicalSolution: [
                CanonicalPathDefinition(lineId: "coolant", path: [
                    GridCoord(x: 0, y: 0), GridCoord(x: 0, y: 1), GridCoord(x: 0, y: 2), GridCoord(x: 0, y: 3),
                    GridCoord(x: 0, y: 4), GridCoord(x: 1, y: 4), GridCoord(x: 2, y: 4)
                ]),
                CanonicalPathDefinition(lineId: "fuel", path: [
                    GridCoord(x: 3, y: 1), GridCoord(x: 2, y: 1), GridCoord(x: 1, y: 1), GridCoord(x: 1, y: 2),
                    GridCoord(x: 1, y: 3), GridCoord(x: 2, y: 3), GridCoord(x: 3, y: 3)
                ]),
                CanonicalPathDefinition(lineId: "chemical", path: [
                    GridCoord(x: 1, y: 0), GridCoord(x: 2, y: 0), GridCoord(x: 3, y: 0), GridCoord(x: 4, y: 0),
                    GridCoord(x: 4, y: 1)
                ]),
                CanonicalPathDefinition(lineId: "pressure", path: [
                    GridCoord(x: 2, y: 2), GridCoord(x: 3, y: 2), GridCoord(x: 4, y: 2), GridCoord(x: 4, y: 3),
                    GridCoord(x: 4, y: 4), GridCoord(x: 3, y: 4)
                ])
            ],
            parMoves: 4,
            difficultyScore: 1.0,
            signature: "5x5_fallback_01"
        )

        return LevelPack(
            id: "sector-5x5",
            name: "5×5",
            subtitle: "Starter Pack",
            gridSize: 5,
            order: 1,
            levels: [level1]
        )
    }()

    private static let fallback6x6Pack: LevelPack = {
        let level1 = LevelDefinition(
            id: "6x6-001",
            packId: "sector-6x6",
            number: 1,
            size: 6,
            pairs: [
                TerminalPairDefinition(id: "coolant", fluidType: .coolant, terminalA: GridCoord(x: 0, y: 1), terminalB: GridCoord(x: 5, y: 0)),
                TerminalPairDefinition(id: "fuel", fluidType: .fuel, terminalA: GridCoord(x: 4, y: 4), terminalB: GridCoord(x: 0, y: 3)),
                TerminalPairDefinition(id: "chemical", fluidType: .chemical, terminalA: GridCoord(x: 0, y: 0), terminalB: GridCoord(x: 3, y: 2)),
                TerminalPairDefinition(id: "pressure", fluidType: .pressure, terminalA: GridCoord(x: 0, y: 4), terminalB: GridCoord(x: 5, y: 4)),
                TerminalPairDefinition(id: "thermal", fluidType: .thermal, terminalA: GridCoord(x: 3, y: 1), terminalB: GridCoord(x: 1, y: 1))
            ],
            canonicalSolution: [
                CanonicalPathDefinition(lineId: "coolant", path: [
                    GridCoord(x: 0, y: 1), GridCoord(x: 0, y: 2), GridCoord(x: 1, y: 2), GridCoord(x: 2, y: 2),
                    GridCoord(x: 2, y: 3), GridCoord(x: 3, y: 3), GridCoord(x: 4, y: 3), GridCoord(x: 5, y: 3),
                    GridCoord(x: 5, y: 2), GridCoord(x: 5, y: 1), GridCoord(x: 5, y: 0)
                ]),
                CanonicalPathDefinition(lineId: "fuel", path: [
                    GridCoord(x: 4, y: 4), GridCoord(x: 3, y: 4), GridCoord(x: 2, y: 4), GridCoord(x: 1, y: 4),
                    GridCoord(x: 1, y: 3), GridCoord(x: 0, y: 3)
                ]),
                CanonicalPathDefinition(lineId: "chemical", path: [
                    GridCoord(x: 0, y: 0), GridCoord(x: 1, y: 0), GridCoord(x: 2, y: 0), GridCoord(x: 3, y: 0),
                    GridCoord(x: 4, y: 0), GridCoord(x: 4, y: 1), GridCoord(x: 4, y: 2), GridCoord(x: 3, y: 2)
                ]),
                CanonicalPathDefinition(lineId: "pressure", path: [
                    GridCoord(x: 0, y: 4), GridCoord(x: 0, y: 5), GridCoord(x: 1, y: 5), GridCoord(x: 2, y: 5),
                    GridCoord(x: 3, y: 5), GridCoord(x: 4, y: 5), GridCoord(x: 5, y: 5), GridCoord(x: 5, y: 4)
                ]),
                CanonicalPathDefinition(lineId: "thermal", path: [
                    GridCoord(x: 3, y: 1), GridCoord(x: 2, y: 1), GridCoord(x: 1, y: 1)
                ])
            ],
            parMoves: 5,
            difficultyScore: 2.0,
            signature: "6x6_fallback_01"
        )

        return LevelPack(
            id: "sector-6x6",
            name: "6×6",
            subtitle: "Standard Pack",
            gridSize: 6,
            order: 2,
            levels: [level1]
        )
    }()

    private static let fallback7x7Pack: LevelPack = {
        let level1 = LevelDefinition(
            id: "7x7-001",
            packId: "sector-7x7",
            number: 1,
            size: 7,
            pairs: [
                TerminalPairDefinition(id: "coolant", fluidType: .coolant, terminalA: GridCoord(x: 1, y: 0), terminalB: GridCoord(x: 1, y: 6)),
                TerminalPairDefinition(id: "pressure", fluidType: .pressure, terminalA: GridCoord(x: 0, y: 0), terminalB: GridCoord(x: 0, y: 6)),
                TerminalPairDefinition(id: "chemical", fluidType: .chemical, terminalA: GridCoord(x: 2, y: 1), terminalB: GridCoord(x: 3, y: 1)),
                TerminalPairDefinition(id: "plasma", fluidType: .plasma, terminalA: GridCoord(x: 4, y: 1), terminalB: GridCoord(x: 5, y: 3)),
                TerminalPairDefinition(id: "fuel", fluidType: .fuel, terminalA: GridCoord(x: 5, y: 4), terminalB: GridCoord(x: 4, y: 5)),
                TerminalPairDefinition(id: "thermal", fluidType: .thermal, terminalA: GridCoord(x: 3, y: 5), terminalB: GridCoord(x: 3, y: 3)),
                TerminalPairDefinition(id: "auxiliary", fluidType: .auxiliary, terminalA: GridCoord(x: 2, y: 2), terminalB: GridCoord(x: 3, y: 4)),
                TerminalPairDefinition(id: "chemical_side", fluidType: .chemical, terminalA: GridCoord(x: 1, y: 1), terminalB: GridCoord(x: 1, y: 5))
            ],
            canonicalSolution: [
                CanonicalPathDefinition(lineId: "coolant", path: [
                    GridCoord(x: 1, y: 0), GridCoord(x: 2, y: 0), GridCoord(x: 3, y: 0), GridCoord(x: 4, y: 0),
                    GridCoord(x: 5, y: 0), GridCoord(x: 6, y: 0), GridCoord(x: 6, y: 1), GridCoord(x: 6, y: 2),
                    GridCoord(x: 6, y: 3), GridCoord(x: 6, y: 4), GridCoord(x: 6, y: 5), GridCoord(x: 6, y: 6),
                    GridCoord(x: 5, y: 6), GridCoord(x: 4, y: 6), GridCoord(x: 3, y: 6), GridCoord(x: 2, y: 6),
                    GridCoord(x: 1, y: 6)
                ]),
                CanonicalPathDefinition(lineId: "pressure", path: [
                    GridCoord(x: 0, y: 0), GridCoord(x: 0, y: 1), GridCoord(x: 0, y: 2), GridCoord(x: 0, y: 3),
                    GridCoord(x: 0, y: 4), GridCoord(x: 0, y: 5), GridCoord(x: 0, y: 6)
                ]),
                CanonicalPathDefinition(lineId: "chemical", path: [
                    GridCoord(x: 2, y: 1), GridCoord(x: 3, y: 1)
                ]),
                CanonicalPathDefinition(lineId: "plasma", path: [
                    GridCoord(x: 4, y: 1), GridCoord(x: 5, y: 1), GridCoord(x: 5, y: 2), GridCoord(x: 5, y: 3)
                ]),
                CanonicalPathDefinition(lineId: "fuel", path: [
                    GridCoord(x: 5, y: 4), GridCoord(x: 5, y: 5), GridCoord(x: 4, y: 5)
                ]),
                CanonicalPathDefinition(lineId: "thermal", path: [
                    GridCoord(x: 3, y: 5), GridCoord(x: 2, y: 5), GridCoord(x: 2, y: 4), GridCoord(x: 2, y: 3),
                    GridCoord(x: 3, y: 3)
                ]),
                CanonicalPathDefinition(lineId: "auxiliary", path: [
                    GridCoord(x: 2, y: 2), GridCoord(x: 3, y: 2), GridCoord(x: 4, y: 2), GridCoord(x: 4, y: 3),
                    GridCoord(x: 4, y: 4), GridCoord(x: 3, y: 4)
                ]),
                CanonicalPathDefinition(lineId: "chemical_side", path: [
                    GridCoord(x: 1, y: 1), GridCoord(x: 1, y: 2), GridCoord(x: 1, y: 3), GridCoord(x: 1, y: 4),
                    GridCoord(x: 1, y: 5)
                ])
            ],
            parMoves: 8,
            difficultyScore: 3.0,
            signature: "7x7_fallback_01"
        )

        return LevelPack(
            id: "sector-7x7",
            name: "7×7",
            subtitle: "Advanced Pack",
            gridSize: 7,
            order: 3,
            levels: [level1]
        )
    }()
}
