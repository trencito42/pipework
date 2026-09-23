import SwiftUI

/// Root app shell coordinating splash screen, menu, level select, and gameplay.
public struct ContentView: View {
    public enum ActiveScreen: Equatable {
        case splash
        case menu
        case levelSelect
        case gameplay(pack: LevelPack, level: LevelDefinition)

        public static func == (lhs: ActiveScreen, rhs: ActiveScreen) -> Bool {
            switch (lhs, rhs) {
            case (.splash, .splash), (.menu, .menu), (.levelSelect, .levelSelect):
                return true
            case let (.gameplay(p1, l1), .gameplay(p2, l2)):
                return p1.id == p2.id && l1.id == l2.id
            default:
                return false
            }
        }
    }

    @State private var currentScreen: ActiveScreen = .splash
    @State private var isShowingSettings: Bool = false
    @ObservedObject private var persistence = PersistenceService.shared

    public init() {}

    public var body: some View {
        ZStack {
            PipeworkTheme.bgBase
                .ignoresSafeArea()

            switch currentScreen {
            case .splash:
                SplashScreen(onFinished: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentScreen = .menu
                    }
                })

            case .menu:
                MainMenuScreen(
                    onPlay: {
                        guard let destination = CampaignProgression.continueLocation(profile: persistence.profile) else {
                            return
                        }
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .gameplay(pack: destination.pack, level: destination.level)
                        }
                    },
                    onLevels: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .levelSelect
                        }
                    },
                    onSettings: {
                        isShowingSettings = true
                    }
                )
                .transition(.opacity)

            case .levelSelect:
                SectorSelectScreen(
                    onSelectLevel: { pack, level in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .gameplay(pack: pack, level: level)
                        }
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .menu
                        }
                    }
                )
                .transition(.opacity)

            case let .gameplay(pack, level):
                GameplayScreen(
                    pack: pack,
                    level: level,
                    onExitToMenu: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .menu
                        }
                    },
                    onOpenLevelSelect: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .levelSelect
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
