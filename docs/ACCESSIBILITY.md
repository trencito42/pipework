# PIPEWORK — Accessibility Specification

## 1. Principles
PIPEWORK ensures that puzzle solving never relies purely on color perception alone. Every fluid conduit is identified by multiple distinct sensory dimensions.

---

## 2. Multi-Modal Line Identification
When **Accessibility Labels / Symbols Mode** is active (configurable in Settings, or automatically enabled when `UIAccessibility.isGrayscaleEnabled` or high-contrast is detected):
1. **Geometric Glyphs**:
   - Coolant: Circle `●` / `C`
   - Fuel: Triangle `▲` / `F`
   - Chemical: Diamond `◆` / `K`
   - Thermal: Square `■` / `T`
   - Pressure: Cross `✚` / `P`
   - Auxiliary: Star `★` / `A`
   - Plasma: Hexagon `⬡` / `M`
   - Steam: Wave `≈` / `S`
2. **Terminal Badge**: Rendered inside the terminal center port and along path milestones.

---

## 3. Motion & Display Support
- **Reduce Motion (`accessibilityReduceMotion`)**: Replaces fluid pulse scrolling and victory screen wave effects with static high-contrast illumination and standard crossfades.
- **Dynamic Type**: HUD labels and buttons scale dynamically using system font metrics.
- **VoiceOver**: Board cells are navigable with rotor announcements (e.g. *"Terminal: Coolant Alpha at Column 1, Row 1. Connected to Column 5, Row 1"*).
