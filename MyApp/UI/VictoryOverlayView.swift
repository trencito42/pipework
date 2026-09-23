import SwiftUI

/// Elegant, premium victory modal celebrating a 100% full-board solved state.
public struct VictoryOverlayView: View {
    public let levelTitle: String
    public let moves: Int
    public let parMoves: Int
    public let outcome: CompletionOutcome?
    public let onNextLevel: () -> Void
    public let onReplay: () -> Void
    public let onLevels: () -> Void

    public init(
        levelTitle: String,
        moves: Int,
        parMoves: Int,
        outcome: CompletionOutcome? = nil,
        onNextLevel: @escaping () -> Void,
        onReplay: @escaping () -> Void = {},
        onLevels: @escaping () -> Void = {}
    ) {
        self.levelTitle = levelTitle
        self.moves = moves
        self.parMoves = parMoves
        self.outcome = outcome
        self.onNextLevel = onNextLevel
        self.onReplay = onReplay
        self.onLevels = onLevels
    }

    public var body: some View {
        ZStack {
            // Calm deep backdrop
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Glowing Victory Icon
                ZStack {
                    Circle()
                        .fill(PipeworkTheme.pressureGreen.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Circle()
                        .stroke(PipeworkTheme.pressureGreen.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 52, height: 52)

                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(PipeworkTheme.pressureGreen)
                }

                // Title & Subtitle
                VStack(spacing: 4) {
                    Text("SYSTEM RESTORED")
                        .font(PipeworkTheme.captionFont(size: 11, weight: .bold))
                        .foregroundColor(PipeworkTheme.pressureGreen)
                        .tracking(1.8)

                    Text(levelTitle)
                        .font(PipeworkTheme.titleFont(size: 24, weight: .bold))
                        .foregroundColor(PipeworkTheme.textMain)
                }

                // 3 Stars Display
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { star in
                        Image(systemName: star <= (outcome?.stars ?? 1) ? "star.fill" : "star")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(star <= (outcome?.stars ?? 1) ? PipeworkTheme.goldStar : PipeworkTheme.textDim.opacity(0.4))
                    }
                }

                // Special Outcome Badge
                if outcome?.isPerfect == true {
                    Text("PERFECT ROUTING")
                        .font(PipeworkTheme.captionFont(size: 11, weight: .bold))
                        .foregroundColor(PipeworkTheme.primaryCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(PipeworkTheme.primaryCyan.opacity(0.12))
                                .overlay(Capsule().stroke(PipeworkTheme.primaryCyan.opacity(0.3), lineWidth: 1))
                        )
                } else if outcome?.isNewBest == true {
                    Text("NEW BEST RECORD")
                        .font(PipeworkTheme.captionFont(size: 11, weight: .bold))
                        .foregroundColor(PipeworkTheme.primaryCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(PipeworkTheme.primaryCyan.opacity(0.12))
                                .overlay(Capsule().stroke(PipeworkTheme.primaryCyan.opacity(0.3), lineWidth: 1))
                        )
                }

                // Stats Row
                HStack(spacing: 0) {
                    statPillar(label: "MOVES", value: "\(moves)")
                    
                    Rectangle()
                        .fill(PipeworkTheme.borderSubtle)
                        .frame(width: 1, height: 28)

                    statPillar(label: "PAR", value: "\(parMoves)")

                    if let best = outcome?.bestMoves {
                        Rectangle()
                            .fill(PipeworkTheme.borderSubtle)
                            .frame(width: 1, height: 28)

                        statPillar(label: "BEST", value: "\(best)")
                    }
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium)
                        .fill(PipeworkTheme.surfaceCard)
                        .overlay(RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium).stroke(PipeworkTheme.borderSubtle, lineWidth: 1))
                )

                // CTAs
                VStack(spacing: 10) {
                    Button(action: onNextLevel) {
                        HStack(spacing: 8) {
                            Text("Next Level")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .buttonStyle(PipeworkPillButtonStyle(variant: .primary))

                    HStack(spacing: 12) {
                        Button("Replay", action: onReplay)
                            .buttonStyle(PipeworkPillButtonStyle(variant: .secondary))

                        Button("Levels", action: onLevels)
                            .buttonStyle(PipeworkPillButtonStyle(variant: .subtle))
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: PipeworkTheme.radiusLarge)
                    .fill(PipeworkTheme.bgElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: PipeworkTheme.radiusLarge)
                            .stroke(PipeworkTheme.borderDefault, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)
        }
    }

    private func statPillar(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(PipeworkTheme.captionFont(size: 9, weight: .bold))
                .foregroundColor(PipeworkTheme.textMuted)
                .tracking(1.0)
            Text(value)
                .font(PipeworkTheme.statNumberFont(size: 20, weight: .bold))
                .foregroundColor(PipeworkTheme.textMain)
        }
        .frame(maxWidth: .infinity)
    }
}
