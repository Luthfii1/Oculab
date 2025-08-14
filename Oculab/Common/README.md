# Common Module Structure

This directory contains all shared components, utilities, and core functionality used throughout the Oculab application.

## 📁 Directory Structure

### Core/

Contains the fundamental building blocks of the application:

- **State/** - Application state management

  - `AppStateManager.swift` - Main app state controller
  - `LoadingStateManager.swift` - Loading state management

- **Navigation/** - App navigation and routing

  - `Router.swift` - Navigation router
  - `RouterView.swift` - Router view implementation

- **DependencyInjection/** - Dependency injection container

  - `DependencyInjection.swift` - Main DI container

- **Configuration/** - App-wide configuration and constants
  - `AppConstants.swift` - Application constants
  - `API.swift` - API endpoints and configuration
  - `Decimal.swift` - Decimal number configurations
  - `Stitch.swift` - Stitch configuration

### Architecture/

Contains architectural patterns and protocols:

- **Protocols/** - Interfaces and protocol definitions
  - `NetworkServiceProtocol.swift` - Network service interfaces
  - Other presenter protocols, etc.

### UI/

All user interface related components and resources:

- **Components/** - Reusable UI components

  - `AppButton.swift`, `ValidatedTextField.swift`, etc.
  - Form components, loading views, etc.

- **Themes/** - Design system components

  - **Fonts/** - Custom font definitions
  - Colors, typography, spacing definitions

- **Resources/** - UI assets and resources
  - **Animations/** - Lottie animation files

### Services/

External service integrations and managers:

- **Network/** - API and networking services

  - `AlamofireNetworkService.swift` - Main network implementation
  - `APIResponse.swift` - Response models
  - `NetworkErrorType.swift` - Error handling
  - `NetworkRetryManager.swift` - Retry logic
  - Other network utilities

- **Device/** - Device-specific functionality

  - `KeyboardManager.swift` - Keyboard handling
  - `ImageRegistration.swift` - Image registration
  - `ImageUtilities.swift` - Image processing utilities

- **Storage/** - Data persistence and security
  - `CryptoUtils.swift` - Cryptographic utilities

### Utilities/

Helper functions, extensions, and utility classes:

- **Extensions/** - Swift language extensions

  - String, Date, View extensions, etc.

- **Helpers/** - Utility functions and helper classes

  - `ErrorHandler.swift` - Error handling utilities
  - Other formatting and utility functions

- **Validators/** - Input validation system
  - `ValidationFieldName.swift` - Field name enums
  - `ValidationManager.swift` - Main validation logic
  - `ValidationHelpers.swift` - Validation utilities
  - `FormValidationViewModel.swift` - Form validation ViewModel

## 🎯 Benefits of This Structure

1. **Separation of Concerns** - Each directory has a clear responsibility
2. **Scalability** - Easy to add new components in the right place
3. **Maintainability** - Clear organization makes code easier to maintain
4. **Reusability** - Shared components are easily discoverable
5. **Team Collaboration** - Clear structure helps team members understand the codebase

## 📝 Naming Conventions

- **Directories**: PascalCase (e.g., `Core`, `Architecture`)
- **Files**: PascalCase for classes, camelCase for utilities
- **Groups**: Organize by feature/responsibility, not by file type

## 🔄 Migration Notes

- ✅ **Completed**: All files have been moved to the new organized structure
- ✅ **Network Layer**: Moved from `/Network` to `/Common/Services/Network`
- ✅ **Validation System**: Organized in `/Common/Utilities/Validators`
- ✅ **Device Services**: Moved to `/Common/Services/Device`
- ✅ **Dependency Injection**: Moved to `/Common/Core/DependencyInjection`
- ✅ **Protocols**: Organized in `/Common/Architecture/Protocols`
- ⚠️ **Action Required**: Update Xcode project structure to reflect this organization
- ⚠️ **Action Required**: Update import statements in files that reference moved components

## 📁 Current Structure

```
Common/
├── Core/
│   ├── State/              # App state management
│   ├── Navigation/         # Router and navigation
│   ├── DependencyInjection/ # DI container
│   └── Configuration/      # App config, constants
├── Architecture/
│   └── Protocols/          # Interfaces and protocols
├── UI/
│   ├── Components/         # Reusable UI components
│   ├── Themes/            # Colors, typography, spacing
│   └── Resources/         # Assets, animations
├── Services/
│   ├── Network/           # API, networking
│   ├── Storage/           # UserDefaults, security utils
│   └── Device/            # Keyboard, camera, image utils
└── Utilities/
    ├── Extensions/        # Swift extensions
    ├── Helpers/          # Utility functions
    └── Validators/       # Input validation
```
