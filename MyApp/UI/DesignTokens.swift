import SwiftUI

/// Unified, modern, and elegant design system tokens for PIPEWORK.
public enum PipeworkTheme {

    // MARK: - Canvas & Surface Palette (Softened Low-Contrast Charcoal/Obsidian)
    public static let bgBase = Color(red: 11/255, green: 14/255, blue: 18/255)         // #0B0E12
    public static let bgCanvas = Color(red: 14/255, green: 17/255, blue: 23/255)       // #0E1117
    public static let bgElevated = Color(red: 20/255, green: 25/255, blue: 33/255)     // #141921
    public static let surfaceSubtle = Color(red: 26/255, green: 32/255, blue: 42/255)  // #1A202A
    public static let surfaceCard = Color(red: 18/255, green: 22/255, blue: 30/255)    // #12161E
    
    // MARK: - Borders & Dividers
    public static let borderSubtle = Color.white.opacity(0.07)
    public static let borderDefault = Color.white.opacity(0.12)
    public static let borderActive = Color(red: 0/255, green: 229/255, blue: 229/255).opacity(0.45)
    public static let gridLine = Color.white.opacity(0.04)

    // MARK: - Core Accent Colors
    public static let primaryCyan = Color(red: 0/255, green: 229/255, blue: 229/255)   // #00E5E5
    public static let cyanMuted = Color(red: 0/255, green: 170/255, blue: 175/255)     // #00AAAF
    public static let pressureGreen = Color(red: 34/255, green: 197/255, blue: 94/255) // #22C55E
    public static let warningRed = Color(red: 244/255, green: 63/255, blue: 94/255)    // #F43F5E
    public static let goldStar = Color(red: 251/255, green: 191/255, blue: 36/255)     // #FBBF24

    // MARK: - Neutral Typography Palette
    public static let textMain = Color(red: 245/255, green: 247/255, blue: 250/255)   // #F5F7FA
    public static let textSecondary = Color(red: 156/255, green: 168/255, blue: 184/255)// #9CA8B8
    public static let textMuted = Color(red: 100/255, green: 112/255, blue: 128/255)   // #647080
    public static let textDim = Color(red: 60/255, green: 70/255, blue: 84/255)       // #3C4654

    // MARK: - Metrics & Geometry
    public static let radiusSmall: CGFloat = 8
    public static let radiusMedium: CGFloat = 14
    public static let radiusLarge: CGFloat = 20
    public static let radiusPill: CGFloat = 100

    public static let spacingTight: CGFloat = 6
    public static let spacingSmall: CGFloat = 10
    public static let spacingMedium: CGFloat = 16
    public static let spacingLarge: CGFloat = 24
    public static let spacingExtraLarge: CGFloat = 32

    // MARK: - Fluid Line Palette (Vibrant, Matte, Harmonized)
    public static func fluidColor(for type: FluidType) -> Color {
        switch type {
        case .coolant:
            return Color(red: 0/255, green: 229/255, blue: 229/255)  // Cyan
        case .fuel:
            return Color(red: 255/255, green: 138/255, blue: 36/255) // Warm Amber
        case .chemical:
            return Color(red: 74/255, green: 222/255, blue: 128/255) // Emerald Mint
        case .thermal:
            return Color(red: 244/255, green: 63/255, blue: 94/255)  // Coral Rose
        case .pressure:
            return Color(red: 168/255, green: 85/255, blue: 247/255) // Violet
        case .auxiliary:
            return Color(red: 59/255, green: 130/255, blue: 246/255) // Cobalt Blue
        case .plasma:
            return Color(red: 236/255, green: 72/255, blue: 153/255) // Pink Magenta
        case .steam:
            return Color(red: 226/255, green: 232/255, blue: 240/255)// Polar White
        }
    }

    public static func fluidGlowColor(for type: FluidType) -> Color {
        fluidColor(for: type).opacity(0.35)
    }

    // MARK: - Typography Presets
    public static func titleFont(size: CGFloat = 28, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    public static func headingFont(size: CGFloat = 18, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    public static func bodyFont(size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    public static func captionFont(size: CGFloat = 12, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    public static func monoFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    public static func statNumberFont(size: CGFloat = 20, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Reusable UI Modifiers & Styles

/// Clean pill button style with spring-scale tactile response.
public struct PipeworkPillButtonStyle: ButtonStyle {
    public enum Variant {
        case primary
        case secondary
        case subtle
        case destructive
    }

    public let variant: Variant
    public let isCompact: Bool

    public init(variant: Variant = .primary, isCompact: Bool = false) {
        self.variant = variant
        self.isCompact = isCompact
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PipeworkTheme.headingFont(size: isCompact ? 14 : 16, weight: .semibold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, isCompact ? 14 : 22)
            .padding(.vertical, isCompact ? 10 : 15)
            .frame(maxWidth: isCompact ? nil : .infinity)
            .background(backgroundView(isPressed: configuration.isPressed))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(borderStroke, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return Color(red: 8/255, green: 15/255, blue: 20/255)
        case .secondary:
            return PipeworkTheme.textMain
        case .subtle:
            return PipeworkTheme.textSecondary
        case .destructive:
            return PipeworkTheme.warningRed
        }
    }

    private func backgroundView(isPressed: Bool) -> some View {
        switch variant {
        case .primary:
            return AnyView(PipeworkTheme.primaryCyan)
        case .secondary:
            return AnyView(PipeworkTheme.surfaceSubtle)
        case .subtle:
            return AnyView(PipeworkTheme.bgElevated.opacity(isPressed ? 0.8 : 0.4))
        case .destructive:
            return AnyView(PipeworkTheme.warningRed.opacity(0.12))
        }
    }

    private var borderStroke: Color {
        switch variant {
        case .primary:
            return Color.clear
        case .secondary:
            return PipeworkTheme.borderDefault
        case .subtle:
            return PipeworkTheme.borderSubtle
        case .destructive:
            return PipeworkTheme.warningRed.opacity(0.3)
        }
    }
}

/// Tactile circular/pill icon button style.
public struct PipeworkIconButtonStyle: ButtonStyle {
    public let size: CGFloat
    public let isActive: Bool

    public init(size: CGFloat = 40, isActive: Bool = false) {
        self.size = size
        self.isActive = isActive
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(isActive ? PipeworkTheme.primaryCyan.opacity(0.15) : PipeworkTheme.bgElevated)
            )
            .overlay(
                Circle()
                    .stroke(isActive ? PipeworkTheme.primaryCyan.opacity(0.5) : PipeworkTheme.borderSubtle, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
