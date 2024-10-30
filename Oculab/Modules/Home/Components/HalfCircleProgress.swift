//
//  HalfCircleProgress.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 30/10/24.
//

import SwiftUI

import SwiftUI

struct HalfCircleProgress: View {
    var progress: CGFloat

    var body: some View {
        VStack {
            ZStack {
                // Background Half Circle
                HalfCircleShape()
                    .stroke(AppColors.purple50, lineWidth: 24) // Adjusted line width for smaller size
                    .rotationEffect(.degrees(0))

                // Progress Half Circle
                HalfCircleShape()
                    .trim(from: 0, to: progress)
                    .stroke(AppColors.purple500, style: StrokeStyle(lineWidth: 24))
                    .rotationEffect(.degrees(0))
                    .animation(.easeInOut, value: progress)

                // Text Display
                VStack {
                    Text("\(Int(progress * 100))%")
                        .foregroundStyle(AppColors.slate900)
                        .font(AppTypography.h6)

                    Spacer()
                }
                .frame(width: 100, height: 45)
            }
        }.frame(width: 100, height: 75)
    }
}

struct HalfCircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}

struct HalfCircleView: View {
    @State private var progress: CGFloat = 0.5 // Example: 50%

    var body: some View {
        VStack {
            HalfCircleProgress(progress: progress)

            Slider(value: $progress, in: 0...1)
                .padding()
        }
    }
}

#Preview {
    HalfCircleView()
}
