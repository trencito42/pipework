# PIPEWORK — Audio & Haptics Specification

## 1. Tactile & Haptic Architecture
PIPEWORK utilizes a dedicated `CHHapticEngine` (Core Haptics) subsystem backed by `UIImpactFeedbackGenerator` fallback on legacy or non-supported devices. All feedback is centrally coordinated through `TouchFeedbackController` to guarantee rate limiting, coordinate de-duplication, and zero sensory fatigue.

### Core Haptics Vocabulary & Parameter Curves

| Event | Primary Technology | Intensity / Sharpness / Relative Timing | Semantic Character |
|---|---|---|---|
| **Terminal Pickup** | Core Haptics Transient | Intensity: `0.35`, Sharpness: `0.80` | Crisp, precise mechanical socket grab |
| **Grid Step Forward** | Core Haptics Transient (Rate Limited) | Intensity: `0.12`, Sharpness: `0.95` (28ms throttle) | Ultra-light micro-detent |
| **Grid Step Backtrack** | Core Haptics Transient (Rate Limited) | Intensity: `0.08`, Sharpness: `0.35` (28ms throttle) | Softer velvet detent |
| **Blocked Obstacle** | Core Haptics Transient (Deduplicated) | Intensity: `0.55`, Sharpness: `0.90` (per-cell dedupe) | Rigid tactile boundary notch |
| **Route Cut (Severance)** | Core Haptics Double Pulse | P1: `0.40`/`0.70` (t=0), P2: `0.60`/`0.85` (t=40ms) | Crisp mechanical snap severance |
| **Terminal Lock (Connection)** | Transient + Continuous Pulse | P1: `0.70`/`0.60` (t=0), P2 Cont: `0.40`/`0.30` (t=30ms, 80ms dur) | Heavy resonant magnetic lock |
| **Level Complete (100% PRESSURE)**| 4-Pulse Crescendo | P1: `0.4`/`0.5` (t=0), P2: `0.6`/`0.7` (t=80ms), P3: `0.9`/`0.8` (t=180ms), P4: `1.0`/`0.9` (t=300ms) | Ascending celebratory tactile flourish |
| **Undo Action** | Core Haptics Transient | Intensity: `0.22`, Sharpness: `0.40` | Subtle reverse tap |
| **Button / UI Tap** | Core Haptics Transient | Intensity: `0.18`, Sharpness: `0.60` | Clean industrial micro-click |
| **Level Restart** | Core Haptics Double Pulse | P1: `0.3`/`0.5` (t=0), P2: `0.5`/`0.7` (t=80ms) | Disengagement double pulse |

### Rate Limiting & Sensory De-duplication
- **Step Rate Limiting**: Forward and backward micro-steps are throttled to a minimum interval of 28ms (`0.028s`) to preserve 120Hz tracking fidelity while avoiding continuous vibration fatigue during rapid swipes.
- **Blocked State De-duplication**: Repeated touch events lingering on the same blocked boundary coordinate are deduplicated by `TouchFeedbackController.lastBlockedCoord`, firing the haptic and sound effect exactly once per unique blocked cell encounter until the player redirects the stroke.

---

## 2. Audio Feedback
The current implementation uses lightweight `AudioToolbox` system sounds. They provide immediate semantic coverage but are not final bespoke assets; custom recorded/synthesized industrial samples remain a physical-device polish task.

| Action | Audio Trigger | Sound Character |
|---|---|---|
| **Terminal Grab** | `AudioService.shared.playTerminalGrab()` | Mechanical socket tink |
| **Line Completed** | `AudioService.shared.playConnectionLocked()` | Submarine resonant lock tone |
| **Route Cut** | `AudioService.shared.playRouteCut()` | Sharp pneumatic release click |
| **Blocked Obstacle** | `AudioService.shared.playBlocked()` | Short alert warning click |
| **Undo Move** | `AudioService.shared.playUndo()` | Muted reverse mechanical click |
| **Restart Level** | `AudioService.shared.playRestart()` | Disengage relief click |
| **100% Pressure Complete** | `AudioService.shared.playPressureStabilized()` | Deep resonant power chime |

- **Instant Toggle**: When sound is toggled in Settings, `PersistenceService` immediately persists the change and `AudioService` respects `soundEnabled` synchronously on every subsequent action.
