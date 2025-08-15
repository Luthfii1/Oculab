//
//  AppConstants.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/25.
//

import Foundation

// MARK: - App Constants
enum AppConstants {
    // MARK: - Timing
    static let splashScreenDuration: TimeInterval = 3.0
    static let pinLength: Int = 4
    static let animationDuration: Double = 0.3
    
    // MARK: - UI
    static let loadingIndicatorScale: CGFloat = 1.5
    static let defaultPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 12
    
    // MARK: - Login Screen
    static let loginImageMaxHeight: CGFloat = 300
    static let loginKeyboardTopSpacing: CGFloat = 50
    static let loginBottomSpacing: CGFloat = 100
    static let loginContentPaddingKeyboard: CGFloat = 20
    static let loginContentPaddingNormal: CGFloat = 24
    static let loginFieldsTopPadding: CGFloat = 12
    static let loginButtonTopPadding: CGFloat = 18
    
    // MARK: - Network
    static let requestTimeout: TimeInterval = 30.0
    static let maxRetryAttempts: Int = 3
    
    // MARK: - PIN Configuration
    static let pinNumbers = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["!", "0", "delete.left.fill"]
    ]
    
    // MARK: - FOV Analysis
    static let fovThumbnailSize: CGFloat = 74
    static let fovGridSpacing: CGFloat = 10
    static let fovGridMinItemSize: CGFloat = 74
    static let fovBorderWidth: CGFloat = 4
    static let fovCornerRadius: CGFloat = 2
    static let fovSuccessIconSize: CGFloat = 20
    static let fovSuccessIconPadding: CGFloat = 4
    
    // MARK: - Default Values
    static let defaultUnknownValue = "Unknown"
    static let defaultNoGoalValue = "No goal specified"
    static let defaultNoTypeValue = "No type specified"

    // MARK: - Patient Module UI
    enum PatientUI {
        static let defaultEmptyValue: String = ""
        static let viewSpacing: CGFloat = 24
        static let searchSpacing: CGFloat = 20
        static let gridSpacing: CGFloat = 16
        static let gridItemSpacing: CGFloat = 12
        static let noResultsIconSize: CGFloat = 48
        static let horizontalPadding: CGFloat = 20
        static let topPadding: CGFloat = 40
        
        // Card constants
        static let cardIconSize: CGFloat = 32
        static let cardCornerRadius: CGFloat = 8
        static let cardBorderRadius: CGFloat = 12
        static let cardPadding: CGFloat = 12
        static let cardHeight: CGFloat = 100
        static let cardSpacing: CGFloat = 8
        static let cardContentSpacing: CGFloat = 4
        static let cardStrokeWidth: CGFloat = 1
        static let cardIconOpacity: Double = 0.2
        
        // Form constants
        static let fieldSpacing: CGFloat = 24
        static let nikLength: Int = 16
        static let bpjsLength: Int = 13
        static let bpjsMinLength: Int = 13
        static let bpjsMaxLength: Int = 13
        
        // Date formatting
        static let dateFormat: String = "dd/MM/yyyy"
        static let dateTimeFormat: String = "dd MMMM yyyy HH:mm"
    }
    
    // MARK: - Task Assignment Module UI
    enum TaskAssignmentUI {
        static let verticalSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 20
        static let elementSpacing: CGFloat = 12
        static let buttonSpacing: CGFloat = 16
        static let backButtonWidth: CGFloat = 3.5 // Screen width divisor
    }
}

// MARK: - Validation Constants
enum ValidationConstants {
    static let emailRegexPattern = "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$"
    static let minPasswordLength = 8
    static let maxPasswordLength = 128
}
