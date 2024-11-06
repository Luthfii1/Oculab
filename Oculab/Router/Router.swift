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
//        case newExam
        case examDetail(examId: String, patientId: String)
        case savedResult(examId: String, patientId: String)
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
//        case .newExam:
//            ExamDataView()
        case let .examDetail(examId, patientId): // Corrected to use `let examId`
            ExamDetailView(examId: examId, patientId: patientId)
        case let .savedResult(examId, patientId):
            SavedResultView(examId: examId, patientId: patientId)
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
