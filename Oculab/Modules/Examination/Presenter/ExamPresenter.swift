//
//  ExamPresenter.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import SwiftUI

class ExamDataPresenter: ObservableObject {
    let videoPresenter = VideoRecordPresenter.shared

    @Published var isLoading: Bool = false

    @Published var recordVideo: URL?

    @Published var examDetailData: ExaminationDetailData = .init(
        examinationId: "",
        pic: "",
        slideId: "",
        examinationGoal: "",
        type: "",
        dpjp: ""
    )
    @Published var patientDetailData: PatientDetailData = .init(
        patientId: "",
        name: "",
        nik: "",
        dob: "",
        sex: "",
        bpjs: ""
    )

    private let interactor: ExamInteractor

    init(interactor: ExamInteractor) {
        self.interactor = interactor
    }

    @MainActor
    func handleSubmit() async {
        if let fileURL = recordVideo {
            do {
                let videoData = try Data(contentsOf: fileURL)
                print("Video data loaded successfully with size: \(videoData.count) bytes")

                let response = try await interactor.submitExamination(
                    examVideo: videoData,
                    examinationId: examDetailData.examinationId,
                    patientId: patientDetailData.patientId
                )

                print("Examination submitted successfully with response: \(response)")
            } catch {
                print("Error loading video data: \(error)")
            }
        }
    }

    func saveVideo() {
        recordVideo = videoPresenter.previewURL
    }

    func newVideoRecord() {
        Router.shared.navigateTo(.videoRecord)
    }

    func navigateToAnalysisResult(examinationId: String) {
        Router.shared.navigateTo(.analysisResult(examinationId: examinationId))
    }

    @MainActor
    func fetchData(examId: String, patientId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let examinationResponse = try await interactor.getExamById(examId: examId)
            let patientResponse = try await interactor.getPatientById(patientId: patientId)

            examDetailData = examinationResponse
            patientDetailData = patientResponse

        } catch {
            // Handle error
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
        }
    }
}
