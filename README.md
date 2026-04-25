# 🎓 Student Pal

**Student Pal** is a dedicated academic assistant designed to streamline the student experience. Built with Flutter, it combines schedule management, resource organization, and AI-driven support into a single, intuitive interface.

## ✨ Core Features

* **Smart Class Reminders:** A specialized notification system that alerts you 10 minutes and 1 minute before your scheduled classes.

* **AI Study Assistant:** A generative AI chat powered by Gemini to help clarify complex concepts and assist with brainstorming.

* **Automated Flashcards:** Instantly convert uploaded study materials and lecture notes into interactive flashcards for better retention.

* **Smart Questionnaires:** Generate custom mock exams and practice quizzes directly from your uploaded files to test your knowledge.

* **Resource Center:** A centralized hub to manage and pick academic files and study materials efficiently.

* **Interactive Dashboard:** Quick access to campus navigation via Google Maps and essential student categories.

## 🛠 Tech Stack

* **Frontend:** [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
* **Backend:** [Supabase](https://supabase.com/)
* **AI Integration:** `google_generative_ai` (Gemini API)
* **Notifications:** `flutter_local_notifications`

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (Stable)
* Supabase Account & API Keys
* Google AI (Gemini) API Key

### Installation
1.  **Clone the repo:**
    ```bash
    git clone https://github.com/sinharoro/StudentPal.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the application:**
    ```bash
    flutter run
    ```

## ⚙️ Environment Setup

Run the app with:
```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

Build with:
```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
```

## 📂 Project Structure
* `lib/screens/`: UI for Dashboard, AI Chat, and Resource Management.
* `lib/services/`: Logic for Notifications, Supabase integration, and AI API calls.
* `lib/widgets/`: Reusable UI components.
