//
//  ExamPresenter.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import SwiftUI

class ExamDataPresenter: ObservableObject {
    let videoPresenter = VideoRecordPresenter.shared

    @Published var examData: ExaminationRequest = .init(
        examinationId: UUID().uuidString,
        goal: "",
        preparationType: "",
        slideId: "",
        recordVideo: nil
    )

    //    @Published var idSediaan: String = ""
//    @Published var selectedGoal: String = ""
//    @Published var selectedPreparationType: String = ""

    private let interactor: ExamInteractor

    init(interactor: ExamInteractor) {
        self.interactor = interactor
    }

//    func handleSubmit() {
    ////        let goal = examData.goal == "Skrinning" ? "SCREENING" : "FOLLOWUP"
    ////        let preparationType = examData.preparationType == "Pagi" ? "SPS" : "SP"
//
    ////        let examRequest = ExaminationRequest(
    ////            examinationId: UUID().uuidString,
    ////            goal: goal,
    ////            preparationType: preparationType,
    ////            slideId: idSediaan,
    ////            recordVideo: ""
    ////        )
//
//        interactor.submitExamination(examData: examData, completion: <#(Result<VideoForwardResponse, NetworkErrorType>) -> Void#>)
//    }

    func handleSubmit(completion: @escaping (Result<ExaminationResponse, NetworkErrorType>) -> Void) {
        interactor.submitExamination(examData: examData) { result in
            switch result {
            case let .success(response):
                print("Examination submitted successfully with response: \(response)")
                completion(.success(response))
            case let .failure(error):
                print("Failed to submit examination: \(error)")
                completion(.failure(error))
            }
        }
    }

    func saveVideo() {
        examData.examination.recordVideo = videoPresenter.previewURL
    }

    func newVideoRecord() {
        Router.shared.navigateTo(.videoRecord)
    }
}
