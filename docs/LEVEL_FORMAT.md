# PIPEWORK — Level Format & Serialization Specification

## 1. Schema Overview
Level definitions in PIPEWORK are self-contained, serializable JSON objects conforming to Swift's `Codable`.

---

## 2. Level JSON Schema

```json
{
  "id": "sector-01-01",
  "packId": "sector-5x5",
  "number": 1,
  "size": 5,
  "pairs": [
    {
      "id": "coolant",
      "fluidType": "coolant",
      "terminalA": {"x": 0, "y": 0},
      "terminalB": {"x": 4, "y": 0}
    },
    {
      "id": "fuel",
      "fluidType": "fuel",
      "terminalA": {"x": 0, "y": 1},
      "terminalB": {"x": 4, "y": 1}
    },
    {
      "id": "chemical",
      "fluidType": "chemical",
      "terminalA": {"x": 0, "y": 2},
      "terminalB": {"x": 4, "y": 2}
    },
    {
      "id": "thermal",
      "fluidType": "thermal",
      "terminalA": {"x": 0, "y": 3},
      "terminalB": {"x": 4, "y": 3}
    },
    {
      "id": "pressure",
      "fluidType": "pressure",
      "terminalA": {"x": 0, "y": 4},
      "terminalB": {"x": 4, "y": 4}
    }
  ],
  "canonicalSolution": [
    {
      "fluidId": "coolant",
      "path": [{"x": 0, "y": 0}, {"x": 1, "y": 0}, {"x": 2, "y": 0}, {"x": 3, "y": 0}, {"x": 4, "y": 0}]
    },
    {
      "fluidId": "fuel",
      "path": [{"x": 0, "y": 1}, {"x": 1, "y": 1}, {"x": 2, "y": 1}, {"x": 3, "y": 1}, {"x": 4, "y": 1}]
    },
    {
      "fluidId": "chemical",
      "path": [{"x": 0, "y": 2}, {"x": 1, "y": 2}, {"x": 2, "y": 2}, {"x": 3, "y": 2}, {"x": 4, "y": 2}]
    },
    {
      "fluidId": "thermal",
      "path": [{"x": 0, "y": 3}, {"x": 1, "y": 3}, {"x": 2, "y": 3}, {"x": 3, "y": 3}, {"x": 4, "y": 3}]
    },
    {
      "fluidId": "pressure",
      "path": [{"x": 0, "y": 4}, {"x": 1, "y": 4}, {"x": 2, "y": 4}, {"x": 3, "y": 4}, {"x": 4, "y": 4}]
    }
  ],
  "parMoves": 5,
  "difficultyScore": 1.2,
  "signature": "c5x5_s01_01_a9f8b2"
}
```

---

## 3. Swift Codable Model

```swift
public struct LevelDefinition: Codable, Identifiable, Sendable, Equatable {
    public let id: String
    public let packId: String
    public let number: Int
    public let size: Int
    public let pairs: [TerminalPair]
    public let canonicalSolution: [CanonicalPath]?
    public let parMoves: Int
    public let difficultyScore: Double
    public let signature: String
    
    public init(
        id: String,
        packId: String,
        number: Int,
        size: Int,
        pairs: [TerminalPair],
        canonicalSolution: [CanonicalPath]? = nil,
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
}

public struct TerminalPair: Codable, Identifiable, Sendable, Equatable {
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
}

public struct CanonicalPath: Codable, Sendable, Equatable {
    public let fluidId: String
    public let path: [GridCoord]
    
    public init(fluidId: String, path: [GridCoord]) {
        self.fluidId = fluidId
        self.path = path
    }
}
```

---

## 4. Pack Schema
```json
{
  "id": "sector-5x5",
  "name": "Sector 01 — 5×5 Standard",
  "gridSize": 5,
  "order": 1,
  "levels": ["sector-01-01", "sector-01-02", "..."]
}
```
