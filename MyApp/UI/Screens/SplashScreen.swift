import SwiftUI

/// Restrained, minimal studio ident shown once on cold app launch.
public struct SplashScreen: View {
    @ObservedObject private var persistence = PersistenceService.shared
    public let onFinished: () -> Void

    @State private var opacity: Double = 0.0

    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    public var body: some View {
        ZStack {
            // Calm near-black background
            PipeworkTheme.bgBase
                .ignoresSafeArea()

            // Centered small BLIPMADE studio wordmark with tiny cyan dot
            HStack(spacing: 5) {
                Text("BLIPMADE")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(PipeworkTheme.textSecondary)
                    .tracking(3.5)

                Circle()
                    .fill(PipeworkTheme.primaryCyan)
                    .frame(width: 4, height: 4)
                    .shadow(color: PipeworkTheme.primaryCyan.opacity(0.6), radius: 4)
            }
            .opacity(opacity)
        }
        .onAppear {
            let reduceMotion = persistence.profile.reduceMotionEnabled
            let fadeInDuration = reduceMotion ? 0.15 : 0.25
            let holdDuration = 0.45
            let fadeOutDuration = reduceMotion ? 0.15 : 0.25

            withAnimation(.easeIn(duration: fadeInDuration)) {
                opacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + fadeInDuration + holdDuration) {
                withAnimation(.easeOut(duration: fadeOutDuration)) {
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration) {
                    onFinished()
                }
            }
        }
    }
}
