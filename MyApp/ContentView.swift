import SwiftUI

/// Root app shell managing screen navigation and presentation transitions.
public struct ContentView: View {
    public enum ActiveScreen: Equatable {
        case menu
        case sectorSelect
        case gameplay(pack: LevelPack, level: LevelDefinition, isProcedural: Bool)

        public static func == (lhs: ActiveScreen, rhs: ActiveScreen) -> Bool {
            switch (lhs, rhs) {
            case (.menu, .menu), (.sectorSelect, .sectorSelect):
                return true
            case let (.gameplay(p1, l1, proc1), .gameplay(p2, l2, proc2)):
                return p1.id == p2.id && l1.id == l2.id && proc1 == proc2
            default:
                return false
            }
        }
    }

    @State private var currentScreen: ActiveScreen = .menu
    @State private var isShowingSettings: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            PipeworkTheme.bgBase
                .ignoresSafeArea()

            switch currentScreen {
            case .menu:
                MainMenuScreen(
                    onPlayCampaign: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .sectorSelect
                        }
                    },
                    onPlayInfinite: {
                        let procLevel = LevelGenerator.generateLevel(
                            size: 6,
                            pairCount: 4,
                            packId: "procedural",
                            levelNumber: 1
                        )
                        let procPack = LevelPack(
                            id: "procedural",
                            name: "OVERDRIVE",
                            subtitle: "Infinite Generator",
                            gridSize: 6,
                            order: 99,
                            levels: [procLevel]
                        )
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .gameplay(pack: procPack, level: procLevel, isProcedural: true)
                        }
                    },
                    onOpenSettings: {
                        isShowingSettings = true
                    }
                )
                .transition(.opacity)

            case .sectorSelect:
                SectorSelectScreen(
                    onSelectLevel: { pack, level in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .gameplay(pack: pack, level: level, isProcedural: false)
                        }
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .menu
                        }
                    }
                )
                .transition(.opacity)

            case let .gameplay(pack, level, isProcedural):
                GameplayScreen(
                    pack: pack,
                    level: level,
                    isProceduralMode: isProcedural,
                    onExitToMenu: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .menu
                        }
                    },
                    onOpenSectorMatrix: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .sectorSelect
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsScreen()
        }
    }
}

#Preview {
    ContentView()
}
