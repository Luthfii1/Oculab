//
//  Router.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Combine
import Foundation
import SwiftUI

class Router: ObservableObject {
    static let shared = Router()

    enum Route: Equatable, Hashable {
        case home
        case videoRecord
        case pdf
        case analysisResult(examinationId: String)
        case instructionRecord
        case examDetail(examId: String, patientId: String)
        case savedResult(examId: String, patientId: String)
        case newExam(patientId: String, picId: String)
        case userAccessPin(title: String, description: String)
        case login
        case photoAlbum(fovGroup: FOVType, examId: String)
        case detailedPhoto(slideId: String, fovData: FOVData, order: Int, total: Int)
    }

    @Published var path: NavigationPath = .init()

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .home:
            HomeView()
        case .videoRecord:
            VideoRecordView()
        case .pdf:
            PDFPageView()
        case let .analysisResult(examinationId):
            AnalysisResultView(examinationId: examinationId)
        case .instructionRecord:
            InstructionRecordView()
        case let .examDetail(examId, patientId):
            ExamDetailView(examId: examId, patientId: patientId)
        case let .savedResult(examId, patientId):
            SavedResultView(examId: examId, patientId: patientId)
        case let .newExam(patientId, picId):
            InputExaminationData(selectedPIC: picId, selectedPatient: patientId)
        case let .userAccessPin(title, description):
            UserAccessPin(title: title, description: description)
        case .login:
            LoginView()
        case let .photoAlbum(fovGroup, examId):
            FOVAlbum(fovGroup: fovGroup, examId: examId)
        case let .detailedPhoto(slideId, fovData, order, total):
            FOVDetail(slideId: slideId, fovData: fovData, order: order, total: total)
        }
    }

    func navigateTo(_ appRoute: Route) {
        path.append(appRoute)
    }

    func navigateBack() {
        path.removeLast()
    }

    func popToRoot() {
        DispatchQueue.main.async {
            self.path.removeLast(self.path.count)
        }
    }
}
