import Foundation

/// Static repository of curated, validated, solution-first sector packs.
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
            id: "sec-01-01",
            packId: "sector-5x5",
            number: 1,
            size: 5,
            pairs: [
                TerminalPairDefinition(
                    id: "coolant",
                    fluidType: .coolant,
                    terminalA: GridCoord(x: 0, y: 0),
                    terminalB: GridCoord(x: 0, y: 4)
                ),
                TerminalPairDefinition(
                    id: "fuel",
                    fluidType: .fuel,
                    terminalA: GridCoord(x: 4, y: 2),
                    terminalB: GridCoord(x: 4, y: 4)
                ),
                TerminalPairDefinition(
                    id: "chemical",
                    fluidType: .chemical,
                    terminalA: GridCoord(x: 1, y: 4),
                    terminalB: GridCoord(x: 3, y: 4)
                )
            ],
            canonicalSolution: [
                CanonicalPathDefinition(
                    lineId: "coolant",
                    path: [
                        GridCoord(x: 0, y: 0), GridCoord(x: 1, y: 0), GridCoord(x: 2, y: 0), GridCoord(x: 3, y: 0), GridCoord(x: 4, y: 0),
                        GridCoord(x: 4, y: 1), GridCoord(x: 3, y: 1), GridCoord(x: 2, y: 1), GridCoord(x: 1, y: 1), GridCoord(x: 0, y: 1),
                        GridCoord(x: 0, y: 2), GridCoord(x: 0, y: 3), GridCoord(x: 0, y: 4)
                    ]
                ),
                CanonicalPathDefinition(
                    lineId: "fuel",
                    path: [
                        GridCoord(x: 4, y: 2), GridCoord(x: 3, y: 2), GridCoord(x: 2, y: 2), GridCoord(x: 1, y: 2),
                        GridCoord(x: 1, y: 3), GridCoord(x: 2, y: 3), GridCoord(x: 3, y: 3), GridCoord(x: 4, y: 3), GridCoord(x: 4, y: 4)
                    ]
                ),
                CanonicalPathDefinition(
                    lineId: "chemical",
                    path: [
                        GridCoord(x: 1, y: 4), GridCoord(x: 2, y: 4), GridCoord(x: 3, y: 4)
                    ]
                )
            ],
            parMoves: 3,
            difficultyScore: 1.0,
            signature: "5x5_s01_01"
        )

        return LevelPack(
            id: "sector-5x5",
            name: "SECTOR 01",
            subtitle: "5×5 Standard Diagnostics",
            gridSize: 5,
            order: 1,
            levels: [level1]
        )
    }()

    // MARK: - Sector 02: 6x6 Grid Pack

    public static let sector6x6Pack: LevelPack = {
        let level1 = LevelDefinition(
            id: "sec-02-01",
            packId: "sector-6x6",
            number: 1,
            size: 6,
            pairs: [
                TerminalPairDefinition(
                    id: "coolant",
                    fluidType: .coolant,
                    terminalA: GridCoord(x: 0, y: 0),
                    terminalB: GridCoord(x: 0, y: 5)
                ),
                TerminalPairDefinition(
                    id: "fuel",
                    fluidType: .fuel,
                    terminalA: GridCoord(x: 5, y: 0),
                    terminalB: GridCoord(x: 5, y: 5)
                ),
                TerminalPairDefinition(
                    id: "chemical",
                    fluidType: .chemical,
                    terminalA: GridCoord(x: 1, y: 1),
                    terminalB: GridCoord(x: 4, y: 1)
                ),
                TerminalPairDefinition(
                    id: "thermal",
                    fluidType: .thermal,
                    terminalA: GridCoord(x: 1, y: 4),
                    terminalB: GridCoord(x: 4, y: 4)
                ),
                TerminalPairDefinition(
                    id: "pressure",
                    fluidType: .pressure,
                    terminalA: GridCoord(x: 1, y: 2),
                    terminalB: GridCoord(x: 4, y: 3)
                )
            ],
            parMoves: 5,
            difficultyScore: 2.0,
            signature: "6x6_s02_01"
        )

        return LevelPack(
            id: "sector-6x6",
            name: "SECTOR 02",
            subtitle: "6×6 High Flow Conduit",
            gridSize: 6,
            order: 2,
            levels: [level1]
        )
    }()

    // MARK: - Sector 03: 7x7 Grid Pack (Industrial Sectors 07, 08, 09, 10)

    public static let sector7x7Pack: LevelPack = {
        // Sector 07 (7x7, 49/49 cells full-board solution)
        let level7 = LevelDefinition(
            id: "sector-07",
            packId: "sector-7x7",
            number: 7,
            size: 7,
            pairs: [
                TerminalPairDefinition(
                    id: "coolant",
                    fluidType: .coolant,
                    terminalA: GridCoord(x: 0, y: 0),
                    terminalB: GridCoord(x: 6, y: 6)
                ),
                TerminalPairDefinition(
                    id: "fuel",
                    fluidType: .fuel,
                    terminalA: GridCoord(x: 0, y: 1),
                    terminalB: GridCoord(x: 0, y: 2)
                ),
                TerminalPairDefinition(
                    id: "chemical",
                    fluidType: .chemical,
                    terminalA: GridCoord(x: 0, y: 3),
                    terminalB: GridCoord(x: 3, y: 4)
                ),
                TerminalPairDefinition(
                    id: "pressure",
                    fluidType: .pressure,
                    terminalA: GridCoord(x: 2, y: 4),
                    terminalB: GridCoord(x: 3, y: 5)
                ),
                TerminalPairDefinition(
                    id: "thermal",
                    fluidType: .thermal,
                    terminalA: GridCoord(x: 4, y: 5),
                    terminalB: GridCoord(x: 0, y: 6)
                )
            ],
            canonicalSolution: [
                CanonicalPathDefinition(
                    lineId: "coolant",
                    path: [
                        GridCoord(x: 0, y: 0), GridCoord(x: 1, y: 0), GridCoord(x: 2, y: 0), GridCoord(x: 3, y: 0), GridCoord(x: 4, y: 0), GridCoord(x: 5, y: 0), GridCoord(x: 6, y: 0),
                        GridCoord(x: 6, y: 1), GridCoord(x: 6, y: 2), GridCoord(x: 6, y: 3), GridCoord(x: 6, y: 4), GridCoord(x: 6, y: 5), GridCoord(x: 6, y: 6)
                    ]
                ),
                CanonicalPathDefinition(
                    lineId: "fuel",
                    path: [
                        GridCoord(x: 0, y: 1), GridCoord(x: 1, y: 1), GridCoord(x: 2, y: 1), GridCoord(x: 3, y: 1), GridCoord(x: 4, y: 1), GridCoord(x: 5, y: 1),
                        GridCoord(x: 5, y: 2), GridCoord(x: 4, y: 2), GridCoord(x: 3, y: 2), GridCoord(x: 2, y: 2), GridCoord(x: 1, y: 2), GridCoord(x: 0, y: 2)
                    ]
                ),
                CanonicalPathDefinition(
                    lineId: "chemical",
                    path: [
                        GridCoord(x: 0, y: 3), GridCoord(x: 1, y: 3), GridCoord(x: 2, y: 3), GridCoord(x: 3, y: 3), GridCoord(x: 4, y: 3), GridCoord(x: 5, y: 3),
                        GridCoord(x: 5, y: 4), GridCoord(x: 4, y: 4), GridCoord(x: 3, y: 4)
                    ]
                ),
                CanonicalPathDefinition(
                    lineId: "pressure",
                    path: [
                        GridCoord(x: 2, y: 4), GridCoord(x: 1, y: 4), GridCoord(x: 0, y: 4),
                        GridCoord(x: 0, y: 5), GridCoord(x: 1, y: 5), GridCoord(x: 2, y: 5), GridCoord(x: 3, y: 5)
                    ]
                ),
                CanonicalPathDefinition(
                    lineId: "thermal",
                    path: [
                        GridCoord(x: 4, y: 5), GridCoord(x: 5, y: 5),
                        GridCoord(x: 5, y: 6), GridCoord(x: 4, y: 6), GridCoord(x: 3, y: 6), GridCoord(x: 2, y: 6), GridCoord(x: 1, y: 6), GridCoord(x: 0, y: 6)
                    ]
                )
            ],
            parMoves: 5,
            difficultyScore: 3.5,
            signature: "7x7_s07"
        )

        // Sector 08 (7x7, 49/49 cells full-board solution)
        let level8 = LevelDefinition(
            id: "sector-08",
            packId: "sector-7x7",
            number: 8,
            size: 7,
            pairs: [
                TerminalPairDefinition(
                    id: "coolant",
                    fluidType: .coolant,
                    terminalA: GridCoord(x: 0, y: 0),
                    terminalB: GridCoord(x: 6, y: 6)
                ),
                TerminalPairDefinition(
                    id: "fuel",
                    fluidType: .fuel,
                    terminalA: GridCoord(x: 1, y: 0),
                    terminalB: GridCoord(x: 6, y: 5)
                ),
                TerminalPairDefinition(
                    id: "chemical",
                    fluidType: .chemical,
                    terminalA: GridCoord(x: 1, y: 1),
                    terminalB: GridCoord(x: 2, y: 1)
                ),
                TerminalPairDefinition(
                    id: "pressure",
                    fluidType: .pressure,
                    terminalA: GridCoord(x: 3, y: 1),
                    terminalB: GridCoord(x: 5, y: 3)
                ),
                TerminalPairDefinition(
                    id: "thermal",
                    fluidType: .thermal,
                    terminalA: GridCoord(x: 5, y: 4),
                    terminalB: GridCoord(x: 5, y: 5)
                )
            ],
            canonicalSolution: [
                CanonicalPathDefinition(
                    lineId: "coolant",
                    path: [
                        GridCoord(x: 0, y: 0), GridCoord(x: 0, y: 1), GridCoord(x: 0, y: 2), GridCoord(x: 0, y: 3), GridCoord(x: 0, y: 4), GridCoord(x: 0, y: 5), GridCoord(x: 0, y: 6),
                        GridCoord(x: 1, y: 6), GridCoord(x: 2, y: 6), GridCoord(x: 3, y: 6), GridCoord(x: 4, y: 6), GridCoord(x: 5, y: 6), GridCoord(x: 6, y: 6)
                    ]
                ),
                CanonicalPathDefinition(
                    lineId: "fuel",
                    path: [
                        GridCoord(x: 1, y: 0), GridCoord(x: 2, y: 0), GridCoord(x: 3, y: 0), GridCoord(x: 4, y: 0), GridCoord(x: 5, y: 0), GridCoord(x: 6, y: 0),
                        GridCoord(x: 6, y: 1), GridCoord(x: 6, y: 2), GridCoord(x: 6, y: 3), GridCoord(x: 6, y: 4), GridCoord(x: 6, y: 5)
                    ]
                ),
                CanonicalPathDefinition(
                    lineId: "chemical",
                    path: [
                        GridCoord(x: 1, y: 1), GridCoord(x: 1, y: 2), GridCoord(x: 1, y: 3), GridCoord(x: 1, y: 4), GridCoord(x: 1, y: 5),
                        GridCoord(x: 2, y: 5), GridCoord(x: 2, y: 4), GridCoord(x: 2, y: 3), GridCoord(x: 2, y: 2), GridCoord(x: 2, y: 1)
                    ]
                ),
                CanonicalPathDefinition(
                    lineId: "pressure",
                    path: [
                        GridCoord(x: 3, y: 1), GridCoord(x: 4, y: 1), GridCoord(x: 5, y: 1),
                        GridCoord(x: 5, y: 2), GridCoord(x: 4, y: 2), GridCoord(x: 3, y: 2),
                        GridCoord(x: 3, y: 3), GridCoord(x: 4, y: 3), GridCoord(x: 5, y: 3)
                    ]
                ),
                CanonicalPathDefinition(
                    lineId: "thermal",
                    path: [
                        GridCoord(x: 5, y: 4), GridCoord(x: 4, y: 4), GridCoord(x: 3, y: 4),
                        GridCoord(x: 3, y: 5), GridCoord(x: 4, y: 5), GridCoord(x: 5, y: 5)
                    ]
                )
            ],
            parMoves: 5,
            difficultyScore: 4.0,
            signature: "7x7_s08"
        )

        return LevelPack(
            id: "sector-7x7",
            name: "SECTOR 07",
            subtitle: "7×7 Pressurized Grid",
            gridSize: 7,
            order: 7,
            levels: [level7, level8]
        )
    }()
}
