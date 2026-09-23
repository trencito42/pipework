import Foundation

/// Defines a level pair socket configuration.
public struct TerminalPairDefinition: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let fluidType: FluidType
    public let terminalA: GridCoord
    public let terminalB: GridCoord

    public init(id: String, fluidType: FluidType, terminalA: GridCoord, terminalB: GridCoord) {
        self.id = id
        self.fluidType = fluidType
        self.terminalA = terminalA
        self.terminalB = terminalB
    }

    /// Converts into a pair of engine `Terminal` structs.
    public func toTerminals() -> [Terminal] {
        [
            Terminal(id: "\(id)_A", lineId: id, fluidType: fluidType, coord: terminalA, isPrimarySocket: true),
            Terminal(id: "\(id)_B", lineId: id, fluidType: fluidType, coord: terminalB, isPrimarySocket: false)
        ]
    }
}

/// A pre-verified canonical solution path for a line.
public struct CanonicalPathDefinition: Codable, Hashable, Sendable {
    public let lineId: String
    public let path: [GridCoord]

    public init(lineId: String, path: [GridCoord]) {
        self.lineId = lineId
        self.path = path
    }
}

/// Complete serializable definition for a single PIPEWORK level.
public struct LevelDefinition: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let packId: String
    public let number: Int
    public let size: Int
    public let pairs: [TerminalPairDefinition]
    public let canonicalSolution: [CanonicalPathDefinition]?
    public let parMoves: Int
    public let difficultyScore: Double
    public let signature: String

    public init(
        id: String,
        packId: String,
        number: Int,
        size: Int,
        pairs: [TerminalPairDefinition],
        canonicalSolution: [CanonicalPathDefinition]? = nil,
        parMoves: Int? = nil,
        difficultyScore: Double = 1.0,
        signature: String = ""
    ) {
        self.id = id
        self.packId = packId
        self.number = number
        self.size = size
        self.pairs = pairs
        self.canonicalSolution = canonicalSolution
        self.parMoves = parMoves ?? pairs.count
        self.difficultyScore = difficultyScore
        self.signature = signature
    }

    /// Creates a playable `PuzzleState` from this level definition.
    public func createInitialState() -> PuzzleState {
        let allTerminals = pairs.flatMap { $0.toTerminals() }
        let gridSize = GridSize(dimension: size)
        return PuzzleState(gridSize: gridSize, terminals: allTerminals)
    }
}
