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
        let shouldAnimate = !reduceMotion && (hasFlowingFluid || isInteracting)

        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !shouldAnimate)) { timeline in
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
                        drawCouplings(context: context, geometry: geometry)
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

        context.drawLayer { layer in
            layer.addFilter(.shadow(color: .black.opacity(0.82), radius: 12, x: 0, y: 7))
            layer.fill(shellPath, with: .color(Color(red: 5/255, green: 8/255, blue: 11/255)))
        }
        context.fill(
            shellPath,
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 19/255, green: 27/255, blue: 35/255),
                    Color(red: 8/255, green: 11/255, blue: 15/255),
                    Color(red: 4/255, green: 6/255, blue: 9/255)
                ]),
                startPoint: CGPoint(x: rect.minX, y: rect.minY),
                endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
            )
        )
        context.stroke(shellPath, with: .color(Color(red: 45/255, green: 61/255, blue: 75/255)), lineWidth: 1.5)
        context.stroke(
            Path(roundedRect: rect.insetBy(dx: 3, dy: 3), cornerRadius: 15),
            with: .color(Color(red: 103/255, green: 139/255, blue: 158/255).opacity(0.16)),
            lineWidth: 1
        )

        // 4 Corner Mechanical Bolts
        let boltDiameter = max(6, geometry.cellSize * 0.12)
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
            context.fill(
                boltPath,
                with: .linearGradient(
                    Gradient(colors: [Color(red: 93/255, green: 110/255, blue: 128/255), Color(red: 15/255, green: 20/255, blue: 27/255)]),
                    startPoint: CGPoint(x: boltRect.minX, y: boltRect.minY),
                    endPoint: CGPoint(x: boltRect.maxX, y: boltRect.maxY)
                )
            )
            context.stroke(boltPath, with: .color(Color.black.opacity(0.75)), lineWidth: 1)
            var slot = Path()
            slot.move(to: CGPoint(x: corner.x - boltDiameter * 0.22, y: corner.y))
            slot.addLine(to: CGPoint(x: corner.x + boltDiameter * 0.22, y: corner.y))
            context.stroke(slot, with: .color(Color.black.opacity(0.65)), lineWidth: 0.8)
        }
    }

    // MARK: - 2. Grid Plates & Registration Ticks

    private func drawGridPlates(context: GraphicsContext, geometry: BoardGeometry) {
        for y in 0..<geometry.gridSize.height {
            for x in 0..<geometry.gridSize.width {
                let coord = GridCoord(x: x, y: y)
                let cellRect = geometry.cellRect(for: coord)

                let seamRect = cellRect.insetBy(dx: 1.2, dy: 1.2)
                context.fill(Path(seamRect), with: .color(Color.white.opacity(0.008)))
                context.stroke(Path(seamRect), with: .color(Color(red: 77/255, green: 102/255, blue: 120/255).opacity(0.075)), lineWidth: 0.8)

                let center = geometry.center(for: coord)
                let tickSize = max(1.4, geometry.cellSize * 0.025)
                let tickRect = CGRect(x: center.x - tickSize / 2, y: center.y - tickSize / 2, width: tickSize, height: tickSize)
                context.fill(Path(ellipseIn: tickRect), with: .color(Color(red: 103/255, green: 140/255, blue: 160/255).opacity(0.13)))
            }
        }
    }

    // MARK: - 3. Multi-Layer Vulcanized Hoses & Fluid Cores

    private func drawHoses(context: GraphicsContext, geometry: BoardGeometry, time: TimeInterval) {
        let cs = geometry.cellSize
        let outerWidth = cs * 0.40
        let shellShoulderWidth = cs * 0.345
        let shellLightWidth = cs * 0.30
        let trenchWidth = cs * 0.255
        let fluidEdgeWidth = cs * 0.195
        let fluidWidth = cs * 0.155
        let fluidLightWidth = cs * 0.085
        let specularWidth = max(1.0, cs * 0.028)
        let lightingOffset = CGSize(width: -cs * 0.035, height: -cs * 0.045)

        for (_, pathModel) in state.paths {
            guard pathModel.coordinates.count >= 2 else { continue }
            let isConnected = pathModel.isConnected
            let fluidColor = PipeworkTheme.fluidColor(for: pathModel.fluidType)
            let path = buildContinuousPath(coordinates: pathModel.coordinates, geometry: geometry)
            let litPath = buildContinuousPath(coordinates: pathModel.coordinates, geometry: geometry, offset: lightingOffset)

            // 1. Hydraulic Drop Shadow
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: .black.opacity(0.88), radius: cs * 0.11, x: cs * 0.055, y: cs * 0.09))
                layer.stroke(path, with: .color(Color.black.opacity(0.88)), style: pipeStroke(width: outerWidth + cs * 0.04))
            }

            // 2. Thick Vulcanized Outer Casing (#181E26)
            context.stroke(
                path,
                with: .color(Color(red: 9/255, green: 13/255, blue: 18/255)),
                style: pipeStroke(width: outerWidth)
            )

            // 3. Outer Casing Edge Bevel (#273240)
            context.stroke(
                path,
                with: .color(Color(red: 38/255, green: 50/255, blue: 62/255)),
                style: pipeStroke(width: shellShoulderWidth)
            )

            context.stroke(
                litPath,
                with: .color(Color(red: 79/255, green: 96/255, blue: 111/255).opacity(0.72)),
                style: pipeStroke(width: shellLightWidth)
            )

            context.stroke(
                path,
                with: .color(Color(red: 18/255, green: 24/255, blue: 31/255)),
                style: pipeStroke(width: shellLightWidth * 0.82)
            )

            // 4. Dark Core Bedding / Recessed Trench (#0A0D11)
            context.stroke(
                path,
                with: .color(Color(red: 10/255, green: 13/255, blue: 17/255)),
                style: pipeStroke(width: trenchWidth)
            )

            context.drawLayer { layer in
                layer.addFilter(.shadow(color: fluidColor.opacity(isConnected ? 0.48 : 0.25), radius: cs * 0.09))
                layer.stroke(path, with: .color(fluidColor.opacity(isConnected ? 0.62 : 0.42)), style: pipeStroke(width: fluidEdgeWidth))
            }

            context.stroke(
                path,
                with: .color(fluidColor.opacity(isConnected ? 0.68 : 0.52)),
                style: pipeStroke(width: fluidEdgeWidth)
            )

            context.stroke(
                path,
                with: .color(fluidColor.opacity(isConnected ? 1.0 : 0.88)),
                style: pipeStroke(width: fluidWidth)
            )

            context.stroke(
                litPath,
                with: .color(Color.white.opacity(isConnected ? 0.27 : 0.20)),
                style: pipeStroke(width: fluidLightWidth)
            )

            context.stroke(
                litPath,
                with: .color(Color.white.opacity(isConnected ? 0.68 : 0.48)),
                style: StrokeStyle(lineWidth: specularWidth, lineCap: .round, lineJoin: .round, dash: [cs * 0.42, cs * 0.16], dashPhase: cs * 0.08)
            )

            // 7. Animated Fluid Pulses (when line is connected and reduceMotion is false)
            if isConnected && !reduceMotion {
                let speed: CGFloat = 46.0
                let cycleLength: CGFloat = cs * 2.15
                let dashOffset = CGFloat(time * speed).truncatingRemainder(dividingBy: cycleLength)

                let pulseStyle = StrokeStyle(
                    lineWidth: cs * 0.052,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: [cs * 0.20, cs * 1.95],
                    dashPhase: -dashOffset
                )
                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: fluidColor.opacity(0.85), radius: cs * 0.055))
                    layer.stroke(litPath, with: .color(Color.white.opacity(0.78)), style: pulseStyle)
                }
            }
        }
    }

    private func pipeStroke(width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }

    private func drawCouplings(context: GraphicsContext, geometry: BoardGeometry) {
        let cs = geometry.cellSize
        for pathModel in state.paths.values where pathModel.coordinates.count >= 4 {
            for index in 1..<(pathModel.coordinates.count - 1) where index % 3 == 1 {
                let previous = pathModel.coordinates[index - 1]
                let current = pathModel.coordinates[index]
                let next = pathModel.coordinates[index + 1]
                guard previous.direction(to: current)?.axis == current.direction(to: next)?.axis else { continue }

                let center = geometry.center(for: current)
                let horizontal = previous.y == current.y
                let bandRect = CGRect(
                    x: center.x - (horizontal ? cs * 0.07 : cs * 0.245),
                    y: center.y - (horizontal ? cs * 0.245 : cs * 0.07),
                    width: horizontal ? cs * 0.14 : cs * 0.49,
                    height: horizontal ? cs * 0.49 : cs * 0.14
                )
                let band = Path(roundedRect: bandRect, cornerRadius: cs * 0.045)
                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: .black.opacity(0.72), radius: 2, x: 1.5, y: 2.5))
                    layer.fill(
                        band,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color(red: 20/255, green: 27/255, blue: 34/255),
                                Color(red: 101/255, green: 119/255, blue: 135/255),
                                Color(red: 39/255, green: 50/255, blue: 61/255),
                                Color(red: 11/255, green: 15/255, blue: 20/255)
                            ]),
                            startPoint: CGPoint(x: bandRect.minX, y: bandRect.minY),
                            endPoint: CGPoint(x: bandRect.maxX, y: bandRect.maxY)
                        )
                    )
                }
                context.stroke(band, with: .color(Color.black.opacity(0.8)), lineWidth: 1)
                let highlightInset = horizontal
                    ? CGRect(x: bandRect.minX + 2, y: bandRect.minY + 1, width: max(0, bandRect.width - 4), height: 1)
                    : CGRect(x: bandRect.minX + 1, y: bandRect.minY + 2, width: 1, height: max(0, bandRect.height - 4))
                context.fill(Path(highlightInset), with: .color(Color.white.opacity(0.38)))
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

            let shadowRect = CGRect(x: center.x - outerR, y: center.y - outerR + cs * 0.055, width: outerR * 2, height: outerR * 2)
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: .black.opacity(0.88), radius: cs * 0.09, x: cs * 0.035, y: cs * 0.06))
                layer.fill(Path(ellipseIn: shadowRect), with: .color(Color.black.opacity(0.75)))
            }

            let outerRect = CGRect(x: center.x - outerR, y: center.y - outerR, width: outerR * 2, height: outerR * 2)
            let flangePath = Path(ellipseIn: outerRect)
            let flangeGradient = Gradient(colors: [
                Color(red: 111/255, green: 129/255, blue: 145/255),
                Color(red: 50/255, green: 63/255, blue: 77/255),
                Color(red: 19/255, green: 26/255, blue: 34/255),
                Color(red: 8/255, green: 12/255, blue: 17/255)
            ])
            context.fill(
                flangePath,
                with: .linearGradient(flangeGradient, startPoint: CGPoint(x: outerRect.minX, y: outerRect.minY), endPoint: CGPoint(x: outerRect.maxX, y: outerRect.maxY))
            )
            context.stroke(flangePath, with: .color(Color(red: 96/255, green: 117/255, blue: 136/255).opacity(0.72)), lineWidth: 1.3)
            let flangeInset = outerRect.insetBy(dx: cs * 0.055, dy: cs * 0.055)
            context.stroke(Path(ellipseIn: flangeInset), with: .color(Color.black.opacity(0.62)), lineWidth: cs * 0.045)
            context.stroke(
                Path(ellipseIn: flangeInset.offsetBy(dx: -cs * 0.012, dy: -cs * 0.018)),
                with: .color(Color.white.opacity(0.16)),
                lineWidth: 1
            )

            let boltCount = 6
            let boltRadius = max(1.2, cs * 0.024)
            for i in 0..<boltCount {
                let angle = (Double(i) / Double(boltCount)) * 2 * .pi
                let br = outerR * 0.8
                let bx = center.x + CGFloat(cos(angle)) * br
                let by = center.y + CGFloat(sin(angle)) * br
                let bRect = CGRect(x: bx - boltRadius, y: by - boltRadius, width: boltRadius * 2, height: boltRadius * 2)
                context.fill(
                    Path(ellipseIn: bRect),
                    with: .linearGradient(
                        Gradient(colors: [Color(red: 126/255, green: 141/255, blue: 153/255), Color(red: 15/255, green: 20/255, blue: 26/255)]),
                        startPoint: CGPoint(x: bRect.minX, y: bRect.minY),
                        endPoint: CGPoint(x: bRect.maxX, y: bRect.maxY)
                    )
                )
                context.stroke(Path(ellipseIn: bRect), with: .color(Color.black.opacity(0.8)), lineWidth: 0.7)
            }

            let cavityRect = CGRect(x: center.x - cavityR, y: center.y - cavityR, width: cavityR * 2, height: cavityR * 2)
            let cavityPath = Path(ellipseIn: cavityRect)
            context.fill(
                cavityPath,
                with: .radialGradient(
                    Gradient(colors: [Color(red: 3/255, green: 5/255, blue: 7/255), Color(red: 17/255, green: 23/255, blue: 30/255)]),
                    center: CGPoint(x: center.x - cavityR * 0.25, y: center.y - cavityR * 0.28),
                    startRadius: 0,
                    endRadius: cavityR
                )
            )
            context.stroke(cavityPath, with: .color(Color.black.opacity(0.9)), lineWidth: cs * 0.045)

            let coreRect = CGRect(x: center.x - coreR, y: center.y - coreR, width: coreR * 2, height: coreR * 2)
            let corePath = Path(ellipseIn: coreRect)
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: fluidColor.opacity(isConnected ? 0.75 : 0.42), radius: cs * 0.10))
                layer.fill(corePath, with: .color(fluidColor.opacity(0.82)))
            }
            context.fill(
                corePath,
                with: .radialGradient(
                    Gradient(colors: [Color.white.opacity(0.78), fluidColor, fluidColor.opacity(0.58)]),
                    center: CGPoint(x: center.x - coreR * 0.32, y: center.y - coreR * 0.38),
                    startRadius: 0,
                    endRadius: coreR * 1.05
                )
            )

            let specR = coreR * 0.38
            let specRect = CGRect(x: center.x - coreR * 0.45, y: center.y - coreR * 0.45, width: specR, height: specR)
            context.fill(Path(ellipseIn: specRect), with: .color(Color.white.opacity(0.66)))

            if isConnected || isCurrentActive {
                let lockRingRect = CGRect(x: center.x - cavityR - 1.5, y: center.y - cavityR - 1.5, width: (cavityR + 1.5) * 2, height: (cavityR + 1.5) * 2)
                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: fluidColor.opacity(0.75), radius: cs * 0.065))
                    layer.stroke(Path(ellipseIn: lockRingRect), with: .color(fluidColor.opacity(0.92)), lineWidth: max(1.5, cs * 0.035))
                }
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

    private func buildContinuousPath(
        coordinates: [GridCoord],
        geometry: BoardGeometry,
        offset: CGSize = .zero
    ) -> Path {
        var path = Path()
        guard coordinates.count >= 2 else { return path }

        let points = coordinates.map { coord in
            let center = geometry.center(for: coord)
            return CGPoint(x: center.x + offset.width, y: center.y + offset.height)
        }
        let radius = geometry.cellSize * 0.31
        path.move(to: points[0])

        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }

        for index in 1..<(points.count - 1) {
            let previous = points[index - 1]
            let corner = points[index]
            let next = points[index + 1]
            let incoming = normalizedVector(from: corner, to: previous)
            let outgoing = normalizedVector(from: corner, to: next)
            let isCorner = abs(incoming.dx - outgoing.dx) > 0.1 && abs(incoming.dy - outgoing.dy) > 0.1

            if isCorner {
                let entry = CGPoint(x: corner.x + incoming.dx * radius, y: corner.y + incoming.dy * radius)
                let exit = CGPoint(x: corner.x + outgoing.dx * radius, y: corner.y + outgoing.dy * radius)
                path.addLine(to: entry)
                path.addQuadCurve(to: exit, control: corner)
            } else {
                path.addLine(to: corner)
            }
        }
        path.addLine(to: points[points.count - 1])
        return path
    }

    private func normalizedVector(from origin: CGPoint, to target: CGPoint) -> CGVector {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let length = max(0.001, hypot(dx, dy))
        return CGVector(dx: dx / length, dy: dy / length)
    }
}

/// Stable gesture controller across SwiftUI render passes.
@MainActor
public final class BoardGestureController: ObservableObject {
    public let interpreter = GridGestureInterpreter()
    public var isDragging: Bool = false

    public init() {}
}
