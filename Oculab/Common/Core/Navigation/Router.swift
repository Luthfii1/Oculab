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
        case pdf(examinationId: String)
        case analysisResult(examinationId: String)
        case examDetail(examId: String, patientId: String)
        case examDetailAdmin(examId: String, patientId: String)
        case savedResult(examId: String, patientId: String)
        case newExam(patientId: String, picId: String)
        case userAccessPin(state: PinMode)
        case login
        case photoAlbum(fovGroup: FOVType, examId: String)
        case detailedPhoto(slideId: String, fovData: FOVData, order: Int, total: Int, examId: String?)
        case profile
        case editPassword
        case inputPatientData(patientId: String? = nil)
        case informationInterpretation
        case privacyPolicy
        case analyzingStatusProgress(examinationId: String)
        case accountManagement
        case newAccount
        case editAccount(account: Account)
        case patientList
        case patientForm(patientId: String? = nil)
        case patientDetail(patientId: String)
    }

    @Published var path: NavigationPath = .init()

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .home:
            HomeView()
        case .videoRecord:
            VideoRecordView()
        case let .pdf(examinationId):
            PDFPageView(examinationId: examinationId)
        case let .analysisResult(examinationId):
            AnalysisResultView(examinationId: examinationId)
        case let .examDetail(examId, patientId):
            ExamDetailView(examId: examId, patientId: patientId)
        case let .examDetailAdmin(examId: examId, patientId: patientId):
            ExamDetailAdminView(examId: examId, patientId: patientId)
        case let .savedResult(examId, patientId):
            SavedResultView(examId: examId, patientId: patientId)
        case let .newExam(patientId, picId):
            InputExaminationData(selectedPIC: picId, selectedPatient: patientId)
        case let .userAccessPin(state):
            UserAccessPinView(state: state)
                .environmentObject(DependencyInjection.shared.createAuthPresenter())
        case .login:
            LoginView()
                .environmentObject(DependencyInjection.shared.createAuthPresenter())
        case let .photoAlbum(fovGroup, examId):
            FOVAlbum(fovGroup: fovGroup, examId: examId)
        case let .detailedPhoto(slideId, fovData, order, total, examId):
            FOVDetail(slideId: slideId, fovData: fovData, order: order, total: total, examId: examId)
        case .profile:
            ProfileView()
                .environmentObject(DependencyInjection.shared.createProfilePresenter())
        case .editPassword:
            EditPasswordView()
                .environmentObject(DependencyInjection.shared.createProfilePresenter())
        case .inputPatientData(let patientId):
            InputPatientData(patientId: patientId)
        case .informationInterpretation:
            InformationPage()
        case .privacyPolicy:
            PrivacyPolicyView()
        case let .analyzingStatusProgress(examinationId):
            AnalyzingExaminationProgressView(examinationId: examinationId)
        case .accountManagement:
            UserManagementView()
                .environmentObject(DependencyInjection.shared.createAccountPresenter())
        case .newAccount:
            NewUserFormView()
                .environmentObject(DependencyInjection.shared.createAccountPresenter())
        case let .editAccount(account):
            EditUserFormView(account: account)
                .environmentObject(DependencyInjection.shared.createAccountPresenter())
        case .patientList:
            PatientListView()
        case .patientForm(let patientId):
            PatientFormView(patientId: patientId)
        case let .patientDetail(patientId):
            PatientDetailView(patientId: patientId)
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
