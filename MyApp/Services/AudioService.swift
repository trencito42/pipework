import Foundation
import AudioToolbox

/// Manages lightweight procedural audio feedback for PIPEWORK.
@MainActor
public final class AudioService {
    public static let shared = AudioService()

    public var isEnabled: Bool {
        PersistenceService.shared.profile.soundEnabled
    }

    private init() {}

    /// Played when grabbing a terminal or pipe head.
    public func playTerminalGrab() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1104) // Tink sound
    }

    /// Played when completing a line connection.
    public func playConnectionLocked() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1054) // Submarine lock tone
    }

    /// Played when cutting a route.
    public func playRouteCut() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1052) // Empty popup click
    }

    /// Played when hitting a blocked obstacle (enemy terminal, etc).
    public func playBlocked() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1053) // Short alert click
    }

    /// Played when undoing a move.
    public func playUndo() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1105) // Subtle back click
    }

    /// Played when resetting/restarting a level.
    public func playRestart() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1052) // Disengage click
    }

    /// Played when puzzle is solved at 100% PRESSURE.
    public func playPressureStabilized() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1025) // Resonant success chime
    }
}
