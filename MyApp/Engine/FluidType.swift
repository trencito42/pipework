import Foundation

/// Industrial fluid routing classifications in PIPEWORK.
public enum FluidType: String, Codable, Sendable, CaseIterable, Identifiable {
    case coolant
    case fuel
    case chemical
    case thermal
    case pressure
    case auxiliary
    case plasma
    case steam

    public var id: String { rawValue }

    /// Human-readable industrial classification name.
    public var displayName: String {
        switch self {
        case .coolant: return "Coolant Alpha"
        case .fuel: return "Fuel Propellant"
        case .chemical: return "Chemical Solvent"
        case .thermal: return "Thermal Core"
        case .pressure: return "Hydraulic Pressure"
        case .auxiliary: return "Auxiliary Line"
        case .plasma: return "Plasma Conduit"
        case .steam: return "Steam Equalizer"
        }
    }

    /// Single-character / glyph code for accessibility overlays.
    public var symbolCode: String {
        switch self {
        case .coolant: return "C"
        case .fuel: return "F"
        case .chemical: return "K"
        case .thermal: return "T"
        case .pressure: return "P"
        case .auxiliary: return "A"
        case .plasma: return "M"
        case .steam: return "S"
        }
    }

    /// Geometric unicode shape for high-contrast / colorblind rendering.
    public var geometricSymbol: String {
        switch self {
        case .coolant: return "●"
        case .fuel: return "▲"
        case .chemical: return "◆"
        case .thermal: return "■"
        case .pressure: return "✚"
        case .auxiliary: return "★"
        case .plasma: return "⬡"
        case .steam: return "≈"
        }
    }
}
