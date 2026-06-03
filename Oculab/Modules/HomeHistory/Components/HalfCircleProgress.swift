//
//  HalfCircleProgress.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 30/10/24.
//

import SwiftUI

struct HalfCircleProgress: View {
    var progress: CGFloat

    private let lineWidth: CGFloat = 14
    private let clampedProgress: CGFloat

    init(progress: CGFloat) {
        self.progress = progress
        self.clampedProgress = min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { geometry in
            let metrics = SemicircleGaugeMetrics(size: geometry.size, lineWidth: lineWidth)
            let strokeStyle = StrokeStyle(lineWidth: lineWidth, lineCap: .round)

            ZStack {
                HalfCircleShape(lineWidth: lineWidth)
                    .stroke(AppColors.purple100, style: strokeStyle)

                HalfCircleShape(lineWidth: lineWidth)
                    .trim(from: 0, to: clampedProgress)
                    .stroke(AppColors.purple500, style: strokeStyle)
                    .animation(.easeInOut(duration: 0.35), value: clampedProgress)

                Text("\(Int(clampedProgress * 100))\(AppValue.percentage)")
                    .font(AppTypography.h4_1)
                    .foregroundStyle(AppColors.slate900)
                    .multilineTextAlignment(.center)
                    .position(metrics.labelCenter)
            }
        }
        .frame(width: 112, height: 58)
    }
}

/// Shared layout math for arc path and centered label.
private struct SemicircleGaugeMetrics {
    let center: CGPoint
    let radius: CGFloat
    let labelCenter: CGPoint

    init(size: CGSize, lineWidth: CGFloat) {
        radius = (size.width - lineWidth) / 2
        center = CGPoint(x: size.width / 2, y: size.height)
        // Centroid of a semicircle measured from the flat base (4r / 3π).
        let centroidOffset = radius * (4 / (3 * .pi))
        labelCenter = CGPoint(
            x: size.width / 2,
            y: size.height - centroidOffset
        )
    }
}

/// Semicircle arc on the bottom edge of its frame.
struct HalfCircleShape: Shape {
    var lineWidth: CGFloat = 14

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = (rect.width - lineWidth) / 2
        let center = CGPoint(x: rect.midX, y: rect.maxY)

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}

#Preview {
    HStack(spacing: 20) {
        HalfCircleProgress(progress: 0)
        HalfCircleProgress(progress: 0.5)
        HalfCircleProgress(progress: 1)
    }
    .padding()
}
