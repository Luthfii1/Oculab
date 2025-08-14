//
//  ValidatedTextField.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/2025.
//

import SwiftUI

/// Enhanced TextField with integrated validation support
struct ValidatedTextField: View {
    var title: String
    var isRequired: Bool = false
    var placeholder: String = AppValue.empty
    var leftIcon: String? = nil
    var rightIcon: String? = nil
    var isDisabled: Bool = false
    var isNumberOnly: Bool = false
    var length: Int = 0
    @Binding var text: String
    
    // Validation properties - Enhanced with enum support
    private var fieldName: String
    var validationType: ValidationType = .none
    var customRules: [ValidationManager.ValidationRule] = []
    var validateOnChange: Bool = true
    @StateObject private var validationManager = ValidationManager.shared
    
    @State private var isPasswordVisible: Bool = false
    @FocusState private var isFocused: Bool

    // MARK: - Initializers
    
    /// Initialize with string-based field name (legacy support)
    init(
        title: String,
        isRequired: Bool = false,
        placeholder: String = AppValue.empty,
        leftIcon: String? = nil,
        rightIcon: String? = nil,
        isDisabled: Bool = false,
        isNumberOnly: Bool = false,
        length: Int = 0,
        text: Binding<String>,
        fieldName: String,
        validationType: ValidationType = .none,
        customRules: [ValidationManager.ValidationRule] = [],
        validateOnChange: Bool = true
    ) {
        self.title = title
        self.isRequired = isRequired
        self.placeholder = placeholder
        self.leftIcon = leftIcon
        self.rightIcon = rightIcon
        self.isDisabled = isDisabled
        self.isNumberOnly = isNumberOnly
        self.length = length
        self._text = text
        self.fieldName = fieldName
        self.validationType = validationType
        self.customRules = customRules
        self.validateOnChange = validateOnChange
    }
    
    /// Initialize with ValidationFieldName enum (new recommended approach)
    init(
        title: String,
        isRequired: Bool = false,
        placeholder: String = AppValue.empty,
        leftIcon: String? = nil,
        rightIcon: String? = nil,
        isDisabled: Bool = false,
        isNumberOnly: Bool = false,
        length: Int = 0,
        text: Binding<String>,
        fieldName: ValidationFieldName,
        validationType: ValidationType = .none,
        customRules: [ValidationManager.ValidationRule] = [],
        validateOnChange: Bool = true
    ) {
        self.title = title
        self.isRequired = isRequired
        self.placeholder = placeholder
        self.leftIcon = leftIcon
        self.rightIcon = rightIcon
        self.isDisabled = isDisabled
        self.isNumberOnly = isNumberOnly
        self.length = length
        self._text = text
        self.fieldName = fieldName.fieldName // Convert enum to string
        self.validationType = validationType
        self.customRules = customRules
        self.validateOnChange = validateOnChange
    }

    private var isPasswordInput: Bool {
        validationType == .password || rightIcon == AppIcon.eye
    }

    // Enhanced error state based on validation
    private var isError: Bool {
        validationManager.hasError(for: fieldName)
    }
    
    private var errorMessage: String? {
        validationManager.getError(for: fieldName)
    }

    // Colors based on the state (error, disabled, normal)
    private var borderColor: Color {
        if isError {
            return AppColors.red500
        } else if isDisabled {
            return AppColors.slate200
        } else if isFocused {
            return AppColors.purple700
        } else {
            return AppColors.slate300
        }
    }

    private var iconColor: Color {
        if isError {
            return AppColors.red500
        } else if isDisabled {
            return AppColors.slate100
        } else {
            return AppColors.purple700
        }
    }

    private var textColor: Color {
        isDisabled ? AppColors.slate400 : AppColors.slate900
    }

    private var backgroundColor: Color {
        isDisabled ? AppColors.slate50 : AppColors.slate0
    }

    var body: some View {
        VStack(alignment: .leading) {
            // Title and required indicator
            HStack {
                Text(title)
                    .font(AppTypography.s4_1)
                    .foregroundColor(textColor)
                Spacer().frame(width: 2)
                if isRequired {
                    Text(AppValue.required)
                        .foregroundColor(AppColors.red500)
                }
            }

            Spacer().frame(height: 8)

            // TextField with icons inside the box
            HStack {
                if let leftIcon = leftIcon {
                    Image(systemName: leftIcon)
                        .foregroundColor(iconColor)
                        .padding(.leading, 16)
                }

                // Conditionally show TextField or SecureField
                if isPasswordInput {
                    if isPasswordVisible {
                        TextField(placeholder, text: $text)
                            .keyboardType(getKeyboardType())
                            .disabled(isDisabled)
                            .foregroundColor(textColor)
                            .padding(.horizontal, 16)
                            .focused($isFocused)
                            .onChange(of: text) { _, newValue in
                                handleTextChange(newValue)
                            }
                    } else {
                        SecureField(placeholder, text: $text)
                            .disabled(isDisabled)
                            .foregroundColor(textColor)
                            .padding(.horizontal, 16)
                            .focused($isFocused)
                            .onChange(of: text) { _, newValue in
                                handleTextChange(newValue)
                            }
                    }
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(getKeyboardType())
                        .disabled(isDisabled)
                        .foregroundColor(textColor)
                        .padding(.horizontal, 16)
                        .focused($isFocused)
                        .onChange(of: text) { _, newValue in
                            handleTextChange(newValue)
                        }
                }

                if isPasswordInput {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? AppIcon.eyeSlash : AppIcon.eye)
                            .foregroundColor(iconColor)
                            .padding(.trailing, 12)
                    }
                } else if let rightIcon = rightIcon {
                    Image(systemName: rightIcon)
                        .foregroundColor(iconColor)
                        .padding(.trailing, 12)
                }
            }
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isError ? 2 : 1)
            )
            .background(backgroundColor)

            Spacer().frame(height: 8)

            // Error message or description
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: AppIcon.alert)
                        .foregroundColor(AppColors.red500)
                        .font(.caption)
                    Text(errorMessage)
                        .font(AppTypography.p3)
                        .foregroundColor(AppColors.red500)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .onAppear {
            // Initial validation if field has content
            if !text.isEmpty {
                performValidation()
            }
        }
    }

    private func getKeyboardType() -> UIKeyboardType {
        if isNumberOnly {
            return .numberPad
        }
        
        switch validationType {
        case .email:
            return .emailAddress
        case .phone:
            return .phonePad
        case .nik, .bpjs, .medicalRecord:
            return .numberPad
        default:
            return .default
        }
    }

    private func handleTextChange(_ newValue: String) {
        var updatedValue = newValue
        
        // Apply character filtering
        if isNumberOnly || validationType == .nik || validationType == .bpjs || validationType == .phone {
            updatedValue = newValue.filter { $0.isNumber }
        }
        
        // Apply length limits
        if length > 0 && updatedValue.count > length {
            updatedValue = String(updatedValue.prefix(length))
        }
        
        // Update text if needed
        if updatedValue != newValue {
            text = updatedValue
        }
        
        // Perform validation on change if enabled
        if validateOnChange && !updatedValue.isEmpty {
            performValidation()
        } else if updatedValue.isEmpty {
            validationManager.clearError(for: fieldName)
        }
    }

    private func performValidation() {
        switch validationType {
        case .email:
            validationManager.validateEmail(text, fieldName: fieldName)
        case .password:
            validationManager.validatePassword(text, fieldName: fieldName)
        case .name:
            validationManager.validateName(text, fieldName: fieldName)
        case .phone:
            validationManager.validatePhoneNumber(text, fieldName: fieldName)
        case .nik:
            validationManager.validateNIK(text, fieldName: fieldName)
        case .bpjs:
            if !text.isEmpty {
                validationManager.validateWithRules(text, fieldName: fieldName, rules: [
                    .numbersOnly(),
                    .minLength(13),
                    .maxLength(13)
                ])
            }
        case .medicalRecord:
            validationManager.validateMedicalRecordNumber(text, fieldName: fieldName)
        case .required:
            validationManager.validateRequired(text, fieldName: fieldName)
        case .custom:
            validationManager.validateWithRules(text, fieldName: fieldName, rules: customRules)
        case .none:
            break
        }
    }
    
    /// Manually trigger validation (useful for form submission)
    func validate() -> Bool {
        performValidation()
        return !validationManager.hasError(for: fieldName)
    }
}

// MARK: - Validation Types

enum ValidationType {
    case none
    case email
    case password
    case name
    case phone
    case nik
    case bpjs
    case medicalRecord
    case required
    case custom
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Using enum-based field names (recommended)
        ValidatedTextField(
            title: "Email",
            isRequired: true,
            placeholder: "Enter your email",
            leftIcon: "envelope.fill",
            text: .constant("test@domain.com"),
            fieldName: .loginEmail,
            validationType: .email
        )
        
        ValidatedTextField(
            title: "Password",
            isRequired: true,
            placeholder: "Enter password",
            leftIcon: "lock.fill",
            rightIcon: "eye",
            text: .constant("password123"),
            fieldName: .loginPassword,
            validationType: .password
        )
        
        ValidatedTextField(
            title: "NIK",
            isRequired: true,
            placeholder: "Enter NIK",
            leftIcon: "person.text.rectangle.fill",
            isNumberOnly: true,
            length: 16,
            text: .constant("1234567890123456"),
            fieldName: .patientNIK,
            validationType: .nik
        )
        
        ValidatedTextField(
            title: "Name",
            isRequired: true,
            placeholder: "Enter your name",
            leftIcon: "person.fill",
            text: .constant("John Doe"),
            fieldName: .patientName,
            validationType: .name
        )
        
        // Legacy string-based approach (still supported)
        ValidatedTextField(
            title: "Legacy Field",
            isRequired: true,
            placeholder: "Enter value",
            text: .constant("legacy_value"),
            fieldName: "legacy_field",
            validationType: .required
        )
    }
    .padding()
}
