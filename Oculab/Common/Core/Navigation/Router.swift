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
        case videoRecord(slideId: String)
        case pdf(examinationId: String)
        case analysisResult(examinationId: String)
        case examDetail(examId: String, patientId: String)
        case examDetailAdmin(examId: String, patientId: String)
        case savedResult(examId: String, patientId: String)
        case newExam(patientId: String, picId: String)
        case userAccessPin(state: PinMode)
        case login
        case register
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
        
        // MARK: - Route Properties
        var requiresAuthentication: Bool {
            switch self {
            case .login, .register:
                return false
            default:
                return true
            }
        }
        
        var routeIdentifier: String {
            switch self {
            case .home: return "home"
            case .videoRecord: return "video-record"
            case .pdf: return "pdf"
            case .analysisResult: return "analysis-result"
            case .examDetail: return "exam-detail"
            case .examDetailAdmin: return "exam-detail-admin"
            case .savedResult: return "saved-result"
            case .newExam: return "new-exam"
            case .userAccessPin: return "user-access-pin"
            case .login: return "login"
            case .register: return "register"
            case .photoAlbum: return "photo-album"
            case .detailedPhoto: return "detailed-photo"
            case .profile: return "profile"
            case .editPassword: return "edit-password"
            case .inputPatientData: return "input-patient-data"
            case .informationInterpretation: return "information-interpretation"
            case .privacyPolicy: return "privacy-policy"
            case .analyzingStatusProgress: return "analyzing-status-progress"
            case .accountManagement: return "account-management"
            case .newAccount: return "new-account"
            case .editAccount: return "edit-account"
            case .patientList: return "patient-list"
            case .patientForm: return "patient-form"
            case .patientDetail: return "patient-detail"
            }
        }
    }

    @Published var path: NavigationPath = .init()
    @Published var currentRoute: Route?

    /// Shared wizard state for patient → specimen task assignment.
    private(set) var taskAssignmentFlow: TaskAssignmentFlowCoordinator?

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .home:
            HomeView()
        case let .videoRecord(slideId):
            VideoRecordView(slideId: slideId)
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
            taskAssignmentExaminationView(patientId: patientId, picId: picId)
        case let .userAccessPin(state):
            UserAccessPinView(state: state)
                .environmentObject(DependencyInjection.shared.createAuthPresenter())
        case .login:
            LoginView()
                .environmentObject(DependencyInjection.shared.createAuthPresenter())
        case .register:
            RegisterUserView()
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
            taskAssignmentPatientView(patientId: patientId)
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
        DispatchQueue.main.async {
            self.prepareFlowSession(for: appRoute)
            self.currentRoute = appRoute
            self.path.append(appRoute)
            Logger.info("Navigated to: \(appRoute.routeIdentifier)", category: .navigation)
        }
    }

    private func prepareFlowSession(for route: Route) {
        switch route {
        case .inputPatientData(let patientId):
            beginTaskAssignmentFlow(prefillPatientId: patientId)
        case let .newExam(patientId, picId):
            if taskAssignmentFlow == nil {
                let flow = beginTaskAssignmentFlow(prefillPatientId: patientId)
                flow.attachSpecimenRouteContext(patientId: patientId, picId: picId)
            }
        default:
            break
        }
    }

    func navigateBack() {
        DispatchQueue.main.async {
            if !self.path.isEmpty {
                self.path.removeLast()
                Logger.info("Navigated back", category: .navigation)
            }
        }
    }

    func popToRoot() {
        DispatchQueue.main.async {
            let countToRemove = self.path.count
            if countToRemove > 0 {
                self.path.removeLast(countToRemove)
                self.currentRoute = nil
                Logger.info("Popped to root, removed \(countToRemove) routes", category: .navigation)
            }
            self.endTaskAssignmentFlow()
        }
    }

    // MARK: - Task assignment flow session

    @discardableResult
    func beginTaskAssignmentFlow(prefillPatientId: String? = nil) -> TaskAssignmentFlowCoordinator {
        let flow = TaskAssignmentFlowCoordinator(prefillPatientId: prefillPatientId)
        taskAssignmentFlow = flow
        return flow
    }

    func obtainTaskAssignmentFlow(prefillPatientId: String? = nil) -> TaskAssignmentFlowCoordinator {
        if let taskAssignmentFlow {
            return taskAssignmentFlow
        }
        return beginTaskAssignmentFlow(prefillPatientId: prefillPatientId)
    }

    func endTaskAssignmentFlow() {
        taskAssignmentFlow = nil
    }

    @ViewBuilder
    private func taskAssignmentPatientView(patientId: String?) -> some View {
        if let flow = taskAssignmentFlow {
            InputPatientData(patientId: patientId, flow: flow)
                .environmentObject(flow)
                .environmentObject(flow.validationManager)
        } else {
            ProgressView()
        }
    }

    @ViewBuilder
    private func taskAssignmentExaminationView(patientId: String, picId: String) -> some View {
        if let flow = taskAssignmentFlow {
            InputExaminationData(flow: flow)
                .environmentObject(flow)
                .environmentObject(flow.validationManager)
        } else {
            ProgressView()
        }
    }
    
    // MARK: - Deeplink Support
    func generateDeeplinkURL(for route: Route) -> URL? {
        var components = URLComponents()
        components.scheme = "oculab"
        
        switch route {
        case .home:
            components.path = "/home"
            
        case .login:
            components.path = "/login"
            
        case .register:
            components.path = "/register"
            
        case .profile:
            components.path = "/profile"
            
        case .examDetail(let examId, let patientId):
            components.path = "/exam-detail"
            components.queryItems = [
                URLQueryItem(name: "examId", value: examId),
                URLQueryItem(name: "patientId", value: patientId)
            ]
            
        case .newExam(let patientId, let picId):
            components.path = "/new-exam"
            components.queryItems = [
                URLQueryItem(name: "patientId", value: patientId),
                URLQueryItem(name: "picId", value: picId)
            ]
            
        case .patientDetail(let patientId):
            components.path = "/patient-detail"
            components.queryItems = [
                URLQueryItem(name: "patientId", value: patientId)
            ]
            
        case .analysisResult(let examinationId):
            components.path = "/analysis-result"
            components.queryItems = [
                URLQueryItem(name: "examinationId", value: examinationId)
            ]
            
        case .videoRecord(let slideId):
            components.path = "/video-record"
            components.queryItems = [
                URLQueryItem(name: "slideId", value: slideId)
            ]
            
        default:
            return nil
        }
        
        return components.url
    }
    
    func canNavigateToRoute(_ route: Route) -> Bool {
        if route.requiresAuthentication {
            let isLoggedIn = UserDefaults.standard.bool(forKey: UserDefaultType.isUserLoggedIn.rawValue)
            let isPinSessionAuthorized = UserDefaults.standard.bool(
                forKey: UserDefaultType.isPinSessionAuthorized.rawValue
            )
            return isLoggedIn && isPinSessionAuthorized
        }
        return true
    }
}
