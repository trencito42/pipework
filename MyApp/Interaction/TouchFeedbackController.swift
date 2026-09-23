import Foundation
import CoreGraphics

/// Semantic interaction feedback events emitted by the gesture layer.
public enum InteractionFeedbackEvent: Sendable, Equatable {
    case terminalPickup
    case stepForward(GridCoord)
    case stepBackward(GridCoord)
    case blocked(GridCoord)
    case routeCut
    case lineConnected
    case boardCompleted
}

/// Central coordinator for tactile haptics, procedural sound, and blocked-state deduplication.
@MainActor
public final class TouchFeedbackController {
    public static let shared = TouchFeedbackController()

    public var onBlockedCoord: ((GridCoord) -> Void)?
    public private(set) var lastBlockedCoord: GridCoord? = nil

    public init() {}

    public func prepare() {
        HapticService.shared.prepareAll()
    }

    /// Handles a semantic interaction event and routes it to haptics, sound, and visual callbacks.
    public func handle(_ event: InteractionFeedbackEvent) {
        switch event {
        case .terminalPickup:
            lastBlockedCoord = nil
            HapticService.shared.terminalPickup()
            AudioService.shared.playTerminalGrab()

        case .stepForward:
            lastBlockedCoord = nil
            HapticService.shared.stepForward()

        case .stepBackward:
            lastBlockedCoord = nil
            HapticService.shared.stepBackward()

        case .blocked(let coord):
            // Deduplicate blocked events per encountered coordinate
            if lastBlockedCoord != coord {
                lastBlockedCoord = coord
                HapticService.shared.blocked()
                AudioService.shared.playBlocked()
                onBlockedCoord?(coord)
            }

        case .routeCut:
            lastBlockedCoord = nil
            HapticService.shared.routeCut()
            AudioService.shared.playRouteCut()

        case .lineConnected:
            lastBlockedCoord = nil
            HapticService.shared.lineConnected()
            AudioService.shared.playConnectionLocked()

        case .boardCompleted:
            lastBlockedCoord = nil
            HapticService.shared.boardCompleted()
            AudioService.shared.playPressureStabilized()
        }
    }

    public func resetStrokeState() {
        lastBlockedCoord = nil
    }
}
