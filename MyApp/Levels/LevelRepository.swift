import Foundation

/// Static repository of curated, validated, solution-first level packs.
public enum LevelRepository {

    public static let allPacks: [LevelPack] = [
        sector5x5Pack,
        sector6x6Pack,
        sector7x7Pack
    ]

    public static var defaultLevel: LevelDefinition {
        sector7x7Pack.levels[0]
    }

    // MARK: - Sector 01: 5x5 Grid Pack

    public static let sector5x5Pack: LevelPack = {
        let level1 = LevelDefinition(
            id: "5x5-01",
            packId: "sector-5x5",
            number: 1,
            size: 5,
            pairs: [
                TerminalPairDefinition(id: "coolant", fluidType: .coolant, terminalA: GridCoord(x: 4, y: 3), terminalB: GridCoord(x: 3, y: 2)),
                TerminalPairDefinition(id: "fuel", fluidType: .fuel, terminalA: GridCoord(x: 4, y: 4), terminalB: GridCoord(x: 1, y: 3)),
                TerminalPairDefinition(id: "chemical", fluidType: .chemical, terminalA: GridCoord(x: 2, y: 1), terminalB: GridCoord(x: 0, y: 2)),
                TerminalPairDefinition(id: "pressure", fluidType: .pressure, terminalA: GridCoord(x: 4, y: 2), terminalB: GridCoord(x: 3, y: 1))
            ],
            canonicalSolution: [
                CanonicalPathDefinition(lineId: "coolant", path: [
                    GridCoord(x: 4, y: 3), GridCoord(x: 3, y: 3), GridCoord(x: 2, y: 3), GridCoord(x: 2, y: 2), GridCoord(x: 3, y: 2)
                ]),
                CanonicalPathDefinition(lineId: "fuel", path: [
                    GridCoord(x: 4, y: 4), GridCoord(x: 3, y: 4), GridCoord(x: 2, y: 4), GridCoord(x: 1, y: 4),
                    GridCoord(x: 0, y: 4), GridCoord(x: 0, y: 3), GridCoord(x: 1, y: 3)
                ]),
                CanonicalPathDefinition(lineId: "chemical", path: [
                    GridCoord(x: 2, y: 1), GridCoord(x: 2, y: 0), GridCoord(x: 1, y: 0), GridCoord(x: 0, y: 0),
                    GridCoord(x: 0, y: 1), GridCoord(x: 1, y: 1), GridCoord(x: 1, y: 2), GridCoord(x: 0, y: 2)
                ]),
                CanonicalPathDefinition(lineId: "pressure", path: [
                    GridCoord(x: 4, y: 2), GridCoord(x: 4, y: 1), GridCoord(x: 4, y: 0), GridCoord(x: 3, y: 0), GridCoord(x: 3, y: 1)
                ])
            ],
            parMoves: 4,
            difficultyScore: 1.0,
            signature: "5x5_01"
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

    // MARK: - Sector 02: 6x6 Grid Pack

    public static let sector6x6Pack: LevelPack = {
        let level1 = LevelDefinition(
            id: "6x6-01",
            packId: "sector-6x6",
            number: 1,
            size: 6,
            pairs: [
                TerminalPairDefinition(id: "coolant", fluidType: .coolant, terminalA: GridCoord(x: 3, y: 5), terminalB: GridCoord(x: 4, y: 2)),
                TerminalPairDefinition(id: "fuel", fluidType: .fuel, terminalA: GridCoord(x: 1, y: 0), terminalB: GridCoord(x: 1, y: 5)),
                TerminalPairDefinition(id: "chemical", fluidType: .chemical, terminalA: GridCoord(x: 1, y: 2), terminalB: GridCoord(x: 5, y: 0)),
                TerminalPairDefinition(id: "pressure", fluidType: .pressure, terminalA: GridCoord(x: 1, y: 4), terminalB: GridCoord(x: 2, y: 2)),
                TerminalPairDefinition(id: "thermal", fluidType: .thermal, terminalA: GridCoord(x: 3, y: 3), terminalB: GridCoord(x: 4, y: 5))
            ],
            canonicalSolution: [
                CanonicalPathDefinition(lineId: "coolant", path: [
                    GridCoord(x: 3, y: 5), GridCoord(x: 2, y: 5), GridCoord(x: 2, y: 4), GridCoord(x: 3, y: 4),
                    GridCoord(x: 4, y: 4), GridCoord(x: 4, y: 3), GridCoord(x: 4, y: 2)
                ]),
                CanonicalPathDefinition(lineId: "fuel", path: [
                    GridCoord(x: 1, y: 0), GridCoord(x: 0, y: 0), GridCoord(x: 0, y: 1), GridCoord(x: 0, y: 2),
                    GridCoord(x: 0, y: 3), GridCoord(x: 0, y: 4), GridCoord(x: 0, y: 5), GridCoord(x: 1, y: 5)
                ]),
                CanonicalPathDefinition(lineId: "chemical", path: [
                    GridCoord(x: 1, y: 2), GridCoord(x: 1, y: 1), GridCoord(x: 2, y: 1), GridCoord(x: 2, y: 0),
                    GridCoord(x: 3, y: 0), GridCoord(x: 4, y: 0), GridCoord(x: 5, y: 0)
                ]),
                CanonicalPathDefinition(lineId: "pressure", path: [
                    GridCoord(x: 1, y: 4), GridCoord(x: 1, y: 3), GridCoord(x: 2, y: 3), GridCoord(x: 2, y: 2)
                ]),
                CanonicalPathDefinition(lineId: "thermal", path: [
                    GridCoord(x: 3, y: 3), GridCoord(x: 3, y: 2), GridCoord(x: 3, y: 1), GridCoord(x: 4, y: 1),
                    GridCoord(x: 5, y: 1), GridCoord(x: 5, y: 2), GridCoord(x: 5, y: 3), GridCoord(x: 5, y: 4),
                    GridCoord(x: 5, y: 5), GridCoord(x: 4, y: 5)
                ])
            ],
            parMoves: 5,
            difficultyScore: 2.0,
            signature: "6x6_01"
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

    // MARK: - Sector 03: 7x7 Grid Pack

    public static let sector7x7Pack: LevelPack = {
        let level1 = LevelDefinition(
            id: "7x7-01",
            packId: "sector-7x7",
            number: 1,
            size: 7,
            pairs: [
                TerminalPairDefinition(id: "coolant", fluidType: .coolant, terminalA: GridCoord(x: 0, y: 0), terminalB: GridCoord(x: 6, y: 6)),
                TerminalPairDefinition(id: "fuel", fluidType: .fuel, terminalA: GridCoord(x: 0, y: 1), terminalB: GridCoord(x: 5, y: 6)),
                TerminalPairDefinition(id: "chemical", fluidType: .chemical, terminalA: GridCoord(x: 0, y: 2), terminalB: GridCoord(x: 4, y: 6)),
                TerminalPairDefinition(id: "pressure", fluidType: .pressure, terminalA: GridCoord(x: 0, y: 3), terminalB: GridCoord(x: 3, y: 6)),
                TerminalPairDefinition(id: "thermal", fluidType: .thermal, terminalA: GridCoord(x: 0, y: 4), terminalB: GridCoord(x: 2, y: 6)),
                TerminalPairDefinition(id: "auxiliary", fluidType: .auxiliary, terminalA: GridCoord(x: 0, y: 5), terminalB: GridCoord(x: 0, y: 6))
            ],
            canonicalSolution: [
                CanonicalPathDefinition(lineId: "coolant", path: [
                    GridCoord(x: 0, y: 0), GridCoord(x: 1, y: 0), GridCoord(x: 2, y: 0), GridCoord(x: 3, y: 0), GridCoord(x: 4, y: 0), GridCoord(x: 5, y: 0), GridCoord(x: 6, y: 0),
                    GridCoord(x: 6, y: 1), GridCoord(x: 6, y: 2), GridCoord(x: 6, y: 3), GridCoord(x: 6, y: 4), GridCoord(x: 6, y: 5), GridCoord(x: 6, y: 6)
                ]),
                CanonicalPathDefinition(lineId: "fuel", path: [
                    GridCoord(x: 0, y: 1), GridCoord(x: 1, y: 1), GridCoord(x: 2, y: 1), GridCoord(x: 3, y: 1), GridCoord(x: 4, y: 1), GridCoord(x: 5, y: 1),
                    GridCoord(x: 5, y: 2), GridCoord(x: 5, y: 3), GridCoord(x: 5, y: 4), GridCoord(x: 5, y: 5), GridCoord(x: 5, y: 6)
                ]),
                CanonicalPathDefinition(lineId: "chemical", path: [
                    GridCoord(x: 0, y: 2), GridCoord(x: 1, y: 2), GridCoord(x: 2, y: 2), GridCoord(x: 3, y: 2), GridCoord(x: 4, y: 2),
                    GridCoord(x: 4, y: 3), GridCoord(x: 4, y: 4), GridCoord(x: 4, y: 5), GridCoord(x: 4, y: 6)
                ]),
                CanonicalPathDefinition(lineId: "pressure", path: [
                    GridCoord(x: 0, y: 3), GridCoord(x: 1, y: 3), GridCoord(x: 2, y: 3), GridCoord(x: 3, y: 3),
                    GridCoord(x: 3, y: 4), GridCoord(x: 3, y: 5), GridCoord(x: 3, y: 6)
                ]),
                CanonicalPathDefinition(lineId: "thermal", path: [
                    GridCoord(x: 0, y: 4), GridCoord(x: 1, y: 4), GridCoord(x: 2, y: 4),
                    GridCoord(x: 2, y: 5), GridCoord(x: 2, y: 6)
                ]),
                CanonicalPathDefinition(lineId: "auxiliary", path: [
                    GridCoord(x: 0, y: 5), GridCoord(x: 1, y: 5), GridCoord(x: 1, y: 6), GridCoord(x: 0, y: 6)
                ])
            ],
            parMoves: 6,
            difficultyScore: 3.5,
            signature: "7x7_01"
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
