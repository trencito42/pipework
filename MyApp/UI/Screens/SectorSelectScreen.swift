import SwiftUI

/// Tactical sector and level browser displaying progression and star telemetry.
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
                // Header
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("MENU")
                                .font(PipeworkTheme.monoFont(size: 12, weight: .bold))
                        }
                        .foregroundColor(PipeworkTheme.textMain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(PipeworkTheme.panelBase)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(PipeworkTheme.borderDim, lineWidth: 1))
                        )
                    }

                    Spacer()

                    Text("SECTOR MATRIX")
                        .font(PipeworkTheme.roundedFont(size: 17, weight: .heavy))
                        .foregroundColor(PipeworkTheme.textMain)
                        .tracking(2.0)

                    Spacer()

                    // Balance placeholder
                    Color.clear
                        .frame(width: 70, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Pack Selector Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(packs.enumerated()), id: \.offset) { index, pack in
                            Button(action: { selectedPackIndex = index }) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(pack.name)
                                        .font(PipeworkTheme.monoFont(size: 13, weight: .bold))
                                        .foregroundColor(selectedPackIndex == index ? PipeworkTheme.primaryCyan : PipeworkTheme.textMuted)
                                    Text("\(pack.gridSize)×\(pack.gridSize)")
                                        .font(PipeworkTheme.monoFont(size: 10, weight: .medium))
                                        .foregroundColor(PipeworkTheme.textDim)
                                }
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

                // Subtitle Info
                HStack {
                    Text(currentPack.subtitle)
                        .font(PipeworkTheme.monoFont(size: 12, weight: .semibold))
                        .foregroundColor(PipeworkTheme.textMuted)
                    Spacer()
                    Text("\(currentPack.levels.count) SUB-SECTORS")
                        .font(PipeworkTheme.monoFont(size: 10, weight: .bold))
                        .foregroundColor(PipeworkTheme.primaryCyan)
                }
                .padding(.horizontal, 24)

                // Level Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
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

        return Button(action: { onSelectLevel(currentPack, level) }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("LEVEL \(level.number)")
                        .font(PipeworkTheme.monoFont(size: 14, weight: .bold))
                        .foregroundColor(isCompleted ? PipeworkTheme.textMain : PipeworkTheme.textMuted)
                    Spacer()
                    if isCompleted {
                        Circle()
                            .fill(PipeworkTheme.pressureGreen)
                            .frame(width: 8, height: 8)
                            .shadow(color: PipeworkTheme.pressureGreen, radius: 4)
                    }
                }

                // Stars Display
                HStack(spacing: 4) {
                    ForEach(1...3, id: \.self) { starIndex in
                        Image(systemName: starIndex <= stars ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundColor(starIndex <= stars ? PipeworkTheme.primaryCyan : PipeworkTheme.textDim)
                    }
                }

                // Metrics
                HStack {
                    Text("PAR: \(level.parMoves)")
                        .font(PipeworkTheme.monoFont(size: 10, weight: .medium))
                        .foregroundColor(PipeworkTheme.textDim)
                    Spacer()
                    if let best = record?.bestMoves {
                        Text("BEST: \(best)")
                            .font(PipeworkTheme.monoFont(size: 10, weight: .bold))
                            .foregroundColor(PipeworkTheme.primaryCyan)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(PipeworkTheme.panelBase)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isCompleted ? PipeworkTheme.borderBright : PipeworkTheme.borderDim, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
