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
                    AppCard(icon: AppText.Icon.preparationSectionIcon, title: AppTextVideoRecordInstruction.preparationSectionTitle, spacing: Decimal.d16) {
                        VStack(alignment: .leading, spacing: Decimal.d16) {
                            ForEach(videoRecordPresenter.preRecordingInstructions, id: \.self) { instruction in
                                HStack(alignment: .top) {
                                    Text("•")
                                    Text(instruction)
                                }
                            }
                        }
                        .padding(.leading, Decimal.d12)
                        .font(AppTypography.p3)
                    }

                    AppCard(icon: AppText.Icon.cameraFill, title: AppTextVideoRecordInstruction.recordingSectionTitle, spacing: Decimal.d16) {
                        VStack(spacing: Decimal.d16) {
                            ForEach(videoRecordPresenter.duringRecordingInstructions.indices, id: \.self) { index in
                                if index == 2 {
                                    Image("Instruction")
                                }
                                HStack(alignment: .top) {
                                    Text("•")
                                    Text(videoRecordPresenter.duringRecordingInstructions[index])
                                }
                            }
                        }
                        .padding(.leading, Decimal.d12)
                        .font(AppTypography.p3)
                    }

                    AppButton(
                        title: AppTextVideoRecordInstruction.startRecordingButton,
                        leftIcon: AppText.Icon.camera, // Optional left icon
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
                            Image("back")
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    InstructionRecordView()
}
