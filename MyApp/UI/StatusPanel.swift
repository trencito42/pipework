import SwiftUI

/// Elegant, minimalist HUD bar displaying Lines, Moves, and an integrated inline Pressure gauge.
public struct StatusPanel: View {
    public let connectedLines: Int
    public let totalLines: Int
    public let moves: Int
    public let pressurePercentage: Int

    public var body: some View {
        HStack(spacing: 0) {
            // 1. Lines Metric
            HStack(spacing: 6) {
                Circle()
                    .fill(connectedLines == totalLines ? PipeworkTheme.pressureGreen : PipeworkTheme.primaryCyan)
                    .frame(width: 7, height: 7)

                VStack(alignment: .leading, spacing: 1) {
                    Text("LINES")
                        .font(PipeworkTheme.captionFont(size: 9, weight: .bold))
                        .foregroundColor(PipeworkTheme.textMuted)
                        .tracking(1.0)

                    HStack(spacing: 2) {
                        Text("\(connectedLines)")
                            .font(PipeworkTheme.statNumberFont(size: 16, weight: .bold))
                            .foregroundColor(connectedLines == totalLines ? PipeworkTheme.pressureGreen : PipeworkTheme.textMain)
                        Text("/\(totalLines)")
                            .font(PipeworkTheme.captionFont(size: 13, weight: .medium))
                            .foregroundColor(PipeworkTheme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Divider
            Capsule()
                .fill(PipeworkTheme.borderSubtle)
                .frame(width: 1, height: 24)

            // 2. Moves Metric
            VStack(spacing: 1) {
                Text("MOVES")
                    .font(PipeworkTheme.captionFont(size: 9, weight: .bold))
                    .foregroundColor(PipeworkTheme.textMuted)
                    .tracking(1.0)

                Text("\(moves)")
                    .font(PipeworkTheme.statNumberFont(size: 16, weight: .bold))
                    .foregroundColor(PipeworkTheme.textMain)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // Divider
            Capsule()
                .fill(PipeworkTheme.borderSubtle)
                .frame(width: 1, height: 24)

            // 3. Pressure Metric & Inline Gauge
            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    Text("PRESSURE")
                        .font(PipeworkTheme.captionFont(size: 9, weight: .bold))
                        .foregroundColor(PipeworkTheme.textMuted)
                        .tracking(1.0)

                    Text("\(pressurePercentage)%")
                        .font(PipeworkTheme.statNumberFont(size: 14, weight: .bold))
                        .foregroundColor(pressurePercentage == 100 ? PipeworkTheme.pressureGreen : PipeworkTheme.textMain)
                }

                // Inline Gauge Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(PipeworkTheme.surfaceSubtle)
                            .frame(height: 4)

                        let fillWidth = max(0, min(geo.size.width, geo.size.width * CGFloat(pressurePercentage) / 100.0))
                        Capsule()
                            .fill(pressurePercentage == 100 ? PipeworkTheme.pressureGreen : PipeworkTheme.primaryCyan)
                            .frame(width: fillWidth, height: 4)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: pressurePercentage)
                    }
                }
                .frame(height: 4)
                .frame(width: 76)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium)
                .fill(PipeworkTheme.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium)
                        .stroke(PipeworkTheme.borderSubtle, lineWidth: 1)
                )
        )
    }
}
