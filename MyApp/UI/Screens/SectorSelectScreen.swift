import SwiftUI

/// Clean, lightweight level browser with native interactive iOS page-swipe physics between packs.
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

            VStack(spacing: 14) {
                // 1. Top Navigation Bar
                HStack {
                    Button(action: {
                        HapticService.shared.buttonTap()
                        onBack()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .bold))
                            Text("Menu")
                                .font(PipeworkTheme.headingFont(size: 14, weight: .semibold))
                        }
                        .foregroundColor(PipeworkTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(PipeworkTheme.bgElevated)
                                .overlay(Capsule().stroke(PipeworkTheme.borderSubtle, lineWidth: 1))
                        )
                    }

                    Spacer()

                    Text("Level Select")
                        .font(PipeworkTheme.headingFont(size: 17, weight: .bold))
                        .foregroundColor(PipeworkTheme.textMain)

                    Spacer()

                    // Pack star progress
                    let packStars = currentPack.levels.reduce(0) { $0 + (persistence.getRecord(for: $1.id)?.starsEarned ?? 0) }
                    let totalPossible = currentPack.levels.count * 3
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(PipeworkTheme.goldStar)
                        Text("\(packStars)/\(totalPossible)")
                            .font(PipeworkTheme.captionFont(size: 12, weight: .bold))
                            .foregroundColor(PipeworkTheme.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(PipeworkTheme.bgElevated)
                            .overlay(Capsule().stroke(PipeworkTheme.borderSubtle, lineWidth: 1))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // 2. Refined Segmented Control
                HStack(spacing: 4) {
                    ForEach(Array(packs.enumerated()), id: \.offset) { index, pack in
                        Button(action: {
                            HapticService.shared.buttonTap()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                selectedPackIndex = index
                            }
                        }) {
                            Text(pack.name)
                                .font(PipeworkTheme.headingFont(size: 14, weight: selectedPackIndex == index ? .bold : .medium))
                                .foregroundColor(selectedPackIndex == index ? PipeworkTheme.textMain : PipeworkTheme.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: PipeworkTheme.radiusSmall)
                                        .fill(selectedPackIndex == index ? PipeworkTheme.surfaceSubtle : Color.clear)
                                )
                        }
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium)
                        .fill(PipeworkTheme.bgElevated)
                        .overlay(RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium).stroke(PipeworkTheme.borderSubtle, lineWidth: 1))
                )
                .padding(.horizontal, 20)

                // 3. Native Interactive Paged TabView
                TabView(selection: $selectedPackIndex) {
                    ForEach(Array(packs.enumerated()), id: \.offset) { packIdx, pack in
                        packLevelGridView(pack: pack)
                            .tag(packIdx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: selectedPackIndex) { _, _ in
                    HapticService.shared.buttonTap()
                }
            }
        }
    }

    // MARK: - Level Grid for a specific pack

    private func packLevelGridView(pack: LevelPack) -> some View {
        let chapters = stride(from: 0, to: pack.levels.count, by: 10).map { start in
            let end = min(start + 10, pack.levels.count)
            return LevelChapter(number: start / 10 + 1, levels: Array(pack.levels[start..<end]))
        }

        return ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(chapters) { chapter in
                    VStack(alignment: .leading, spacing: 10) {
                        chapterHeader(chapter)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                            ForEach(chapter.levels) { level in
                                compactLevelTile(pack: pack, level: level)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
    }

    private func chapterHeader(_ chapter: LevelChapter) -> some View {
        let completed = chapter.levels.filter { persistence.isLevelCompleted($0.id) }.count
        return HStack {
            Text("Sector \(chapter.number)")
                .font(PipeworkTheme.headingFont(size: 13, weight: .bold))
                .foregroundColor(PipeworkTheme.textSecondary)

            Spacer()

            Text("\(completed)/\(chapter.levels.count) completed")
                .font(PipeworkTheme.captionFont(size: 11, weight: .medium))
                .foregroundColor(PipeworkTheme.textMuted)
        }
    }

    private func compactLevelTile(pack: LevelPack, level: LevelDefinition) -> some View {
        let record = persistence.getRecord(for: level.id)
        let isCompleted = record?.isCompleted ?? false
        let stars = record?.starsEarned ?? 0
        let isUnlocked = persistence.isLevelUnlocked(level.id)
        let isCurrent = CampaignProgression.continueLocation(profile: persistence.profile)?.level.id == level.id

        return Button(action: {
            guard isUnlocked else { return }
            HapticService.shared.buttonTap()
            onSelectLevel(pack, level)
        }) {
            VStack(spacing: 4) {
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(PipeworkTheme.textDim)
                        .frame(height: 22)
                } else {
                    Text("\(level.number)")
                        .font(PipeworkTheme.statNumberFont(size: 15, weight: .bold))
                        .foregroundColor(isCompleted ? PipeworkTheme.textMain : (isCurrent ? PipeworkTheme.primaryCyan : PipeworkTheme.textSecondary))
                        .frame(height: 22)
                }

                // 3 Star Dots
                HStack(spacing: 3) {
                    ForEach(1...3, id: \.self) { starIdx in
                        Circle()
                            .fill(starIdx <= stars ? (isCompleted ? PipeworkTheme.goldStar : PipeworkTheme.primaryCyan) : PipeworkTheme.textDim.opacity(0.35))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium)
                    .fill(isCurrent ? PipeworkTheme.surfaceSubtle : PipeworkTheme.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium)
                            .stroke(
                                isCurrent ? PipeworkTheme.primaryCyan.opacity(0.6) : (isCompleted ? PipeworkTheme.pressureGreen.opacity(0.25) : PipeworkTheme.borderSubtle),
                                lineWidth: isCurrent ? 1.5 : 1.0
                            )
                    )
            )
        }
        .disabled(!isUnlocked)
        .opacity(isUnlocked ? 1.0 : 0.45)
        .buttonStyle(PlainButtonStyle())
    }
}

private struct LevelChapter: Identifiable {
    let number: Int
    let levels: [LevelDefinition]
    var id: Int { number }
}
