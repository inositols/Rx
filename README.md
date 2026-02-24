# Rx (Pharmacy CBT Platform)

Rx is a professional Computer-Based Testing (CBT) platform specifically designed for pharmacy students. It provides a comprehensive suite of tools for students to prepare for professional exams through practice tests, and for administrators to manage a robust bank of pharmacological and pharmacognostical questions.

![Rx App](images/splash.png)

## 🚀 Features

### **For Students**
- **Auth System**: Secure login for students to track their progress.
- **Customizable Tests**: Take quizzes based on different pharmacy subjects (e.g., Pharmacology, Pharmacognosy).
- **Exam Mode**: Real-time test-taking interface with active timers.
- **Result Analysis**: Immediate performance feedback with detailed results and history tracking.
- **Responsive Design**: Optimized for different screen sizes and devices.

### **For Administrators**
- **Admin Dashboard**: Specialized tools for platform management.
- **Question Management**: Bulk import questions from CSV files.
- **Data Maintenance**: Tools for database migration and setup.
- **Platform Monitoring**: Oversight of quiz content and system status.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Material 3 Design)
- **State Management**: [BLoC](https://pub.dev/packages/flutter_bloc) (Business Logic Component)
- **Backend/Database**: [Firebase](https://firebase.google.com/) (Auth & Firestore)
- **Utilities**: 
  - `csv`: For question bank parsing.
  - `intl`: For localized formatting.
  - `file_picker`: For admin-side document uploads.

## 📁 Project Structure

The project follows a **Feature-Based Clean Architecture**, organizing code by functional modules rather than file types:

```text
lib/
├── auth/           # Authentication logic, views, and BLoC
├── quiz/           # Quiz logic, upload interface, and widgets
├── question/       # Question management and CRUD operations
├── test/           # Test-taking flow and results history
├── dashboard/      # Admin and Student dashboard views
├── core/           # Shared models (CBTModels), data, and utils
├── shared/         # Common UI components (Splash, AuthSelector)
└── main.dart       # App entry point and BLoC providers
```

## 🏁 Getting Started

### Prerequisites
- Flutter SDK (^3.5.3)
- Android Studio / VS Code with Flutter extension
- A Firebase project with Firestore and Auth enabled

### Installation
1.  **Clone the repository**:
    ```bash
    git clone [repository-url]
    cd rx
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Firebase Setup**:
    - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from your Firebase console.
    - Place them in `android/app/` and `ios/Runner/` respectively.
    - Alternatively, use `flutterfire configure` to update `lib/firebase_options.dart`.

### Running the App
```bash
flutter run
```

## 📝 Usage
- **Student Access**: Use the Student Login to access quizzes and history.
- **Admin Access**: Use the Admin credentials to access the bulk upload and question management tools.

---
*Developed by the Rx Team*
