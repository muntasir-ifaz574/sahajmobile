# SahajMobile Flutter App

A comprehensive Flutter application for mobile device financing and installment management, built with modern Flutter architecture and best practices.

## 🚀 Features

### Core Flow
- **Splash Screen**: Branded loading screen with SahajMobile logo
- **Onboarding**: 3-slider introduction to the app features
- **Authentication**: Login screen with temporary dummy credentials (no registration - agent-managed accounts)
- **Dashboard**: Agent portal with sales data, loan data, and navigation
- **Installment Plan**: Complete product selection and payment configuration
- **Verification**: ID card upload, photo capture, and information confirmation
- **Application Forms**: Address, job/income, guarantor, and machine information
- **Contract Flow**: Online contract signing, pre-enrollment, and activation
- **Approval**: Status screen with QR code for device setup

### Key Features
- 📱 **Product Selection**: Choose mobile brands and models with pricing
- 💰 **Installment Calculator**: Dynamic calculation of down payments and monthly installments
- 📄 **Advanced OCR Processing**: ID card text extraction using Google ML Kit Text Recognition 0.15.0
- 📸 **Document Verification**: Front/back ID card upload with real-time validation
- 📝 **Digital Contract**: Online signature capture with Signature Pad 6.3.0
- 📊 **Dashboard Analytics**: Sales and loan data visualization
- 🔐 **Secure Authentication**: Token-based authentication system
- 📱 **QR Code Integration**: Device activation QR codes

## 🏗️ Architecture

### Tech Stack
- **Framework**: Flutter 3.8.0+
- **State Management**: Riverpod 3.0.3 (Latest)
- **Routing**: GoRouter 16.3.0 (Latest)
- **HTTP Client**: Dio 5.4.0
- **Image Handling**: Image Picker 1.0.4, Cached Network Image 3.3.0
- **OCR & ML**: Google ML Kit Text Recognition 0.15.0 (Latest)
- **Storage**: Shared Preferences 2.2.2, Flutter Secure Storage 9.0.0
- **UI Components**: QR Flutter 4.1.0, Signature Pad 6.3.0 (Latest)
- **Utilities**: Permission Handler 12.0.1 (Latest), Intl 0.20.2 (Latest)

### Project Structure
```
lib/
├── core/
│   ├── constants/          # App constants and configuration
│   ├── theme/             # App theme and styling
│   ├── routing/           # GoRouter configuration
│   └── screens/           # Core screens (splash, onboarding)
├── features/
│   ├── auth/              # Authentication screens
│   ├── dashboard/         # Dashboard and analytics
│   ├── installment/      # Product selection and payment plans
│   ├── verification/     # ID verification flow
│   ├── application/      # Application forms
│   ├── contract/         # Contract and enrollment
│   └── approval/         # Approval and QR code
├── shared/
│   ├── models/           # Data models
│   ├── services/         # API services
│   ├── providers/        # Riverpod providers
│   └── widgets/          # Reusable widgets
└── main.dart             # App entry point
```

## 🛠️ Setup & Installation

### Prerequisites
- Flutter SDK 3.8.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Git

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sahajmobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run code generation** (for JSON serialization and Riverpod providers)
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Flow

### 1. Initial Flow
```
Splash Screen → Onboarding (3 slides) → Login Screen → Dashboard
```

### 2. Application Flow
```
Dashboard → Application Button → Product Selection → Installment Plan → Confirm Information
```

### 3. Verification Flow (OCR-Enhanced)
```
Confirm Information → Upload ID Card (OCR Processing) → Take ID Photo → Confirm ID Info (Auto-filled)
```
**OCR Features:**
- 📸 **Dual-side Upload**: Front and back ID card capture
- 🔍 **Real-time OCR**: Automatic text extraction during upload
- ✅ **Quality Validation**: Image quality checks before processing
- 📝 **Auto-fill Forms**: Extracted data automatically populates verification forms

### 4. Application Forms
```
Confirm ID Info → Address Info → Job/Income Info → Guarantor Info → Machine Info
```

### 5. Contract Flow
```
Machine Info → Online Contract → Pre-Enroll → Activation Progress → Approval Status
```

## 🔧 Configuration

### API Configuration
Update the API base URL in `lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'https://sm.sahajmobile.org/api/';
```

### 🔐 Temporary Login Credentials (Development)
For development and testing purposes, the following dummy credentials are available:

| Username | Password | Role | Description |
|----------|----------|------|-------------|
| `admin` | `admin123` | admin | Admin user with full access |
| `agent` | `agent123` | agent | Agent user for sales operations |
| `demo` | `demo123` | agent | Demo user for testing |

**Note**: These are temporary credentials for development. In production, these will be replaced with real API authentication.

### Theme Customization
Modify colors and styling in `lib/core/theme/app_theme.dart`:
```dart
static const Color primaryColor = Color(0xFF2196F3);
static const Color secondaryColor = Color(0xFF1976D2);
```

## 📊 State Management

The app uses **Riverpod 3.0.3** (latest version) for state management with the following providers:

- **AuthProvider**: Handles authentication state and user data using `Notifier<AuthState>`
- **ApplicationProvider**: Manages application form data
- **InstallmentProvider**: Handles installment calculations
- **RouterProvider**: Manages navigation state with GoRouter 16.3.0

### Key State Management Features:
- ✅ **Riverpod 3.0 Migration**: Updated from StateNotifier to Notifier pattern
- ✅ **Type-safe Providers**: Strongly typed state management
- ✅ **Dependency Injection**: Automatic provider resolution
- ✅ **Hot Reload Support**: Seamless development experience

## 🔍 OCR & Document Processing

### Google ML Kit Text Recognition 0.15.0
The app features advanced OCR capabilities for ID card processing:

#### OCR Features:
- 📄 **Text Extraction**: Automatic text recognition from ID card images
- 🔍 **Multi-language Support**: Supports Bengali, English, and other languages
- 📱 **Real-time Processing**: On-device text recognition for privacy
- 🎯 **High Accuracy**: Latest ML Kit algorithms for precise text extraction
- 📸 **Image Quality Detection**: Validates image quality before processing

#### Supported Document Types:
- 🆔 **National ID Cards**: Front and back side processing
- 📋 **Driver's License**: Text extraction and validation
- 📄 **Other Government Documents**: Extensible OCR support

#### OCR Workflow:
```
1. Image Capture/Upload → 2. Quality Validation → 3. Text Extraction → 4. Data Parsing → 5. Verification
```

#### Technical Implementation:
- **Service**: `NidOcrService` handles all OCR operations
- **Processing**: Asynchronous text recognition with error handling
- **Storage**: Temporary image storage for processing
- **Validation**: Image quality checks before OCR processing

## 🔐 Security Features

- **Token-based Authentication**: Secure API communication with Dio 5.4.0
- **Secure Storage**: Sensitive data encryption with Flutter Secure Storage 9.0.0
- **Input Validation**: Form validation and sanitization
- **Permission Handling**: Camera and storage permissions with Permission Handler 12.0.1
- **OCR Security**: Google ML Kit Text Recognition 0.15.0 for secure document processing
- **Privacy-First**: On-device OCR processing - no data sent to external servers

## 📱 Platform Support

- ✅ Android (API 21+)
- ✅ iOS (iOS 11+)
- ✅ Material Design 3
- ✅ Responsive Design

### Performance & Stability
- 🚀 **Better Performance**: Latest Riverpod 3.0 provides improved performance
- 🔧 **Type Safety**: Enhanced type safety with latest GoRouter
- 🛡️ **Security**: Updated ML Kit for better OCR processing
- 📱 **Compatibility**: Better platform compatibility with latest dependencies
- 🔍 **OCR Performance**: Faster text recognition with Google ML Kit 0.15.0
- 📸 **Image Processing**: Optimized image handling and validation

## 🧪 Testing

Run tests with:
```bash
flutter test
```

### Code Analysis
Run static analysis to check for issues:
```bash
flutter analyze
```

## 📦 Build & Deployment

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For support and questions:
- Email: muntasir574@gmail.com
- Documentation: [Link to documentation]

## 🔄 Version History

- **v1.0.1** (Latest): Major dependency updates and Riverpod 3.0 migration
  - ✅ Updated to Riverpod 3.0.3 (latest)
  - ✅ Updated to GoRouter 16.3.0 (latest)
  - ✅ Updated Google ML Kit Text Recognition to 0.15.0
  - ✅ Updated Permission Handler to 12.0.1
  - ✅ Updated Signature Pad to 6.3.0
  - ✅ Updated Intl to 0.20.2
  - ✅ Fixed all compilation errors
  - ✅ Improved state management with Notifier pattern

- **v1.0.0**: Initial release with complete app flow
  - Splash screen and onboarding
  - Authentication system
  - Dashboard with analytics
  - Complete installment flow
  - Document verification
  - Contract management
  - Approval system with QR codes

---

**Built with ❤️ using Flutter**