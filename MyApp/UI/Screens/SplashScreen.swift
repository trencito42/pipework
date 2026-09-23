import SwiftUI

/// Minimal Blipmade startup intro shown once on cold app launch.
public struct SplashScreen: View {
    @ObservedObject private var persistence = PersistenceService.shared
    public let onFinished: () -> Void

    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.95

    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    public var body: some View {
        ZStack {
            PipeworkTheme.bgBase
                .ignoresSafeArea()

            HStack(spacing: 8) {
                Circle()
                    .fill(PipeworkTheme.primaryCyan)
                    .frame(width: 8, height: 8)
                    .shadow(color: PipeworkTheme.primaryCyan, radius: 6)

                Text("BLIPMADE")
                    .font(PipeworkTheme.monoFont(size: 16, weight: .bold))
                    .foregroundColor(PipeworkTheme.textMain)
                    .tracking(3.5)
            }
            .opacity(opacity)
            .scaleEffect(persistence.profile.reduceMotionEnabled ? 1.0 : scale)
        }
        .onAppear {
            let reduceMotion = persistence.profile.reduceMotionEnabled
            let animDuration = reduceMotion ? 0.3 : 0.45

            withAnimation(.easeIn(duration: animDuration)) {
                opacity = 1.0
                scale = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onFinished()
                }
            }
        }
    }
}
