import Foundation

/// Represents the four cardinal orthogonal directions in the PIPEWORK puzzle engine.
public enum GridDirection: String, Codable, Sendable, CaseIterable {
    case north
    case south
    case east
    case west

    /// Directional axis (Horizontal vs Vertical).
    public enum Axis: String, Codable, Sendable, CaseIterable {
        case horizontal
        case vertical
    }

    /// The axis of this direction.
    public var axis: Axis {
        switch self {
        case .east, .west: return .horizontal
        case .north, .south: return .vertical
        }
    }

    /// Unit delta on X axis.
    public var dx: Int {
        switch self {
        case .north, .south: return 0
        case .east: return 1
        case .west: return -1
        }
    }

    /// Unit delta on Y axis (South is positive down).
    public var dy: Int {
        switch self {
        case .north: return -1
        case .south: return 1
        case .east, .west: return 0
        }
    }

    /// The opposite cardinal direction.
    public var opposite: GridDirection {
        switch self {
        case .north: return .south
        case .south: return .north
        case .east: return .west
        case .west: return .east
        }
    }
}
