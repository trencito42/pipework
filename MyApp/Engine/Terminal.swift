import Foundation

/// Represents a fixed mechanical pipe connection socket on the PIPEWORK board.
public struct Terminal: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let lineId: String
    public let fluidType: FluidType
    public let coord: GridCoord
    public let isPrimarySocket: Bool

    public init(
        id: String? = nil,
        lineId: String,
        fluidType: FluidType,
        coord: GridCoord,
        isPrimarySocket: Bool = true
    ) {
        self.id = id ?? "\(lineId)_\(isPrimarySocket ? "A" : "B")"
        self.lineId = lineId
        self.fluidType = fluidType
        self.coord = coord
        self.isPrimarySocket = isPrimarySocket
    }
}
