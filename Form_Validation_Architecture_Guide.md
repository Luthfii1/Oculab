# Form Validation Architecture Best Practices

## Overview

This document outlines the recommended approach for implementing form validation in the Oculab app, comparing view-level vs presenter-level validation strategies.

## ✅ **Recommended Approach: Presenter-Level Validation**

### Benefits:

1. **Single Responsibility**: Business logic stays in the presenter
2. **Testability**: Easy to unit test validation without UI dependencies
3. **Consistency**: All form logic in one place
4. **Reusability**: Multiple views can use the same presenter
5. **Maintainability**: Changes to validation rules only require presenter updates

### Implementation Pattern:

```swift
// In Presenter
class AuthenticationPresenter: ObservableObject {
    @Published var formValidation = FormValidationViewModel()
    @Published var email = ""
    @Published var password = ""
    @Published var emailError = ""
    @Published var passwordError = ""

    // Computed property for form validity
    var isFilled: Bool {
        return isFormValid() && !isLoading
    }

    // Validation methods
    private func validateEmailField() {
        if !email.isEmpty {
            let isValid = ValidationManager.shared.validateEmail(email, fieldName: "login_email")
            emailError = isValid ? "" : (ValidationManager.shared.getError(for: "login_email") ?? "")
        } else {
            emailError = ""
            ValidationManager.shared.clearError(for: "login_email")
        }
    }

    // Enhanced action method with validation
    @MainActor
    func loginWithValidation() async -> Bool {
        guard isFormValid() else { return false }
        formValidation.clearAllErrors()
        return await performLogin()
    }

    private func isFormValid() -> Bool {
        return formValidation.validateLoginForm(email: email, password: password)
    }
}
```

```swift
// In View - Clean and Simple
struct LoginView: View {
    @EnvironmentObject var presenter: AuthenticationPresenter

    var body: some View {
        VStack {
            AppTextField(
                title: "Email",
                text: $presenter.email,
                description: presenter.emailError,
                isError: !presenter.emailError.isEmpty
            )

            AppButton(
                title: "Login",
                isEnabled: presenter.isFilled
            ) {
                Task {
                    await presenter.loginWithValidation()
                }
            }
        }
    }
}
```

## ❌ **Alternative Approach: View-Level Validation**

### When It Might Be Used:

- Simple, one-off forms
- Rapid prototyping
- Forms with very specific UI-only validation

### Drawbacks:

1. **Mixed Responsibilities**: View handles both UI and business logic
2. **Testing Complexity**: Harder to test validation without UI
3. **Code Duplication**: Similar forms duplicate validation logic
4. **Maintenance Issues**: Validation changes require view updates

## 🏗️ **Architecture Patterns by Form Type**

### 1. **Medical Forms (Patient, Medical Records)**

**Recommended**: Presenter-level with specialized medical validation

```swift
class PatientPresenter: ObservableObject {
    @Published var formValidation = FormValidationViewModel()

    func validatePatientForm() -> Bool {
        return formValidation.validatePatientForm(
            name: patient.name,
            nik: patient.NIK,
            bpjs: patient.BPJS
        )
    }

    @MainActor
    func savePatientWithValidation() async {
        guard validatePatientForm() else { return }
        await savePatient()
    }
}
```

### 2. **User Management Forms**

**Recommended**: Presenter-level with role-based validation

```swift
class AccountPresenter: ObservableObject {
    @Published var formValidation = FormValidationViewModel()

    func validateUserForm() -> Bool {
        return formValidation.validateUserForm(
            name: name,
            email: email,
            role: role
        )
    }
}
```

### 3. **Authentication Forms**

**Recommended**: Presenter-level with security validation

```swift
class AuthenticationPresenter: ObservableObject {
    // Validation integrated into existing business logic
    // Real-time feedback through @Published properties
    // Centralized error handling
}
```

## 📋 **Implementation Checklist**

### For Each Form Presenter:

- [ ] Add `FormValidationViewModel` as `@Published` property
- [ ] Implement form-specific validation methods
- [ ] Add real-time field validation in property observers
- [ ] Create enhanced action methods with validation
- [ ] Expose validation state through computed properties

### For Each Form View:

- [ ] Remove local validation logic
- [ ] Use presenter's validation state for UI feedback
- [ ] Call presenter's enhanced action methods
- [ ] Keep views focused on UI presentation only

### For Testing:

- [ ] Unit test presenter validation methods
- [ ] Test validation state changes
- [ ] Mock form submission with invalid data
- [ ] Verify error message accuracy

## 🎯 **Current Implementation Status**

### ✅ **Completed - Presenter-Level Validation**

- `AuthenticationPresenter` - Updated with integrated validation
- `LoginView` - Simplified to use presenter validation

### 📋 **Recommended Updates**

- `PatientPresenter` - Move validation from `PatientFormField`
- `AccountPresenter` - Move validation from form views
- `ProfilePresenter` - Move validation from `EditPasswordView`

### 🔧 **Migration Strategy**

1. **Phase 1**: Update existing presenters with validation logic
2. **Phase 2**: Simplify views to remove validation code
3. **Phase 3**: Add comprehensive unit tests
4. **Phase 4**: Document validation rules and error messages

## 🏆 **Benefits Achieved**

### Developer Experience:

- **Consistent Architecture**: All business logic in presenters
- **Better Testing**: Validation logic easily unit testable
- **Code Reusability**: Presenters can be reused across views
- **Separation of Concerns**: Views focus on UI, presenters handle logic

### User Experience:

- **Real-time Feedback**: Immediate validation as user types
- **Consistent Error Messages**: Centralized validation rules
- **Better Performance**: Validation optimized in presenters
- **Accessibility**: Better error announcements for screen readers

### Medical App Benefits:

- **Data Quality**: Robust validation prevents invalid medical data
- **Regulatory Compliance**: Proper validation for medical records
- **User Safety**: Prevents critical data entry errors
- **Audit Trail**: Centralized validation logging capability

## 📖 **Conclusion**

**Presenter-level validation is the recommended approach** for the Oculab medical application because:

1. **Scalability**: Easier to maintain as the app grows
2. **Medical Safety**: Critical for healthcare applications
3. **Team Collaboration**: Clear separation of UI and business logic
4. **Code Quality**: Better architecture leads to fewer bugs
5. **Testing Coverage**: Comprehensive validation testing possible

The refactored `AuthenticationPresenter` and `LoginView` demonstrate this pattern effectively, providing a template for updating other forms in the application.
