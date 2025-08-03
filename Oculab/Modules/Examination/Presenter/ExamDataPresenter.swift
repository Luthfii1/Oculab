//
//  ExamDataPresenter.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import SwiftUI

class ExamDataPresenter: ObservableObject {
    let videoPresenter = VideoRecordPresenter.shared
    @Published var isLoading: Bool = false {
        didSet {
            if isLoading {
                buttonTitle = "Submitting..."
            } else {
                buttonTitle = "Mulai Analisis"
            }
        }
    }

    @Published var recordVideo: URL?
    @Published var buttonTitle: String = "Mulai Analisis"

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
    
    @Published var examinations: [AdminExaminationData] = []

    private let interactor: ExamInteractor

    init(interactor: ExamInteractor) {
        self.interactor = interactor
    }

    func buttonEnabled() -> Bool {
        return (recordVideo != nil) && !isLoading
    }

    @MainActor
    func handleSubmit() async {
        isLoading = true
        defer { isLoading = false }

        guard let fileURL = recordVideo else {
            print("Submit button was pressed but recordVideo URL is nil.")
            return
        }

        do {
            let videoData = try Data(contentsOf: fileURL)
            print("Video data loaded successfully with size: \(videoData.count) bytes")

            let response = try await interactor.submitExamination(
                examVideo: videoData,
                examinationId: examDetailData.examinationId,
                patientId: patientDetailData.patientId
            )

            print("Examination submitted successfully with response: \(response)")

            recordVideo = nil
            videoPresenter.previewURL = nil
            deleteTemporaryFile(at: fileURL)

        } catch {
            print("Error submitting or loading video data: \(error)")
        }
    }

    func deleteTemporaryFile(at url: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
                print("Successfully deleted temporary video file at: \(url.path)")
            } catch {
                print("Error deleting temporary video file: \(error.localizedDescription)")
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
    func fetchData(examId: String, patientId: String, userRole: RolesType) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let patientResponse = try await interactor.getPatientById(patientId: patientId)
            patientDetailData = patientResponse
            
            if userRole == .ADMIN {
                // Fetch admin examination detail data
                let examinationResponse = try await interactor.getAdminExamDetail(observationId: examId)
                examinations = examinationResponse.examinations
                
                // Map admin data to examDetailData for compatibility
                examDetailData = ExaminationDetailData(
                    examinationId: examinationResponse.observationId,
                    pic: examinationResponse.picName,
                    slideId: examinationResponse.examinations.first?.slideId ?? "",
                    examinationGoal: examinationResponse.goal,
                    type: examinationResponse.examinations.first?.preparationType ?? "",
                    dpjp: examinationResponse.dpjpName
                )
            } else {
                // Fetch regular examination data for LAB users
                let examinationResponse = try await interactor.getExamById(examId: examId)
                examDetailData = examinationResponse
                examinations = []
            }
            
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
