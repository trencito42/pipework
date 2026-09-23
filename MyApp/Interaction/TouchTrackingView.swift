import SwiftUI
#if canImport(UIKit)
import UIKit

/// High-precision, zero-latency native touch surface forwarding continuous pointer events.
public struct TouchTrackingView: UIViewRepresentable {
    public let onTouchBegan: (CGPoint) -> Void
    public let onTouchMoved: (CGPoint) -> Void
    public let onTouchEnded: (CGPoint) -> Void
    public let onTouchCancelled: () -> Void
    public let onPredictedTouchMoved: ((CGPoint) -> Void)?

    public init(
        onTouchBegan: @escaping (CGPoint) -> Void,
        onTouchMoved: @escaping (CGPoint) -> Void,
        onTouchEnded: @escaping (CGPoint) -> Void,
        onTouchCancelled: @escaping () -> Void,
        onPredictedTouchMoved: ((CGPoint) -> Void)? = nil
    ) {
        self.onTouchBegan = onTouchBegan
        self.onTouchMoved = onTouchMoved
        self.onTouchEnded = onTouchEnded
        self.onTouchCancelled = onTouchCancelled
        self.onPredictedTouchMoved = onPredictedTouchMoved
    }

    public func makeUIView(context: Context) -> TouchCaptureUIView {
        let view = TouchCaptureUIView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = false
        view.onTouchBegan = onTouchBegan
        view.onTouchMoved = onTouchMoved
        view.onTouchEnded = onTouchEnded
        view.onTouchCancelled = onTouchCancelled
        view.onPredictedTouchMoved = onPredictedTouchMoved
        return view
    }

    public func updateUIView(_ uiView: TouchCaptureUIView, context: Context) {
        uiView.onTouchBegan = onTouchBegan
        uiView.onTouchMoved = onTouchMoved
        uiView.onTouchEnded = onTouchEnded
        uiView.onTouchCancelled = onTouchCancelled
        uiView.onPredictedTouchMoved = onPredictedTouchMoved
    }

    public final class TouchCaptureUIView: UIView {
        var onTouchBegan: ((CGPoint) -> Void)?
        var onTouchMoved: ((CGPoint) -> Void)?
        var onTouchEnded: ((CGPoint) -> Void)?
        var onTouchCancelled: (() -> Void)?
        var onPredictedTouchMoved: ((CGPoint) -> Void)?

        public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let loc = touch.location(in: self)
            onTouchBegan?(loc)
        }

        public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }

            // Process coalesced touches if available for 120Hz smoothness
            if let event = event, let coalesced = event.coalescedTouches(for: touch) {
                for cTouch in coalesced {
                    let loc = cTouch.location(in: self)
                    onTouchMoved?(loc)
                }
            } else {
                let loc = touch.location(in: self)
                onTouchMoved?(loc)
            }

            // Forward predicted touch ONLY for visual tether responsiveness
            if let event = event, let predicted = event.predictedTouches(for: touch)?.first {
                let predLoc = predicted.location(in: self)
                onPredictedTouchMoved?(predLoc)
            }
        }

        public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else {
                onTouchCancelled?()
                return
            }
            let loc = touch.location(in: self)
            onTouchEnded?(loc)
        }

        public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            onTouchCancelled?()
        }
    }
}
#endif
