import SwiftUI

/// Industrial victory overlay presented when the grid reaches 100% PRESSURE.
public struct VictoryOverlayView: View {
    public let sectorName: String
    public let moves: Int
    public let connectedFluids: Int
    public let totalFluids: Int
    public let onNextSector: () -> Void

    public var body: some View {
        ZStack {
            // Blurred backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // Tactical Modal Card
            VStack(spacing: 18) {
                // 1. Success Icon Badge
                ZStack {
                    Circle()
                        .fill(PipeworkTheme.pressureGreen.opacity(0.12))
                        .frame(width: 58, height: 58)
                    Circle()
                        .stroke(PipeworkTheme.pressureGreen.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 58, height: 58)
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(PipeworkTheme.pressureGreen)
                }
                .shadow(color: PipeworkTheme.pressureGreen.opacity(0.3), radius: 12)

                // 2. Title & Status Subtitle
                VStack(spacing: 4) {
                    Text("SYSTEM RESTORED")
                        .font(PipeworkTheme.roundedFont(size: 20, weight: .heavy))
                        .foregroundColor(PipeworkTheme.textMain)
                        .tracking(1.8)

                    Text("PRESSURE STABLE")
                        .font(PipeworkTheme.monoFont(size: 12, weight: .bold))
                        .foregroundColor(PipeworkTheme.pressureGreen)
                        .tracking(2.0)
                }

                // 3. Stats Diagnostic Strip
                HStack {
                    statItem(title: "EFFICIENCY", value: "100%")
                    Divider()
                        .frame(height: 20)
                        .background(PipeworkTheme.borderDim)
                    statItem(title: "MOVES", value: String(format: "%02d", moves))
                    Divider()
                        .frame(height: 20)
                        .background(PipeworkTheme.borderDim)
                    statItem(title: "FLUIDS", value: "\(connectedFluids) / \(totalFluids)")
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 14/255, green: 18/255, blue: 23/255))
                )

                // 4. Primary Glowing Action Button
                Button(action: onNextSector) {
                    HStack(spacing: 8) {
                        Text("NEXT SECTOR")
                            .font(PipeworkTheme.monoFont(size: 14, weight: .bold))
                            .tracking(1.6)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(Color(red: 5/255, green: 22/255, blue: 22/255))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 36/255, green: 240/255, blue: 240/255), Color(red: 21/255, green: 184/255, blue: 184/255)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: PipeworkTheme.primaryCyan.opacity(0.4), radius: 10, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 18/255, green: 23/255, blue: 30/255), Color(red: 10/255, green: 13/255, blue: 18/255)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 39/255, green: 51/255, blue: 66/255), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.8), radius: 30, y: 15)
        }
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(PipeworkTheme.monoFont(size: 9, weight: .bold))
                .foregroundColor(PipeworkTheme.textMuted)
            Text(value)
                .font(PipeworkTheme.monoFont(size: 13, weight: .bold))
                .foregroundColor(PipeworkTheme.textMain)
        }
        .frame(maxWidth: .infinity)
    }
}
