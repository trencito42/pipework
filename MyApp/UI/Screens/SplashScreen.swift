import SwiftUI

/// Minimal startup intro shown once on cold app launch.
public struct SplashScreen: View {
    @ObservedObject private var persistence = PersistenceService.shared
    public let onFinished: () -> Void

    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.96

    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    public var body: some View {
        ZStack {
            PipeworkTheme.bgBase
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Geometric Logo Node
                ZStack {
                    Circle()
                        .stroke(PipeworkTheme.borderSubtle, lineWidth: 1.5)
                        .frame(width: 48, height: 48)

                    Circle()
                        .fill(PipeworkTheme.primaryCyan)
                        .frame(width: 12, height: 12)
                        .shadow(color: PipeworkTheme.primaryCyan, radius: 8)
                }

                Text("PIPEWORK")
                    .font(PipeworkTheme.titleFont(size: 24, weight: .heavy))
                    .foregroundColor(PipeworkTheme.textMain)
                    .tracking(4.0)
            }
            .opacity(opacity)
            .scaleEffect(persistence.profile.reduceMotionEnabled ? 1.0 : scale)
        }
        .onAppear {
            let reduceMotion = persistence.profile.reduceMotionEnabled
            let animDuration = reduceMotion ? 0.25 : 0.4

            withAnimation(.easeIn(duration: animDuration)) {
                opacity = 1.0
                scale = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                withAnimation(.easeOut(duration: 0.25)) {
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    onFinished()
                }
            }
        }
    }
}
