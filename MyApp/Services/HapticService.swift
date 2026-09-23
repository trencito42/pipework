import UIKit

/// Manages tactile haptic feedback for game interactions.
@MainActor
public final class HapticService {
    public static let shared = HapticService()

    public var isEnabled: Bool = true

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        prepare()
    }

    public func prepare() {
        guard isEnabled else { return }
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
    }

    /// Feedback on starting or picking up a terminal.
    public func terminalTouchDown() {
        guard isEnabled else { return }
        lightImpact.impactOccurred(intensity: 0.6)
    }

    /// Feedback on step traversal.
    public func cellStep() {
        guard isEnabled else { return }
        // Very subtle or silent by default to prevent fatigue
    }

    /// Feedback on severing/cutting an intersecting line.
    public func lineCut() {
        guard isEnabled else { return }
        mediumImpact.impactOccurred(intensity: 0.8)
    }

    /// Feedback on completing a line between both terminals.
    public func lineConnected() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    /// Feedback on solving the board (100% PRESSURE).
    public func boardCompleted() {
        guard isEnabled else { return }
        heavyImpact.impactOccurred(intensity: 1.0)
    }
}
