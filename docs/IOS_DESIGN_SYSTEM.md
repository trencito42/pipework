# PIPEWORK — iOS Design System & Visual Specification

## 1. Aesthetic Foundations
- **Environment**: Dark graphite industrial diagnostic console with radial vignette (`#0F1318` to `#070809`).
- **Surface Construction**: Beveled matte graphite panels, chamfered corner bolts, recessed conduit trenches, and razor-sharp 1pt structural borders.
- **Lighting Model**: Ambient dark graphite environment illuminated strictly by vivid pressurized fluid lines and glowing terminal sockets.
- **Typography**: Industrial monospaced and technical sans-serif typefaces (`SF Pro Rounded` for titles, `SF Mono` for telemetry and HUD metrics).

---

## 2. Color Palette Tokens

| Token | Hex / sRGB | Purpose |
|---|---|---|
| `bgBase` | `#070809` | Root background edge color |
| `bgVignetteCenter` | `#0F1318` | Center radial background gradient highlight |
| `panelBase` | `#0D1014` | Board frame and HUD backplate container |
| `panelSubtle` | `#13171D` | Inset panels, button bases |
| `borderDim` | `#1F2630` | Structural 1pt panel dividers and board outline |
| `borderBright` | `#2D3744` | Highlighted borders, active controls |
| `gridLine` | `rgba(255, 255, 255, 0.035)` | Subtle orthogonal cell plate seams |
| `gridCellEmpty` | `#080A0D` | Base board void |
| `primaryCyan` | `#20E7E7` | Primary diagnostic accent, glow highlights, branding dot |
| `pressureGreen` | `#25D366` | 100% PRESSURE stabilized completion green |
| `textMain` | `#E6EDF5` | Primary readings, header titles, active values |
| `textMuted` | `#5E6B7C` | Field labels (LINES, MOVES, PRESSURE) |
| `textDim` | `#414B58` | Inactive/disabled icons and denominator slash |

### Fluid Line Colors

| Fluid | Hex Core | Hex Outer / Glow | Description |
|---|---|---|---|
| **Coolant** | `#20E7E7` | `rgba(32, 231, 231, 0.4)` | Cryogenic electric cyan |
| **Fuel** | `#FF7B1C` | `rgba(255, 123, 28, 0.4)` | Pressurized amber propellant |
| **Chemical** | `#84E02A` | `rgba(132, 224, 42, 0.4)` | Acid emerald solvent |
| **Compressed / Gas** | `#B358F6` | `rgba(179, 88, 246, 0.4)` | Hydraulic neon violet |
| **Emergency / Thermal** | `#FF3B30` | `rgba(255, 59, 48, 0.4)` | High-temperature emergency line |
| **Auxiliary** | `#3D7BFF` | `rgba(61, 123, 255, 0.4)` | Deep cobalt hydraulic line |
| **Plasma** | `#FF0088` | `rgba(255, 0, 136, 0.4)` | High-energy magenta |
| **Steam** | `#E2EAF3` | `rgba(226, 234, 243, 0.4)` | Titanium white vapor line |

---

## 3. Component & Geometry Architecture

### 3.1 Multi-Layer Hose Geometry
Hydraulic pipes are rendered as multi-pass vulcanized hoses with glowing fluid cores:
1. **Drop Shadow**: Soft ambient occlusion underneath (`#0E1216`, blur: 8pt, offset Y: 4pt).
2. **Reinforced Outer Casing**: Thick dark rubber casing (`#181E26`, width: 42% of cell size).
3. **Casing Edge Bevel**: Highlights (`#273240`, width: 36% of cell size).
4. **Recessed Core Bedding**: Dark trench (`#0A0D11`, width: 22% of cell size).
5. **Fluid Core Channel**: Glowing fluid color (`pair.color`, width: 18% of cell size).
6. **Specular Lumen Beam**: Core highlight (`white` at 70% opacity, width: 6% of cell size).
7. **Flowing Fluid Pulses**: When connected, high-luminance pulse packets travel along the pipe at constant linear velocity.
8. **Corner Fillet**: 90° bends are filleted with smooth rounded arcs (`cornerFilletRatio = 0.32 * cellSize`).

### 3.2 Machined Terminal Socket Geometry
1. **Outer Flange**: Machined metal ring (diameter: 76% of cell size) with metallic gradient (`#2E3947` to `#0E1216`) and beveled outer rim (`#3D4B5D`).
2. **Perimeter Rivets**: 6 mechanical flange bolts spaced at 60° increments around the outer collar.
3. **Recessed Cavity**: Dark inner chamber (diameter: 54% of cell size, radial gradient `#050709` to `#1B232C`).
4. **Fluid Well Port**: Glowing fluid core (diameter: 32% of cell size) with specular highlight in upper-left quadrant.
5. **Connected Lock Ring**: Radiant illuminated collar encircling the socket when line is complete.
6. **Interaction Pulse**: Spring scale pulse (1.12x) on touch and connection lock.

### 3.3 Board Frame & Corner Bolts
- **Outer Shell**: Deep graphite card (`#080A0D`) with 18pt corner radius and `1px solid #1C232D` border.
- **Corner Bolts**: 4 machined 8pt mechanical bolts at each corner of the board housing.
- **Cell Plates**: Subtle 1pt perimeter seams with tiny central alignment registration crosses.

### 3.4 HUD & Pressure Meter
- **Header**: Status LED dot (glowing cyan 6pt) + `PIPEWORK` in heavy tracking + Sector badge (`SECTOR 07`) + Sound mute toggle.
- **Status Panel**: 3-column tactical readout:
  1. `LINES`: Connected / Total (`0 / 5`) with muted denominator.
  2. `MOVES`: 2-digit zero-padded counter (`00`).
  3. `PRESSURE`: Numerical percentage (`0%` to `100%`) with integrated 4pt horizontal progress track (`#141A22` track, glowing cyan fill, transitioning to `#25D366` green at 100%).
- **Tactical Buttons**: 52×52pt circular metallic buttons (`Undo`, `Hint`, `Restart`) with beveled gradient and tactile press feedback.
- **Drag Elastic Tether**: While actively dragging, a subtle fluid tether connects the current cell nozzle to the touch coordinate.
- **Blocked Cell Feedback**: A localized crimson red shockwave ring indicates obstructed cells.

---

## 4. Animation Timings
- **Fluid Pulse Phase**: Continuous wave period (phase offset driven by `TimelineView` / display link).
- **Socket Spring Pulse**: 350ms spring response upon connection lock.
- **Pressure Bar Fill**: 350ms cubic ease-out.
- **Victory Cascading Surge**: 130ms staggered pulse cascade across all lines followed by completion modal transition.
- **Touch-Down Scaling**: 92% scale on button depression.
