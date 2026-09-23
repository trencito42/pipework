import SwiftUI
import Combine

/// High-performance, clean, geometric Canvas renderer for PIPEWORK.
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
                    margin: 6
                )

                ZStack {
                    Canvas { context, _ in
                        drawBoardBackdrop(context: context, geometry: geometry)
                        drawGridCells(context: context, geometry: geometry)
                        drawPipes(context: context, geometry: geometry, time: timeInterval)
                        drawActiveDragTether(context: context, geometry: geometry)
                        drawTerminalSockets(context: context, geometry: geometry)
                        drawBlockedIndicator(context: context, geometry: geometry)
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
            try? await Task.sleep(nanoseconds: 240_000_000)
            if localBlockedCoord == coord {
                localBlockedCoord = nil
            }
        }
    }

    // MARK: - 1. Clean Geometric Board Backdrop

    private func drawBoardBackdrop(context: GraphicsContext, geometry: BoardGeometry) {
        let rect = geometry.boardRect
        let cornerRadius: CGFloat = min(22, geometry.cellSize * 0.35)
        let boardPath = Path(roundedRect: rect, cornerRadius: cornerRadius)

        // Soft ambient shadow
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: Color.black.opacity(0.45), radius: 16, x: 0, y: 8))
            layer.fill(boardPath, with: .color(PipeworkTheme.bgCanvas))
        }

        // Deep matte board surface
        context.fill(
            boardPath,
            with: .color(PipeworkTheme.bgElevated)
        )

        // Refined outer edge stroke
        context.stroke(
            boardPath,
            with: .color(PipeworkTheme.borderSubtle),
            lineWidth: 1.0
        )
    }

    // MARK: - 2. Subtle Grid Cells & Alignment Dots

    private func drawGridCells(context: GraphicsContext, geometry: BoardGeometry) {
        let cs = geometry.cellSize
        let cellInset = max(1.5, cs * 0.04)
        let cellRadius = max(4, cs * 0.14)

        for y in 0..<geometry.gridSize.height {
            for x in 0..<geometry.gridSize.width {
                let coord = GridCoord(x: x, y: y)
                let cellRect = geometry.cellRect(for: coord)
                let insetRect = cellRect.insetBy(dx: cellInset, dy: cellInset)
                let cellPath = Path(roundedRect: insetRect, cornerRadius: cellRadius)

                // Quiet cell tile fill
                context.fill(
                    cellPath,
                    with: .color(PipeworkTheme.surfaceCard.opacity(0.45))
                )

                // Subtle grid cell outline
                context.stroke(
                    cellPath,
                    with: .color(Color.white.opacity(0.025)),
                    lineWidth: 0.75
                )

                // Center guide dot
                let center = geometry.center(for: coord)
                let dotSize = max(2.0, cs * 0.05)
                let dotRect = CGRect(x: center.x - dotSize / 2, y: center.y - dotSize / 2, width: dotSize, height: dotSize)
                context.fill(
                    Path(ellipseIn: dotRect),
                    with: .color(Color.white.opacity(0.07))
                )
            }
        }
    }

    // MARK: - 3. Clean Modern Geometric Pipes

    private func drawPipes(context: GraphicsContext, geometry: BoardGeometry, time: TimeInterval) {
        let cs = geometry.cellSize
        let outerWidth = cs * 0.44
        let coreWidth = cs * 0.28
        let innerGlowWidth = cs * 0.14

        for (_, pathModel) in state.paths {
            guard pathModel.coordinates.count >= 2 else { continue }
            let isConnected = pathModel.isConnected
            let fluidColor = PipeworkTheme.fluidColor(for: pathModel.fluidType)
            let path = buildContinuousPath(coordinates: pathModel.coordinates, geometry: geometry)

            // 1. Soft depth drop shadow
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: Color.black.opacity(0.4), radius: cs * 0.08, x: 0, y: cs * 0.04))
                layer.stroke(
                    path,
                    with: .color(Color.black.opacity(0.5)),
                    style: StrokeStyle(lineWidth: outerWidth + 2, lineCap: .round, lineJoin: .round)
                )
            }

            // 2. Matte dark casing sleeve (clean, dark container)
            context.stroke(
                path,
                with: .color(PipeworkTheme.bgBase),
                style: StrokeStyle(lineWidth: outerWidth, lineCap: .round, lineJoin: .round)
            )

            // 3. Vibrant fluid color body
            context.drawLayer { layer in
                if isConnected {
                    layer.addFilter(.shadow(color: fluidColor.opacity(0.45), radius: cs * 0.08))
                }
                layer.stroke(
                    path,
                    with: .color(fluidColor),
                    style: StrokeStyle(lineWidth: coreWidth, lineCap: .round, lineJoin: .round)
                )
            }

            // 4. Subtle center core luminescence
            context.stroke(
                path,
                with: .color(Color.white.opacity(isConnected ? 0.35 : 0.20)),
                style: StrokeStyle(lineWidth: innerGlowWidth, lineCap: .round, lineJoin: .round)
            )

            // 5. Flowing fluid pulse dots on connected lines
            if isConnected && !reduceMotion {
                let speed: CGFloat = 36.0
                let cycleLength: CGFloat = cs * 1.8
                let dashOffset = CGFloat(time * speed).truncatingRemainder(dividingBy: cycleLength)

                let pulseStyle = StrokeStyle(
                    lineWidth: cs * 0.08,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: [cs * 0.14, cs * 1.66],
                    dashPhase: -dashOffset
                )
                context.stroke(
                    path,
                    with: .color(Color.white.opacity(0.65)),
                    style: pulseStyle
                )
            }
        }
    }

    // MARK: - 4. Active Dragging Tether & Fluid Head

    private func drawActiveDragTether(context: GraphicsContext, geometry: BoardGeometry) {
        guard let activeLineId = state.activeLineId,
              let activePath = state.paths[activeLineId],
              let headCoord = activePath.head,
              !activePath.isConnected else { return }

        let cs = geometry.cellSize
        let headCenter = geometry.center(for: headCoord)
        let fluidColor = PipeworkTheme.fluidColor(for: activePath.fluidType)

        // Elastic follow tether if pointer is displaced
        if let pointer = dragPointerLocation {
            let dx = pointer.x - headCenter.x
            let dy = pointer.y - headCenter.y
            let dist = hypot(dx, dy)
            let maxTether = cs * 0.55
            let factor = dist > 0 ? min(1.0, maxTether / dist) : 0

            var tetherPath = Path()
            tetherPath.move(to: headCenter)
            tetherPath.addLine(to: CGPoint(x: headCenter.x + dx * factor, y: headCenter.y + dy * factor))

            context.stroke(
                tetherPath,
                with: .color(fluidColor.opacity(0.6)),
                style: StrokeStyle(lineWidth: cs * 0.20, lineCap: .round)
            )
        }

        // Active glowing head ring
        let ringRadius = cs * 0.30
        let ringRect = CGRect(x: headCenter.x - ringRadius, y: headCenter.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2)
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: fluidColor.opacity(0.6), radius: 6))
            layer.stroke(
                Path(ellipseIn: ringRect),
                with: .color(Color.white),
                lineWidth: 2.5
            )
        }
    }

    // MARK: - 5. Concentric Modern Terminal Sockets

    private func drawTerminalSockets(context: GraphicsContext, geometry: BoardGeometry) {
        let cs = geometry.cellSize
        let outerR = cs * 0.36
        let coreR = cs * 0.22

        for terminal in state.terminals {
            let center = geometry.center(for: terminal.coord)
            let fluidColor = PipeworkTheme.fluidColor(for: terminal.fluidType)
            let isConnected = state.paths[terminal.lineId]?.isConnected ?? false
            let isCurrentActive = state.activeLineId == terminal.lineId

            // Outer dark bezel
            let outerRect = CGRect(x: center.x - outerR, y: center.y - outerR, width: outerR * 2, height: outerR * 2)
            let outerPath = Path(ellipseIn: outerRect)
            
            context.fill(
                outerPath,
                with: .color(PipeworkTheme.bgBase)
            )
            context.stroke(
                outerPath,
                with: .color(Color.white.opacity(0.15)),
                lineWidth: 1.5
            )

            // Active / Connected Glow Ring
            if isConnected || isCurrentActive {
                let lockRingRect = outerRect.insetBy(dx: -2.5, dy: -2.5)
                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: fluidColor.opacity(0.6), radius: 6))
                    layer.stroke(
                        Path(ellipseIn: lockRingRect),
                        with: .color(fluidColor.opacity(0.85)),
                        lineWidth: 2.0
                    )
                }
            }

            // Inner Vibrant Fluid Core
            let coreRect = CGRect(x: center.x - coreR, y: center.y - coreR, width: coreR * 2, height: coreR * 2)
            let corePath = Path(ellipseIn: coreRect)

            context.drawLayer { layer in
                if isConnected {
                    layer.addFilter(.shadow(color: fluidColor.opacity(0.5), radius: 6))
                }
                context.fill(
                    corePath,
                    with: .color(fluidColor)
                )
            }

            // Clean white specular highlight dot
            let specSize = coreR * 0.45
            let specRect = CGRect(x: center.x - specSize / 2, y: center.y - coreR * 0.55, width: specSize, height: specSize)
            context.fill(
                Path(ellipseIn: specRect),
                with: .color(Color.white.opacity(0.35))
            )

            // Optional accessibility symbol
            if showAccessibilitySymbols {
                let symbol = terminal.fluidType.symbolCode
                let text = Text(symbol)
                    .font(PipeworkTheme.headingFont(size: cs * 0.22, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.85))
                context.draw(text, at: center)
            }
        }
    }

    // MARK: - 6. Blocked Warning Feedback

    private func drawBlockedIndicator(context: GraphicsContext, geometry: BoardGeometry) {
        guard let blocked = localBlockedCoord else { return }
        let center = geometry.center(for: blocked)
        let cs = geometry.cellSize

        let circlePath = Path(ellipseIn: CGRect(x: center.x - cs * 0.42, y: center.y - cs * 0.42, width: cs * 0.84, height: cs * 0.84))
        context.fill(circlePath, with: .color(PipeworkTheme.warningRed.opacity(0.22)))
        context.stroke(circlePath, with: .color(PipeworkTheme.warningRed), lineWidth: 2.0)
    }

    // MARK: - Path Interpolation

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
        let radius = geometry.cellSize * 0.32
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
