//
//  AnalyzingExaminationProgressView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 17/04/25.
//

import SwiftUI

struct AnalyzingExaminationProgressView: View {
    var examinationId: String
    @EnvironmentObject private var presenter: AnalysisResultPresenter

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.2)

                LottieHelper(animationName: AppText.Examination.ProgressView.loadingAnimationName)
                    .frame(width: 84, height: 84)
                    .padding(.bottom, 72)

                Text(AppText.Examination.ProgressView.analyzingTitle)
                    .font(AppTypography.h2)
                    .padding(.bottom, 12)

                Text(AppText.Examination.ProgressView.refreshInstruction)
                    .font(AppTypography.p3)

                Spacer()
            }
        }
        .refreshable {
            Task {
                await presenter.getStatusExamination(examinationId: examinationId)
            }
        }
    }
}

#Preview {
    AnalyzingExaminationProgressView(examinationId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2")
        .environmentObject(DependencyInjection.shared)
}

// TODO: Change this component if the websocket has ready
// // Loading percentage component
// // TODO: Implement with websocket
// ZStack {
//     Circle()
//         .stroke(lineWidth: 12)
//         .opacity(0.3)
//         .foregroundColor(AppColors.purple50)

//     Circle()
//         .trim(from: 0.0, to: 0.8)
//         .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
//         .foregroundColor(AppColors.purple500)
//         .rotationEffect(Angle(degrees: 270.0))
//         .animation(.linear, value: 0.8)

//     Text("80%")
//         .font(.system(size: 32, weight: .bold))
//         .foregroundStyle(AppColors.purple500)
// }
// .frame(width: 120, height: 120)
// .padding(.bottom, 40)
// Loading animation component
