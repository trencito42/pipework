import SwiftUI

/// Industrial design system tokens for PIPEWORK.
public enum PipeworkTheme {

    // MARK: - Environmental Palette
    public static let bgBase = Color(red: 7/255, green: 8/255, blue: 9/255)           // #070809
    public static let bgVignette = Color(red: 15/255, green: 19/255, blue: 24/255)    // #0F1318
    public static let panelBase = Color(red: 13/255, green: 16/255, blue: 20/255)     // #0D1014
    public static let panelSubtle = Color(red: 19/255, green: 23/255, blue: 29/255)   // #13171D
    public static let borderDim = Color(red: 31/255, green: 38/255, blue: 48/255)     // #1F2630
    public static let borderBright = Color(red: 45/255, green: 55/255, blue: 68/255)   // #2D3744
    public static let gridLine = Color(white: 1.0, opacity: 0.035)
    public static let gridCellEmpty = Color(red: 8/255, green: 10/255, blue: 13/255)  // #080A0D

    // MARK: - UI Accents & Text
    public static let primaryCyan = Color(red: 32/255, green: 231/255, blue: 231/255) // #20E7E7
    public static let pressureGreen = Color(red: 37/255, green: 211/255, blue: 102/255)// #25D366
    public static let warningRed = Color(red: 255/255, green: 59/255, blue: 48/255)    // #FF3B30
    public static let textMain = Color(red: 230/255, green: 237/255, blue: 245/255)   // #E6EDF5
    public static let textMuted = Color(red: 94/255, green: 107/255, blue: 124/255)   // #5E6B7C
    public static let textDim = Color(red: 65/255, green: 75/255, blue: 88/255)       // #414B58

    // MARK: - Fluid Line Colors
    public static func fluidColor(for type: FluidType) -> Color {
        switch type {
        case .coolant:
            return Color(red: 32/255, green: 231/255, blue: 231/255) // Electric Cyan #20E7E7
        case .fuel:
            return Color(red: 255/255, green: 123/255, blue: 28/255) // Amber Orange #FF7B1C
        case .chemical:
            return Color(red: 132/255, green: 224/255, blue: 42/255) // Emerald Green #84E02A
        case .thermal:
            return Color(red: 255/255, green: 59/255, blue: 48/255)  // Emergency Red #FF3B30
        case .pressure:
            return Color(red: 179/255, green: 88/255, blue: 246/255) // Neon Violet #B358F6
        case .auxiliary:
            return Color(red: 61/255, green: 123/255, blue: 255/255) // Hydraulic Blue #3D7BFF
        case .plasma:
            return Color(red: 255/255, green: 0/255, blue: 136/255)  // Neon Magenta #FF0088
        case .steam:
            return Color(red: 226/255, green: 234/255, blue: 243/255)// Titanium White #E2EAF3
        }
    }

    public static func fluidGlowColor(for type: FluidType) -> Color {
        fluidColor(for: type).opacity(0.4)
    }

    // MARK: - Typography
    public static func monoFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    public static func roundedFont(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
