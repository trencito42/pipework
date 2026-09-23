import SwiftUI

/// Tactical status bar with 3 columns (Lines, Moves, Pressure gauge).
public struct StatusPanel: View {
    public let connectedLines: Int
    public let totalLines: Int
    public let moves: Int
    public let pressurePercentage: Int

    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Column 1: LINES
            VStack(alignment: .leading, spacing: 3) {
                Text("LINES")
                    .font(PipeworkTheme.monoFont(size: 9, weight: .bold))
                    .foregroundColor(PipeworkTheme.textMuted)
                    .tracking(1.4)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(connectedLines)")
                        .font(PipeworkTheme.roundedFont(size: 17, weight: .heavy))
                        .foregroundColor(connectedLines == totalLines ? PipeworkTheme.primaryCyan : PipeworkTheme.textMain)
                    Text("/ \(totalLines)")
                        .font(PipeworkTheme.monoFont(size: 12, weight: .medium))
                        .foregroundColor(PipeworkTheme.textDim)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Column 2: MOVES
            VStack(alignment: .leading, spacing: 3) {
                Text("MOVES")
                    .font(PipeworkTheme.monoFont(size: 9, weight: .bold))
                    .foregroundColor(PipeworkTheme.textMuted)
                    .tracking(1.4)

                Text(String(format: "%02d", moves))
                    .font(PipeworkTheme.roundedFont(size: 17, weight: .heavy))
                    .foregroundColor(PipeworkTheme.textMain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Column 3: PRESSURE & Integrated Meter Track
            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text("PRESSURE")
                        .font(PipeworkTheme.monoFont(size: 9, weight: .bold))
                        .foregroundColor(PipeworkTheme.textMuted)
                        .tracking(1.4)
                    Spacer()
                    Text("\(pressurePercentage)%")
                        .font(PipeworkTheme.roundedFont(size: 14, weight: .bold))
                        .foregroundColor(pressurePercentage == 100 ? PipeworkTheme.pressureGreen : PipeworkTheme.textMain)
                }

                // 4pt Pressure Meter Track Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Inset Track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(red: 20/255, green: 26/255, blue: 34/255))
                            .frame(height: 4)

                        // Filled Progress
                        let fillWidth = max(0, min(geo.size.width, geo.size.width * CGFloat(pressurePercentage) / 100.0))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: pressurePercentage == 100
                                        ? [Color(red: 16/255, green: 185/255, blue: 129/255), PipeworkTheme.pressureGreen]
                                        : [Color(red: 15/255, green: 163/255, blue: 163/255), PipeworkTheme.primaryCyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: fillWidth, height: 4)
                            .shadow(
                                color: pressurePercentage == 100
                                    ? PipeworkTheme.pressureGreen.opacity(0.6)
                                    : PipeworkTheme.primaryCyan.opacity(0.5),
                                radius: 4
                            )
                            .animation(.easeOut(duration: 0.3), value: pressurePercentage)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 11/255, green: 14/255, blue: 18/255)) // #0B0E12
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(PipeworkTheme.borderDim, lineWidth: 1)
                )
        )
    }
}
