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

    private var chapters: [LevelChapter] {
        stride(from: 0, to: currentPack.levels.count, by: 10).map { start in
            let end = min(start + 10, currentPack.levels.count)
            return LevelChapter(number: start / 10 + 1, levels: Array(currentPack.levels[start..<end]))
        }
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
                    LazyVStack(spacing: 22) {
                        ForEach(chapters) { chapter in
                            VStack(alignment: .leading, spacing: 10) {
                                chapterHeader(chapter)
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(chapter.levels) { level in
                                        levelCard(level: level)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func chapterHeader(_ chapter: LevelChapter) -> some View {
        let completed = chapter.levels.filter { persistence.isLevelCompleted($0.id) }.count
        let stars = chapter.levels.reduce(0) { $0 + (persistence.getRecord(for: $1.id)?.starsEarned ?? 0) }
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SUBSECTOR \(String(format: "%02d", chapter.number))")
                    .font(PipeworkTheme.monoFont(size: 11, weight: .bold))
                    .foregroundColor(PipeworkTheme.textMain)
                    .tracking(1.2)
                Text("\(completed)/\(chapter.levels.count) restored")
                    .font(PipeworkTheme.monoFont(size: 10, weight: .medium))
                    .foregroundColor(PipeworkTheme.textMuted)
            }
            Spacer()
            Label("\(stars)/\(chapter.levels.count * 3)", systemImage: "star.fill")
                .font(PipeworkTheme.monoFont(size: 10, weight: .bold))
                .foregroundColor(PipeworkTheme.primaryCyan)
        }
    }

    private func levelCard(level: LevelDefinition) -> some View {
        let record = persistence.getRecord(for: level.id)
        let isCompleted = record?.isCompleted ?? false
        let stars = record?.starsEarned ?? 0
        let isUnlocked = persistence.isLevelUnlocked(level.id)
        let isCurrent = CampaignProgression.continueLocation(profile: persistence.profile)?.level.id == level.id

        return Button(action: {
            guard isUnlocked else { return }
            HapticService.shared.buttonTap()
            onSelectLevel(currentPack, level)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Level \(level.number)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isUnlocked ? PipeworkTheme.textMain : PipeworkTheme.textMuted)
                    Spacer()
                    if isCompleted {
                        Circle()
                            .fill(PipeworkTheme.pressureGreen)
                            .frame(width: 8, height: 8)
                            .shadow(color: PipeworkTheme.pressureGreen, radius: 4)
                    } else if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(PipeworkTheme.textDim)
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
                            .stroke(isCurrent ? PipeworkTheme.primaryCyan.opacity(0.7) : (isCompleted ? PipeworkTheme.borderBright : PipeworkTheme.borderDim), lineWidth: isCurrent ? 1.5 : 1)
                    )
            )
        }
        .disabled(!isUnlocked)
        .opacity(isUnlocked ? 1.0 : 0.48)
        .buttonStyle(PlainButtonStyle())
    }
}

private struct LevelChapter: Identifiable {
    let number: Int
    let levels: [LevelDefinition]
    var id: Int { number }
}
