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
        case examDetailAdmin(examId: String, patientId: String)
        case savedResult(examId: String, patientId: String)
        case newExam(patientId: String, picId: String)
        case userAccessPin(state: PinMode)
        case login
        case photoAlbum(fovGroup: FOVType, examId: String)
        case detailedPhoto(slideId: String, fovData: FOVData, order: Int, total: Int)
        case profile
        case editPassword
        case inputPatientData
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
        case let .examDetailAdmin(examId: examId, patientId: patientId):
            ExamDetailAdmin(examId: examId, patientId: patientId)
        case let .savedResult(examId, patientId):
            SavedResultView(examId: examId, patientId: patientId)
        case let .newExam(patientId, picId):
            InputExaminationData(selectedPIC: picId, selectedPatient: patientId)
        case let .userAccessPin(state):
            UserAccessPin(state: state)
                .environmentObject(DependencyInjection.shared.createAuthPresenter())
        case .login:
            LoginView()
                .environmentObject(DependencyInjection.shared.createAuthPresenter())
        case let .photoAlbum(fovGroup, examId):
            FOVAlbum(fovGroup: fovGroup, examId: examId)
        case let .detailedPhoto(slideId, fovData, order, total):
            FOVDetail(slideId: slideId, fovData: fovData, order: order, total: total)
        case .profile:
            ProfileView()
                .environmentObject(DependencyInjection.shared.createProfilePresenter())
        case .editPassword:
            EditPasswordView()
                .environmentObject(DependencyInjection.shared.createProfilePresenter())
        case .inputPatientData:
            InputPatientData()
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
