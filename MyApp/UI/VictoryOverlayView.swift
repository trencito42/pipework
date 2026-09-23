import SwiftUI

/// Victory modal celebrating a 100% full-board solved state.
public struct VictoryOverlayView: View {
    public let levelTitle: String
    public let moves: Int
    public let bestMoves: Int?
    public let onNextLevel: () -> Void
    public let onReplay: () -> Void
    public let onLevels: () -> Void

    public init(
        levelTitle: String,
        moves: Int,
        bestMoves: Int? = nil,
        onNextLevel: @escaping () -> Void,
        onReplay: @escaping () -> Void = {},
        onLevels: @escaping () -> Void = {}
    ) {
        self.levelTitle = levelTitle
        self.moves = moves
        self.bestMoves = bestMoves
        self.onNextLevel = onNextLevel
        self.onReplay = onReplay
        self.onLevels = onLevels
    }

    public var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Glow status icon
                ZStack {
                    Circle()
                        .fill(PipeworkTheme.pressureGreen.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Circle()
                        .fill(PipeworkTheme.pressureGreen)
                        .frame(width: 24, height: 24)
                        .shadow(color: PipeworkTheme.pressureGreen, radius: 12)
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Color(red: 4/255, green: 20/255, blue: 10/255))
                }

                VStack(spacing: 4) {
                    Text("SYSTEM RESTORED")
                        .font(PipeworkTheme.monoFont(size: 12, weight: .bold))
                        .foregroundColor(PipeworkTheme.pressureGreen)
                        .tracking(2.0)

                    Text(levelTitle)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(PipeworkTheme.textMain)
                }

                // Stats card
                HStack(spacing: 20) {
                    VStack(spacing: 2) {
                        Text("MOVES")
                            .font(PipeworkTheme.monoFont(size: 10, weight: .bold))
                            .foregroundColor(PipeworkTheme.textMuted)
                        Text("\(moves)")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(PipeworkTheme.primaryCyan)
                    }

                    if let best = bestMoves {
                        Divider()
                            .frame(height: 28)
                            .background(PipeworkTheme.borderDim)

                        VStack(spacing: 2) {
                            Text("BEST")
                                .font(PipeworkTheme.monoFont(size: 10, weight: .bold))
                                .foregroundColor(PipeworkTheme.textMuted)
                            Text("\(best)")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(PipeworkTheme.primaryCyan)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(PipeworkTheme.panelSubtle)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(PipeworkTheme.borderDim, lineWidth: 1))
                )

                // Actions
                VStack(spacing: 10) {
                    Button(action: onNextLevel) {
                        Text("Next Level")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 4/255, green: 20/255, blue: 10/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(PipeworkTheme.pressureGreen)
                            )
                            .shadow(color: PipeworkTheme.pressureGreen.opacity(0.35), radius: 8, y: 3)
                    }

                    HStack(spacing: 12) {
                        Button(action: onReplay) {
                            Text("Replay")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(PipeworkTheme.textMain)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(PipeworkTheme.panelBase)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(PipeworkTheme.borderDim, lineWidth: 1))
                                )
                        }

                        Button(action: onLevels) {
                            Text("Levels")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(PipeworkTheme.textMain)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(PipeworkTheme.panelBase)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(PipeworkTheme.borderDim, lineWidth: 1))
                                )
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(PipeworkTheme.panelBase)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(PipeworkTheme.borderBright, lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 32)
        }
    }
}
