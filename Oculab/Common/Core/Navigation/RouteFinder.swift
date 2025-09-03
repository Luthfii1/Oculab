//
//  RouteFinder.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 03/09/25.
//

import Foundation
import SwiftUI

// MARK: - Deeplink Types
enum DeeplinkType: String, CaseIterable {
    case home = "home"
    case login = "login"
    case register = "register"
    case profile = "profile"
    case examDetail = "exam-detail"
    case newExam = "new-exam"
    case patientDetail = "patient-detail"
    case patientList = "patient-list"
    case analysisResult = "analysis-result"
    case videoRecord = "video-record"
//    case photoAlbum = "photo-album"
    case accountManagement = "account-management"
    case userAccessPin = "user-access-pin"
    
    var displayName: String {
        switch self {
        case .home: return "Home"
        case .login: return "Login"
        case .register: return "Register"
        case .profile: return "Profile"
        case .examDetail: return "Exam Detail"
        case .newExam: return "New Exam"
        case .patientDetail: return "Patient Detail"
        case .patientList: return "Patient List"
        case .analysisResult: return "Analysis Result"
        case .videoRecord: return "Video Record"
//        case .photoAlbum: return "Photo Album"
        case .accountManagement: return "Account Management"
        case .userAccessPin: return "User Access PIN"
        }
    }
}

// MARK: - Deeplink Parameters
struct DeeplinkParameters {
    let examId: String?
    let patientId: String?
    let slideId: String?
    let examinationId: String?
    let picId: String?
    let fovGroup: String?
    let pinState: String?
    let accountId: String?
    
    init(queryItems: [URLQueryItem]) {
        self.examId = queryItems.first(where: { $0.name == "examId" })?.value
        self.patientId = queryItems.first(where: { $0.name == "patientId" })?.value
        self.slideId = queryItems.first(where: { $0.name == "slideId" })?.value
        self.examinationId = queryItems.first(where: { $0.name == "examinationId" })?.value
        self.picId = queryItems.first(where: { $0.name == "picId" })?.value
        self.fovGroup = queryItems.first(where: { $0.name == "fovGroup" })?.value
        self.pinState = queryItems.first(where: { $0.name == "pinState" })?.value
        self.accountId = queryItems.first(where: { $0.name == "accountId" })?.value
    }
}

// MARK: - Deeplink Result
enum DeeplinkResult {
    case success(Router.Route)
    case authenticationRequired
    case invalidURL
    case missingParameters(String)
    case unsupportedRoute
    
    var errorMessage: String? {
        switch self {
        case .success:
            return nil
        case .authenticationRequired:
            return "Authentication required to access this content"
        case .invalidURL:
            return "Invalid URL format"
        case .missingParameters(let params):
            return "Missing required parameters: \(params)"
        case .unsupportedRoute:
            return "Unsupported route"
        }
    }
}

// MARK: - Route Finder Class
class RouteFinder: ObservableObject {
    static let shared = RouteFinder()
    
    @Published var pendingDeeplink: Router.Route?
    @Published var deeplinkError: String?
    
    private let urlScheme = "oculab"
    private let host = "app"
    
    private init() {}
    
    // MARK: - Main Deeplink Processing
    func processDeeplink(_ url: URL) -> DeeplinkResult {
        Logger.info("Processing deeplink: \(url.absoluteString)", category: .navigation)
        
        // Validate URL scheme
        guard url.scheme?.lowercased() == urlScheme else {
            Logger.error("Invalid URL scheme: \(url.absoluteString)", category: .navigation)
            return .invalidURL
        }
        
        // Handle both formats: oculab://register and oculab://app/register
        let routeComponent: String
        if let host = url.host, !host.isEmpty {
            // Format: oculab://register (host is the route)
            routeComponent = host
        } else {
            // Format: oculab://app/register (path is the route)
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            guard let firstComponent = pathComponents.first else {
                Logger.error("No route component found: \(url.absoluteString)", category: .navigation)
                return .unsupportedRoute
            }
            routeComponent = firstComponent
        }
        
        guard let deeplinkType = DeeplinkType(rawValue: routeComponent) else {
            Logger.error("Unsupported route: \(routeComponent)", category: .navigation)
            return .unsupportedRoute
        }
        
        // Extract query parameters
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let parameters = DeeplinkParameters(queryItems: queryItems)
        
        // Route to appropriate handler
        return routeToDestination(type: deeplinkType, parameters: parameters)
    }
    
    // MARK: - Route Resolution
    private func routeToDestination(type: DeeplinkType, parameters: DeeplinkParameters) -> DeeplinkResult {
        switch type {
        case .home:
            if !isUserAuthenticated() {
                return .authenticationRequired
            }
            return .success(.home)
            
        case .login:
            return .success(.login)
            
        case .register:
            return .success(.register)
            
        case .profile:
            if !isUserAuthenticated() {
                return .authenticationRequired
            }
            return .success(.profile)
            
        case .examDetail:
            return handleExamDetailRoute(parameters: parameters)
            
        case .newExam:
            return handleNewExamRoute(parameters: parameters)
            
        case .patientDetail:
            return handlePatientDetailRoute(parameters: parameters)
            
        case .patientList:
            if !isUserAuthenticated() {
                return .authenticationRequired
            }
            return .success(.patientList)
            
        case .analysisResult:
            return handleAnalysisResultRoute(parameters: parameters)
            
        case .videoRecord:
            return handleVideoRecordRoute(parameters: parameters)
            
//        case .photoAlbum:
//            return handlePhotoAlbumRoute(parameters: parameters)
            
        case .accountManagement:
            if !isUserAuthenticated() {
                return .authenticationRequired
            }
            return .success(.accountManagement)
            
        case .userAccessPin:
            return handleUserAccessPinRoute(parameters: parameters)
        }
    }
    
    // MARK: - Route Handlers
    private func handleExamDetailRoute(parameters: DeeplinkParameters) -> DeeplinkResult {
        guard let examId = parameters.examId,
              let patientId = parameters.patientId else {
            return .missingParameters("examId, patientId")
        }
        
        if !isUserAuthenticated() {
            return .authenticationRequired
        }
        
        return .success(.examDetail(examId: examId, patientId: patientId))
    }
    
    private func handleNewExamRoute(parameters: DeeplinkParameters) -> DeeplinkResult {
        guard let patientId = parameters.patientId,
              let picId = parameters.picId else {
            return .missingParameters("patientId, picId")
        }
        
        if !isUserAuthenticated() {
            return .authenticationRequired
        }
        
        return .success(.newExam(patientId: patientId, picId: picId))
    }
    
    private func handlePatientDetailRoute(parameters: DeeplinkParameters) -> DeeplinkResult {
        guard let patientId = parameters.patientId else {
            return .missingParameters("patientId")
        }
        
        if !isUserAuthenticated() {
            return .authenticationRequired
        }
        
        return .success(.patientDetail(patientId: patientId))
    }
    
    private func handleAnalysisResultRoute(parameters: DeeplinkParameters) -> DeeplinkResult {
        guard let examinationId = parameters.examinationId else {
            return .missingParameters("examinationId")
        }
        
        if !isUserAuthenticated() {
            return .authenticationRequired
        }
        
        return .success(.analysisResult(examinationId: examinationId))
    }
    
    private func handleVideoRecordRoute(parameters: DeeplinkParameters) -> DeeplinkResult {
        guard let slideId = parameters.slideId else {
            return .missingParameters("slideId")
        }
        
        if !isUserAuthenticated() {
            return .authenticationRequired
        }
        
        return .success(.videoRecord(slideId: slideId))
    }
    
//    private func handlePhotoAlbumRoute(parameters: DeeplinkParameters) -> DeeplinkResult {
//        guard let fovGroupString = parameters.fovGroup,
//              let examId = parameters.examId else {
//            return .missingParameters("fovGroup, examId")
//        }
//        
//        // Convert string to FOVType enum
//        guard let fovGroup = FOVType.fromString(fovGroupString) else {
//            return .missingParameters("valid fovGroup")
//        }
//        
//        if !isUserAuthenticated() {
//            return .authenticationRequired
//        }
//        
//        return .success(.photoAlbum(fovGroup: fovGroup, examId: examId))
//    }
    
    private func handleUserAccessPinRoute(parameters: DeeplinkParameters) -> DeeplinkResult {
        guard let pinStateString = parameters.pinState else {
            return .missingParameters("pinState")
        }
        
        // Convert string to PinMode enum
        let pinState: PinMode
        switch pinStateString.lowercased() {
        case "create":
            pinState = .create
        case "authenticate":
            pinState = .authenticate
        case "change":
            pinState = .changePIN
        case "revalidate":
            pinState = .revalidate
        case "forget":
            pinState = .forgetPin
        default:
            return .missingParameters("valid pinState (create, authenticate, change, revalidate, forget)")
        }
        
        return .success(.userAccessPin(state: pinState))
    }
    
    // MARK: - Authentication Check
    func isUserAuthenticated() -> Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultType.isUserLoggedIn.rawValue)
    }
    
    // MARK: - Navigation Helpers
    func navigateToDeeplink(_ result: DeeplinkResult) {
        DispatchQueue.main.async {
            switch result {
            case .success(let route):
                self.deeplinkError = nil
                Router.shared.navigateTo(route)
                Logger.info("Successfully navigated to deeplink route", category: .navigation)
                
            case .authenticationRequired:
                self.deeplinkError = result.errorMessage
                self.pendingDeeplink = nil
                Router.shared.navigateTo(.login)
                Logger.warning("Authentication required for deeplink", category: .navigation)
                
            default:
                self.deeplinkError = result.errorMessage
                self.pendingDeeplink = nil
                Logger.error("Failed to process deeplink: \(result.errorMessage ?? "Unknown error")", category: .navigation)
            }
        }
    }
    
    func setPendingDeeplink(_ route: Router.Route) {
        self.pendingDeeplink = route
    }
    
    func processPendingDeeplink() {
        guard let pendingRoute = pendingDeeplink else { return }
        
        DispatchQueue.main.async {
            Router.shared.navigateTo(pendingRoute)
            self.pendingDeeplink = nil
            Logger.info("Processed pending deeplink after authentication", category: .navigation)
        }
    }
    
    // MARK: - URL Generation
    func generateDeeplinkURL(for route: Router.Route) -> URL? {
        var components = URLComponents()
        components.scheme = urlScheme
        components.host = host
        
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
            
        case .patientList:
            components.path = "/patient-list"
            
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
            
//        case .photoAlbum(let fovGroup, let examId):
//            components.path = "/photo-album"
//            components.queryItems = [
//                URLQueryItem(name: "fovGroup", value: fovGroup.toString()),
//                URLQueryItem(name: "examId", value: examId)
//            ]
            
        case .accountManagement:
            components.path = "/account-management"
            
        case .userAccessPin(let state):
            components.path = "/user-access-pin"
            let stateString: String
            switch state {
            case .create: stateString = "create"
            case .authenticate: stateString = "authenticate"
            case .changePIN: stateString = "change"
            case .revalidate: stateString = "revalidate"
            case .forgetPin: stateString = "forget"
            }
            components.queryItems = [
                URLQueryItem(name: "pinState", value: stateString)
            ]
            
        default:
            return nil // Some routes might not support deeplinks
        }
        
        return components.url
    }
}

// MARK: - FOVType Extension
//extension FOVType {
//    static func fromString(_ string: String) -> FOVType? {
//        switch string.lowercased() {
//        case "central": return .central
//        case "peripheral": return .peripheral
//        case "nasal": return .nasal
//        case "temporal": return .temporal
//        default: return nil
//        }
//    }
//    
//    func toString() -> String {
//        switch self {
//        case .central: return "central"
//        case .peripheral: return "peripheral"
//        case .nasal: return "nasal"
//        case .temporal: return "temporal"
//        }
//    }
//}
