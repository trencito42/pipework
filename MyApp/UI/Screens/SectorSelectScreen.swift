import SwiftUI

/// Clean, human level selection browser displaying pack tabs and star ratings.
public struct SectorSelectScreen: View {
    @ObservedObject private var persistence = PersistenceService.shared
    @State private var selectedPackIndex: Int = 0
    public let onSelectLevel: (LevelPack, LevelDefinition) -> Void
    public let onBack: () -> Void

    private let packs = LevelRepository.allPacks

    public init(
        onSelectLevel: @escaping (LevelPack, LevelDefinition) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.onSelectLevel = onSelectLevel
        self.onBack = onBack
    }

    private var currentPack: LevelPack {
        packs[selectedPackIndex]
    }

    public var body: some View {
        ZStack {
            PipeworkTheme.bgBase
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Top Navigation Bar
                HStack {
                    Button(action: {
                        HapticService.shared.buttonTap()
                        onBack()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Menu")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(PipeworkTheme.textMain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(PipeworkTheme.panelBase)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(PipeworkTheme.borderDim, lineWidth: 1))
                        )
                    }

                    Spacer()

                    Text("Levels")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(PipeworkTheme.textMain)

                    Spacer()

                    Color.clear
                        .frame(width: 60, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Pack Tabs Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(packs.enumerated()), id: \.offset) { index, pack in
                            Button(action: {
                                HapticService.shared.buttonTap()
                                selectedPackIndex = index
                            }) {
                                Text("\(pack.name) Grid")
                                    .font(.system(size: 14, weight: selectedPackIndex == index ? .bold : .medium))
                                    .foregroundColor(selectedPackIndex == index ? PipeworkTheme.primaryCyan : PipeworkTheme.textMuted)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedPackIndex == index ? PipeworkTheme.panelSubtle : PipeworkTheme.panelBase)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedPackIndex == index ? PipeworkTheme.primaryCyan.opacity(0.6) : PipeworkTheme.borderDim, lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Level Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(currentPack.levels) { level in
                            levelCard(level: level)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func levelCard(level: LevelDefinition) -> some View {
        let record = persistence.getRecord(for: level.id)
        let isCompleted = record?.isCompleted ?? false
        let stars = record?.starsEarned ?? 0

        return Button(action: {
            HapticService.shared.buttonTap()
            onSelectLevel(currentPack, level)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Level \(level.number)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isCompleted ? PipeworkTheme.textMain : PipeworkTheme.textMuted)
                    Spacer()
                    if isCompleted {
                        Circle()
                            .fill(PipeworkTheme.pressureGreen)
                            .frame(width: 8, height: 8)
                            .shadow(color: PipeworkTheme.pressureGreen, radius: 4)
                    }
                }

                HStack(spacing: 3) {
                    ForEach(1...3, id: \.self) { starIndex in
                        Image(systemName: starIndex <= stars ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(starIndex <= stars ? PipeworkTheme.primaryCyan : PipeworkTheme.textDim)
                    }
                }

                HStack {
                    Text("Par: \(level.parMoves)")
                        .font(PipeworkTheme.monoFont(size: 11, weight: .medium))
                        .foregroundColor(PipeworkTheme.textDim)
                    Spacer()
                    if let best = record?.bestMoves {
                        Text("Best: \(best)")
                            .font(PipeworkTheme.monoFont(size: 11, weight: .bold))
                            .foregroundColor(PipeworkTheme.primaryCyan)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(PipeworkTheme.panelBase)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCompleted ? PipeworkTheme.borderBright : PipeworkTheme.borderDim, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
