# PIPEWORK — Audio & Haptics Specification

## 1. Haptic Feedback Design
Haptic patterns are subtle, crisp, and tactile. They must never fatigue the user's hand during continuous drawing.

| Event | Feedback Generator | Style / Parameters |
|---|---|---|
| **Terminal Touchdown** | `UIImpactFeedbackGenerator(style: .light)` | Light mechanical click (intensity 0.5) |
| **Grid Cell Step** | *None by default* | Silent to avoid continuous vibration fatigue |
| **Route Cut / Collision** | `UIImpactFeedbackGenerator(style: .medium)` | Sharp crisp snap |
| **Terminal Lock (Pair Complete)** | `UINotificationFeedbackGenerator` | `.success` or rigid crisp snap |
| **Backtrack Step** | `UIImpactFeedbackGenerator(style: .soft)` | Very soft step (intensity 0.3) |
| **Board Solved (100% PRESSURE)** | Custom Success Pattern | Heavy impact followed by double soft resonant pulses |

---

## 2. Audio Design
- All sound effects are minimalist, industrial, and synthesized or high-fidelity recordings of mechanical relays, fluid valves, and resonant chambers.
- **Audio Channels**:
  - `click_terminal_down.wav`: Crisp metallic click.
  - `pipe_flow_hum.wav`: Subtle fluid rush upon connection.
  - `pipe_sever.wav`: Pneumatic pressure release click.
  - `puzzle_complete_surge.wav`: Resonant power surge chord with deep bass bloom.
- Game is fully playable with sound disabled; user preferences are observed instantly.
