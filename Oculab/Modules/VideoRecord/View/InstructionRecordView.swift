//
//  InstructionRecordView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct InstructionRecordView: View {
    let videoRecordPresenter = VideoRecordPresenter.shared

    var body: some View {
        NavigationView {
            ScrollView {
                Spacer().frame(height: Decimal.d12)
                VStack(spacing: Decimal.d24) {
                    AppCard(
                        icon: AppIcon.preparationSection,
                        title: AppTextVideoRecordInstruction.preparationSectionTitle,
                        spacing: Decimal.d16
                    ) {
                        VStack(alignment: .leading, spacing: Decimal.d16) {
                            ForEach(videoRecordPresenter.preRecordingInstructions, id: \.self) { instruction in
                                HStack(alignment: .top) {
                                    Text(AppValue.bullet)
                                    Text(instruction)
                                }
                            }
                        }
                        .padding(.leading, Decimal.d12)
                        .font(AppTypography.p3)
                    }

                    AppCard(
                        icon: AppIcon.cameraFill,
                        title: AppTextVideoRecordInstruction.recordingSectionTitle,
                        spacing: Decimal.d16
                    ) {
                        VStack(spacing: Decimal.d16) {
                            ForEach(videoRecordPresenter.duringRecordingInstructions.indices, id: \.self) { index in
                                if index == 2 {
                                    Image(AppImage.instruction)
                                }
                                HStack(alignment: .top) {
                                    Text(AppValue.bullet)
                                    Text(videoRecordPresenter.duringRecordingInstructions[index])
                                }
                            }
                        }
                        .padding(.leading, Decimal.d12)
                        .font(AppTypography.p3)
                    }

                    AppButton(
                        title: AppTextVideoRecordInstruction.startRecordingButton,
                        leftIcon: AppIcon.camera, // Optional left icon
                        colorType: .primary, // Primary button type
                        size: .large,
                        isEnabled: true
                    ) {
                        videoRecordPresenter.navigateToVideo()
                    }
                }
                .padding(.horizontal, Decimal.d20)
            }
            .navigationTitle(AppTextVideoRecordInstruction.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
                    }) {
                        HStack {
                            Image(AppIcon.back)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

//#Preview {
//    InstructionRecordView()
//}
