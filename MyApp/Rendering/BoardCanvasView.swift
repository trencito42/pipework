import SwiftUI
import Combine

/// High-performance Canvas renderer recreating the tactile industrial look of PIPEWORK.
public struct BoardCanvasView: View {
    @Binding public var state: PuzzleState
    @Binding public var history: MoveHistory
    public let showAccessibilitySymbols: Bool
    public let reduceMotion: Bool
    public let onStrokeCommitted: (StrokeCommitResult) -> Void

    @State private var dragPointerLocation: CGPoint? = nil
    @State private var localBlockedCoord: GridCoord? = nil
    @State private var blockedTask: Task<Void, Never>? = nil
    @StateObject private var gestureController = BoardGestureController()

    public init(
        state: Binding<PuzzleState>,
        history: Binding<MoveHistory>,
        showAccessibilitySymbols: Bool = false,
        reduceMotion: Bool = false,
        onStrokeCommitted: @escaping (StrokeCommitResult) -> Void = { _ in }
    ) {
        self._state = state
        self._history = history
        self.showAccessibilitySymbols = showAccessibilitySymbols
        self.reduceMotion = reduceMotion
        self.onStrokeCommitted = onStrokeCommitted
    }

    public var body: some View {
        let hasFlowingFluid = state.connectedLineCount > 0 && !reduceMotion
        let isInteracting = dragPointerLocation != nil || localBlockedCoord != nil
        let interval: Double = reduceMotion ? 1.0 : ((hasFlowingFluid || isInteracting) ? (1.0 / 60.0) : (1.0 / 15.0))

        TimelineView(.animation(minimumInterval: interval)) { timeline in
            let timeInterval = reduceMotion ? 0.0 : timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let geometry = BoardGeometry(
                    gridSize: state.gridSize,
                    containerSize: proxy.size,
                    margin: 8
                )

                ZStack {
                    Canvas { context, _ in
                        drawBoardShell(context: context, geometry: geometry)
                        drawGridPlates(context: context, geometry: geometry)
                        drawHoses(context: context, geometry: geometry, time: timeInterval)
                        drawActiveDragNozzle(context: context, geometry: geometry)
                        drawSockets(context: context, geometry: geometry)
                        drawBlockedFeedback(context: context, geometry: geometry)
                    }

                    #if canImport(UIKit) && !os(watchOS)
                    TouchTrackingView(
                        onTouchBegan: { point in
                            dragPointerLocation = point
                            gestureController.interpreter.beginStroke(
                                at: point,
                                geometry: geometry,
                                state: &state,
                                history: &history
                            )
                        },
                        onTouchMoved: { point in
                            dragPointerLocation = point
                            gestureController.interpreter.continueStroke(
                                to: point,
                                geometry: geometry,
                                state: &state
                            )
                        },
                        onTouchEnded: { point in
                            dragPointerLocation = nil
                            let result = gestureController.interpreter.endStroke(
                                at: point,
                                geometry: geometry,
                                state: &state,
                                history: &history
                            )
                            onStrokeCommitted(result)
                        },
                        onTouchCancelled: {
                            dragPointerLocation = nil
                            gestureController.interpreter.cancelStroke(
                                state: &state,
                                history: &history
                            )
                        },
                        onPredictedTouchMoved: { predPoint in
                            // Update visual drag nozzle position only (does NOT affect puzzle state)
                            dragPointerLocation = predPoint
                        }
                    )
                    #else
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged { value in
                                    dragPointerLocation = value.location
                                    if !gestureController.isDragging {
                                        gestureController.isDragging = true
                                        gestureController.interpreter.beginStroke(
                                            at: value.startLocation,
                                            geometry: geometry,
                                            state: &state,
                                            history: &history
                                        )
                                    } else {
                                        gestureController.interpreter.continueStroke(
                                            to: value.location,
                                            geometry: geometry,
                                            state: &state
                                        )
                                    }
                                }
                                .onEnded { value in
                                    dragPointerLocation = nil
                                    gestureController.isDragging = false
                                    let result = gestureController.interpreter.endStroke(
                                        at: value.location,
                                        geometry: geometry,
                                        state: &state,
                                        history: &history
                                    )
                                    onStrokeCommitted(result)
                                }
                        )
                    #endif
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .onAppear {
                    gestureController.interpreter.feedbackController.onBlockedCoord = { coord in
                        triggerBlockedVisual(at: coord)
                    }
                }
            }
        }
    }

    private func triggerBlockedVisual(at coord: GridCoord) {
        blockedTask?.cancel()
        localBlockedCoord = coord
        blockedTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 260_000_000)
            if localBlockedCoord == coord {
                localBlockedCoord = nil
            }
        }
    }

    // MARK: - 1. Board Shell & Corner Mechanical Bolts

    private func drawBoardShell(context: GraphicsContext, geometry: BoardGeometry) {
        let rect = geometry.boardRect
        let shellPath = Path(roundedRect: rect, cornerRadius: 18)

        // Base plate fill
        context.fill(shellPath, with: .color(PipeworkTheme.gridCellEmpty))
        // 1.5pt Structural border
        context.stroke(shellPath, with: .color(PipeworkTheme.borderDim), lineWidth: 1.5)

        // 4 Corner Mechanical Bolts
        let boltDiameter: CGFloat = 8
        let boltMargin: CGFloat = 8
        let corners: [CGPoint] = [
            CGPoint(x: rect.minX + boltMargin, y: rect.minY + boltMargin),
            CGPoint(x: rect.maxX - boltMargin, y: rect.minY + boltMargin),
            CGPoint(x: rect.minX + boltMargin, y: rect.maxY - boltMargin),
            CGPoint(x: rect.maxX - boltMargin, y: rect.maxY - boltMargin)
        ]

        for corner in corners {
            let boltRect = CGRect(
                x: corner.x - boltDiameter / 2,
                y: corner.y - boltDiameter / 2,
                width: boltDiameter,
                height: boltDiameter
            )
            let boltPath = Path(ellipseIn: boltRect)
            context.fill(boltPath, with: .color(Color(red: 25/255, green: 32/255, blue: 42/255)))
            context.stroke(boltPath, with: .color(Color(red: 40/255, green: 50/255, blue: 66/255)), lineWidth: 1)
        }
    }

    // MARK: - 2. Grid Plates & Registration Ticks

    private func drawGridPlates(context: GraphicsContext, geometry: BoardGeometry) {
        for y in 0..<geometry.gridSize.height {
            for x in 0..<geometry.gridSize.width {
                let coord = GridCoord(x: x, y: y)
                let cellRect = geometry.cellRect(for: coord)

                let seamRect = cellRect.insetBy(dx: 1, dy: 1)
                context.stroke(
                    Path(seamRect),
                    with: .color(PipeworkTheme.gridLine),
                    lineWidth: 1
                )

                let center = geometry.center(for: coord)
                let tickRect = CGRect(x: center.x - 1, y: center.y - 1, width: 2, height: 2)
                context.fill(Path(tickRect), with: .color(Color(white: 1.0, opacity: 0.07)))
            }
        }
    }

    // MARK: - 3. Multi-Layer Vulcanized Hoses & Fluid Cores

    private func drawHoses(context: GraphicsContext, geometry: BoardGeometry, time: TimeInterval) {
        let cs = geometry.cellSize
        let outerWidth = cs * 0.42
        let bevelWidth = cs * 0.36
        let trenchWidth = cs * 0.22
        let fluidWidth = cs * 0.18
        let specularWidth = max(2.0, fluidWidth * 0.35)

        for (_, pathModel) in state.paths {
            guard pathModel.coordinates.count >= 2 else { continue }
            let isConnected = pathModel.isConnected
            let fluidColor = PipeworkTheme.fluidColor(for: pathModel.fluidType)
            let path = buildContinuousPath(coordinates: pathModel.coordinates, geometry: geometry)

            // 1. Hydraulic Drop Shadow
            context.stroke(
                path,
                with: .color(Color.black.opacity(0.7)),
                style: StrokeStyle(lineWidth: outerWidth + 4, lineCap: .round, lineJoin: .round)
            )

            // 2. Thick Vulcanized Outer Casing (#181E26)
            context.stroke(
                path,
                with: .color(Color(red: 24/255, green: 30/255, blue: 38/255)),
                style: StrokeStyle(lineWidth: outerWidth, lineCap: .round, lineJoin: .round)
            )

            // 3. Outer Casing Edge Bevel (#273240)
            context.stroke(
                path,
                with: .color(Color(red: 39/255, green: 50/255, blue: 64/255)),
                style: StrokeStyle(lineWidth: bevelWidth, lineCap: .round, lineJoin: .round)
            )

            // 4. Dark Core Bedding / Recessed Trench (#0A0D11)
            context.stroke(
                path,
                with: .color(Color(red: 10/255, green: 13/255, blue: 17/255)),
                style: StrokeStyle(lineWidth: trenchWidth, lineCap: .round, lineJoin: .round)
            )

            // 5. Glowing Fluid Core Channel
            let glowColor = fluidColor.opacity(isConnected ? 0.95 : 0.8)
            context.stroke(
                path,
                with: .color(glowColor),
                style: StrokeStyle(lineWidth: fluidWidth, lineCap: .round, lineJoin: .round)
            )

            // 6. Luminous Specular Highlight Beam
            context.stroke(
                path,
                with: .color(Color.white.opacity(isConnected ? 0.8 : 0.6)),
                style: StrokeStyle(lineWidth: specularWidth, lineCap: .round, lineJoin: .round)
            )

            // 7. Animated Fluid Pulses (when line is connected and reduceMotion is false)
            if isConnected && !reduceMotion {
                let speed: CGFloat = 65.0
                let cycleLength: CGFloat = cs * 1.6
                let dashOffset = CGFloat(time * speed).truncatingRemainder(dividingBy: cycleLength)

                let pulseStyle = StrokeStyle(
                    lineWidth: fluidWidth * 0.6,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: [cs * 0.35, cs * 0.65],
                    dashPhase: -dashOffset
                )
                context.stroke(
                    path,
                    with: .color(Color.white.opacity(0.85)),
                    style: pulseStyle
                )
            }
        }
    }

    // MARK: - 4. Active Dragging Nozzle & Elastic Tether

    private func drawActiveDragNozzle(context: GraphicsContext, geometry: BoardGeometry) {
        guard let activeLineId = state.activeLineId,
              let activePath = state.paths[activeLineId],
              let headCoord = activePath.head,
              !activePath.isConnected else { return }

        let cs = geometry.cellSize
        let headCenter = geometry.center(for: headCoord)
        let fluidColor = PipeworkTheme.fluidColor(for: activePath.fluidType)

        let nozzleRadius = cs * 0.32
        let nozzleRect = CGRect(
            x: headCenter.x - nozzleRadius,
            y: headCenter.y - nozzleRadius,
            width: nozzleRadius * 2,
            height: nozzleRadius * 2
        )
        context.stroke(
            Path(ellipseIn: nozzleRect),
            with: .color(fluidColor),
            lineWidth: 2.5
        )

        if let pointer = dragPointerLocation {
            let dx = pointer.x - headCenter.x
            let dy = pointer.y - headCenter.y
            let dist = hypot(dx, dy)
            let maxTether = cs * 0.45
            let factor = dist > 0 ? min(1.0, maxTether / dist) : 0

            var tetherPath = Path()
            tetherPath.move(to: headCenter)
            tetherPath.addLine(to: CGPoint(x: headCenter.x + dx * factor, y: headCenter.y + dy * factor))

            context.stroke(
                tetherPath,
                with: .color(fluidColor.opacity(0.7)),
                style: StrokeStyle(lineWidth: cs * 0.12, lineCap: .round)
            )
        }
    }

    // MARK: - 5. Machined Metal Terminal Sockets

    private func drawSockets(context: GraphicsContext, geometry: BoardGeometry) {
        let cs = geometry.cellSize
        let outerR = cs * 0.38
        let cavityR = cs * 0.27
        let coreR = cs * 0.16

        for terminal in state.terminals {
            let center = geometry.center(for: terminal.coord)
            let fluidColor = PipeworkTheme.fluidColor(for: terminal.fluidType)
            let isConnected = state.paths[terminal.lineId]?.isConnected ?? false
            let isCurrentActive = state.activeLineId == terminal.lineId

            let shadowRect = CGRect(x: center.x - outerR, y: center.y - outerR + 2, width: outerR * 2, height: outerR * 2)
            context.fill(Path(ellipseIn: shadowRect), with: .color(Color.black.opacity(0.6)))

            let outerRect = CGRect(x: center.x - outerR, y: center.y - outerR, width: outerR * 2, height: outerR * 2)
            let flangePath = Path(ellipseIn: outerRect)
            let flangeGradient = Gradient(colors: [
                Color(red: 46/255, green: 57/255, blue: 71/255),
                Color(red: 23/255, green: 29/255, blue: 36/255),
                Color(red: 14/255, green: 18/255, blue: 22/255)
            ])
            context.fill(
                flangePath,
                with: .linearGradient(flangeGradient, startPoint: CGPoint(x: outerRect.minX, y: outerRect.minY), endPoint: CGPoint(x: outerRect.maxX, y: outerRect.maxY))
            )
            context.stroke(flangePath, with: .color(Color(red: 61/255, green: 75/255, blue: 93/255)), lineWidth: 1.5)

            let boltCount = 6
            let boltRadius = max(1.2, cs * 0.024)
            for i in 0..<boltCount {
                let angle = (Double(i) / Double(boltCount)) * 2 * .pi
                let br = outerR * 0.8
                let bx = center.x + CGFloat(cos(angle)) * br
                let by = center.y + CGFloat(sin(angle)) * br
                let bRect = CGRect(x: bx - boltRadius, y: by - boltRadius, width: boltRadius * 2, height: boltRadius * 2)
                context.fill(Path(ellipseIn: bRect), with: .color(Color(red: 9/255, green: 12/255, blue: 15/255)))
                context.stroke(Path(ellipseIn: bRect), with: .color(Color(red: 74/255, green: 89/255, blue: 110/255)), lineWidth: 0.8)
            }

            let cavityRect = CGRect(x: center.x - cavityR, y: center.y - cavityR, width: cavityR * 2, height: cavityR * 2)
            let cavityPath = Path(ellipseIn: cavityRect)
            context.fill(cavityPath, with: .color(Color(red: 8/255, green: 11/255, blue: 15/255)))
            context.stroke(cavityPath, with: .color(Color(red: 5/255, green: 7/255, blue: 10/255)), lineWidth: 2)

            let coreRect = CGRect(x: center.x - coreR, y: center.y - coreR, width: coreR * 2, height: coreR * 2)
            let corePath = Path(ellipseIn: coreRect)
            context.fill(corePath, with: .color(fluidColor))

            let specR = coreR * 0.38
            let specRect = CGRect(x: center.x - coreR * 0.45, y: center.y - coreR * 0.45, width: specR, height: specR)
            context.fill(Path(ellipseIn: specRect), with: .color(Color.white.opacity(0.8)))

            if isConnected || isCurrentActive {
                let lockRingRect = CGRect(x: center.x - cavityR - 1.5, y: center.y - cavityR - 1.5, width: (cavityR + 1.5) * 2, height: (cavityR + 1.5) * 2)
                context.stroke(Path(ellipseIn: lockRingRect), with: .color(fluidColor), lineWidth: 2)
            }

            if showAccessibilitySymbols {
                let symbol = terminal.fluidType.symbolCode
                let text = Text(symbol)
                    .font(PipeworkTheme.monoFont(size: cs * 0.22, weight: .bold))
                    .foregroundColor(Color.black)
                context.draw(text, at: center)
            }
        }
    }

    // MARK: - 6. Blocked Feedback Shockwave

    private func drawBlockedFeedback(context: GraphicsContext, geometry: BoardGeometry) {
        guard let blocked = localBlockedCoord else { return }
        let center = geometry.center(for: blocked)
        let cs = geometry.cellSize

        let circlePath = Path(ellipseIn: CGRect(x: center.x - cs * 0.44, y: center.y - cs * 0.44, width: cs * 0.88, height: cs * 0.88))
        context.fill(circlePath, with: .color(PipeworkTheme.warningRed.opacity(0.35)))
        context.stroke(circlePath, with: .color(PipeworkTheme.warningRed), lineWidth: 2)
    }

    private func buildContinuousPath(coordinates: [GridCoord], geometry: BoardGeometry) -> Path {
        var path = Path()
        guard coordinates.count >= 2 else { return path }

        let p0 = geometry.center(for: coordinates[0])
        path.move(to: p0)

        for i in 1..<coordinates.count {
            let pt = geometry.center(for: coordinates[i])
            path.addLine(to: pt)
        }
        return path
    }
}

/// Stable gesture controller across SwiftUI render passes.
@MainActor
public final class BoardGestureController: ObservableObject {
    public let interpreter = GridGestureInterpreter()
    public var isDragging: Bool = false

    public init() {}
}
