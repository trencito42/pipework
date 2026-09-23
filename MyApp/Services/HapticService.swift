import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif
#if canImport(CoreHaptics) && !os(watchOS)
import CoreHaptics
#endif

/// Production-grade tactile and haptic feedback service for PIPEWORK.
/// Utilizes Core Haptics (`CHHapticEngine`) for high-fidelity micro-detents and patterns,
/// with robust fallback to UIKit impact feedback generators.
@MainActor
public final class HapticService {
    public static let shared = HapticService()

    public var isEnabled: Bool {
        PersistenceService.shared.profile.hapticsEnabled
    }

    #if canImport(CoreHaptics) && !os(watchOS)
    private var hapticEngine: CHHapticEngine?
    private var isCoreHapticsSupported: Bool = false
    #endif

    #if canImport(UIKit) && !os(watchOS)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    #endif

    // Micro-step throttle tracking (~28ms throttle)
    private var lastMicroStepTime: TimeInterval = 0
    private let microStepThrottleInterval: TimeInterval = 0.028

    private init() {
        #if canImport(CoreHaptics) && !os(watchOS)
        setupCoreHaptics()
        #endif
        prepareAll()
    }

    #if canImport(CoreHaptics) && !os(watchOS)
    private func setupCoreHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            isCoreHapticsSupported = false
            return
        }

        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak self] in
                Task { @MainActor in
                    try? self?.hapticEngine?.start()
                }
            }
            engine.stoppedHandler = { reason in
                // Engine stopped
            }
            try engine.start()
            self.hapticEngine = engine
            self.isCoreHapticsSupported = true
        } catch {
            self.isCoreHapticsSupported = false
        }
    }
    #endif

    public func prepareAll() {
        #if canImport(UIKit) && !os(watchOS)
        lightImpact.prepare()
        mediumImpact.prepare()
        softImpact.prepare()
        rigidImpact.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
        #endif
    }

    // MARK: - Semantic Haptic Vocabulary

    /// 1. Terminal Pick-up: Crisp, precise grab detent.
    public func terminalPickup() {
        guard isEnabled else { return }
        #if canImport(CoreHaptics) && !os(watchOS)
        if isCoreHapticsSupported, playTransient(intensity: 0.35, sharpness: 0.8) {
            return
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        lightImpact.impactOccurred(intensity: 0.5)
        #endif
    }

    /// 2. Forward Grid Step: Micro-detent (rate-limited).
    public func stepForward() {
        guard isEnabled else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastMicroStepTime >= microStepThrottleInterval else { return }
        lastMicroStepTime = now

        #if canImport(CoreHaptics) && !os(watchOS)
        if isCoreHapticsSupported, playTransient(intensity: 0.12, sharpness: 0.95) {
            return
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        softImpact.impactOccurred(intensity: 0.25)
        #endif
    }

    /// 3. Backtrack Step: Softer micro-detent (rate-limited).
    public func stepBackward() {
        guard isEnabled else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastMicroStepTime >= microStepThrottleInterval else { return }
        lastMicroStepTime = now

        #if canImport(CoreHaptics) && !os(watchOS)
        if isCoreHapticsSupported, playTransient(intensity: 0.08, sharpness: 0.35) {
            return
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        softImpact.impactOccurred(intensity: 0.15)
        #endif
    }

    /// 4. Blocked Step: Sharp, tactile notch indicating blocked boundary/enemy.
    public func blocked() {
        guard isEnabled else { return }
        #if canImport(CoreHaptics) && !os(watchOS)
        if isCoreHapticsSupported, playTransient(intensity: 0.55, sharpness: 0.9) {
            return
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        rigidImpact.impactOccurred(intensity: 0.6)
        #endif
    }

    /// 5. Route Cut: Crisp double-notch indicating severing of an existing line.
    public func routeCut() {
        guard isEnabled else { return }
        #if canImport(CoreHaptics) && !os(watchOS)
        if isCoreHapticsSupported {
            let event1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0
            )
            let event2 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85)
                ],
                relativeTime: 0.04
            )
            if playPattern(events: [event1, event2]) { return }
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        mediumImpact.impactOccurred(intensity: 0.7)
        #endif
    }

    /// 6. Line Connected: Solid, resonant lock pulse when reaching destination terminal.
    public func lineConnected() {
        guard isEnabled else { return }
        #if canImport(CoreHaptics) && !os(watchOS)
        if isCoreHapticsSupported {
            let event1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0
            )
            let event2 = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.03,
                duration: 0.08
            )
            if playPattern(events: [event1, event2]) { return }
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        heavyImpact.impactOccurred(intensity: 0.8)
        #endif
    }

    /// 7. Board Completed: Multi-stage celebratory crescendo pulse sequence.
    public func boardCompleted() {
        guard isEnabled else { return }
        #if canImport(CoreHaptics) && !os(watchOS)
        if isCoreHapticsSupported {
            var events: [CHHapticEvent] = []
            let timings: [(TimeInterval, Float, Float)] = [
                (0.00, 0.4, 0.5),
                (0.08, 0.6, 0.7),
                (0.18, 0.9, 0.8),
                (0.30, 1.0, 0.9)
            ]
            for (time, intensity, sharpness) in timings {
                events.append(
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                        ],
                        relativeTime: time
                    )
                )
            }
            if playPattern(events: events) { return }
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        notificationFeedback.notificationOccurred(.success)
        #endif
    }

    /// 8. Undo Action: Subtle backward tap.
    public func undo() {
        guard isEnabled else { return }
        #if canImport(CoreHaptics) && !os(watchOS)
        if isCoreHapticsSupported, playTransient(intensity: 0.22, sharpness: 0.4) {
            return
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        lightImpact.impactOccurred(intensity: 0.4)
        #endif
    }

    /// 9. Button Tap / UI Action: Standard tactile click.
    public func buttonTap() {
        guard isEnabled else { return }
        #if canImport(CoreHaptics) && !os(watchOS)
        if isCoreHapticsSupported, playTransient(intensity: 0.18, sharpness: 0.6) {
            return
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        selectionFeedback.selectionChanged()
        #endif
    }

    /// 10. Restart Level: Double reset pulse.
    public func restart() {
        guard isEnabled else { return }
        #if canImport(CoreHaptics) && !os(watchOS)
        if isCoreHapticsSupported {
            let event1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            )
            let event2 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0.08
            )
            if playPattern(events: [event1, event2]) { return }
        }
        #endif
        #if canImport(UIKit) && !os(watchOS)
        mediumImpact.impactOccurred(intensity: 0.6)
        #endif
    }

    // MARK: - Core Haptics Helpers

    #if canImport(CoreHaptics) && !os(watchOS)
    private func playTransient(intensity: Float, sharpness: Float) -> Bool {
        guard hapticEngine != nil else { return false }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )
        return playPattern(events: [event])
    }

    private func playPattern(events: [CHHapticEvent]) -> Bool {
        guard let engine = hapticEngine else { return false }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            return true
        } catch {
            return false
        }
    }
    #endif
}
