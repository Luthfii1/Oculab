//
//  AnalyzingExaminationProgressView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 17/04/25.
//

import SwiftUI

struct AnalyzingExaminationProgressView: View {
    var body: some View {
        VStack {
            Spacer()

            // Loading percentage component
            // TODO: Implement with websocket
            ZStack {
                Circle()
                    .stroke(lineWidth: 12)
                    .opacity(0.3)
                    .foregroundColor(AppColors.purple50)

                Circle()
                    .trim(from: 0.0, to: 0.8)
                    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                    .foregroundColor(AppColors.purple500)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: 0.8)

                Text("80%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppColors.purple500)
            }
            .frame(width: 120, height: 120)
            .padding(.bottom, 40)

            Text("Menginterpretasikan data")
                .font(AppTypography.h2)

            Spacer()
        }
    }
}

#Preview {
    AnalyzingExaminationProgressView()
}
