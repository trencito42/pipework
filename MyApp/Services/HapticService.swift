import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Manages tactile haptic feedback for game interactions across Apple platforms.
@MainActor
public final class HapticService {
    public static let shared = HapticService()

    public var isEnabled: Bool = true

    #if canImport(UIKit) && !os(watchOS)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    #endif

    private init() {
        prepare()
    }

    public func prepare() {
        guard isEnabled else { return }
        #if canImport(UIKit) && !os(watchOS)
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
        #endif
    }

    /// Feedback on starting or picking up a terminal.
    public func terminalTouchDown() {
        guard isEnabled else { return }
        #if canImport(UIKit) && !os(watchOS)
        lightImpact.impactOccurred(intensity: 0.6)
        #endif
    }

    /// Feedback on step traversal.
    public func cellStep() {
        guard isEnabled else { return }
        // Kept subtle to prevent fatigue during continuous drags
    }

    /// Feedback on severing/cutting an intersecting line.
    public func lineCut() {
        guard isEnabled else { return }
        #if canImport(UIKit) && !os(watchOS)
        mediumImpact.impactOccurred(intensity: 0.8)
        #endif
    }

    /// Feedback on completing a line between both terminals.
    public func lineConnected() {
        guard isEnabled else { return }
        #if canImport(UIKit) && !os(watchOS)
        notification.notificationOccurred(.success)
        #endif
    }

    /// Feedback on solving the board (100% PRESSURE).
    public func boardCompleted() {
        guard isEnabled else { return }
        #if canImport(UIKit) && !os(watchOS)
        heavyImpact.impactOccurred(intensity: 1.0)
        #endif
    }
}
