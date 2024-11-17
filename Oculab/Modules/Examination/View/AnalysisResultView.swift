//
//  AnalysisResultView.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct AnalysisResultView: View {
    var examinationId: String

    @StateObject private var presenter = AnalysisResultPresenter()

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    HeaderViewComponent(isLeavePopUpVisible: $presenter.isLeavePopUpVisible)

                    AppStepper(
                        stepTitles: ["Data Pemeriksaan", "Hasil Pemeriksaan"],
                        currentStep: 1
                    )
                    .padding(.vertical, Decimal.d16)

                    if let errorMessage = presenter.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else if let examination = presenter.examinationResult {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: Decimal.d24) {
                                ImageSectionComponent(presenter: presenter, examination: examination)
                                InterpretationSectionComponent(
                                    examination: examination,
                                    presenter: presenter,
                                    selectedTBGrade: $presenter.selectedTBGrade,
                                    numOfBTA: $presenter.numOfBTA,
                                    inspectorNotes: $presenter.inspectorNotes,
                                    isVerifPopUpVisible: $presenter.isVerifPopUpVisible
                                )
                            }
                        }
                    } else {
                        Spacer()
                        Text("Loading examination data...")
                            .foregroundColor(.gray)
                            .padding()
                        Spacer()
                    }
                }
                .onAppear {
                    Task {
                        await presenter.fetchData(examinationId: examinationId)
                    }
                }

                Spacer()

                ConfirmationPopups()
                    .environmentObject(presenter)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AnalysisResultView(examinationId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2")
}
