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
        case analysisResult
        case instructionRecord
        case newExam
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
        case .analysisResult:
            AnalysisResultView()
        case .instructionRecord:
            InstructionRecordView()
        case .newExam:
            ExamDataView()
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
