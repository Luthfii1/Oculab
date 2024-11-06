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

    func handleSubmit() {
        if let fileURL = recordVideo {
            do {
                let videoData = try Data(contentsOf: fileURL)
                print("Video data loaded successfully with size: \(videoData.count) bytes")

                interactor.submitExamination(
                    examVideo: videoData,
                    examinationId: examDetailData.examinationId,
                    patientId: patientDetailData.patientId
                ) { result in
                    switch result {
                    case let .success(response):
                        print("Examination submitted successfully with response: \(response)")
                    case let .failure(error):
                        print("Failed to submit examination: \(error)")
                    }
                }

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

    func analysisResult(examinationId: String) {
        Router.shared.navigateTo(.analysisResult(examinationId: examinationId))
    }

    func fetchData(examId: String, patientId: String) {
        isLoading = true

        print(isLoading)

        interactor.getExamById(examId: examId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false

                switch result {
                case let .success(examination):
                    self?.examDetailData = examination

                case let .failure(error):
                    print("error: ", error.localizedDescription)
                }
            }
        }

        interactor.getPatientById(patientId: patientId) { [weak self] result in
            switch result {
            case let .success(patient):
                self?.patientDetailData = patient

            case let .failure(error):
                print("error: ", error.localizedDescription)
            }
        }
    }
}
