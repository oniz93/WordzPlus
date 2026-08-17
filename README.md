# Wordz Plus 🎮

**Wordz Plus** is a modern, feature-rich word guessing game for iOS, built entirely with **SwiftUI**. It extends the classic "Wordle" formula with customizable difficulty levels, multiple word lengths, and a rewarding points system.

## ✨ Features

- **Multiple Word Lengths**: Challenge yourself with 4, 5, or 6-letter words.
- **Game Modes**:
  - **Normal Mode**: Standard challenge with 6 attempts.
  - **Beginner Mode**: Relaxed play with 8 attempts and cheaper hints.
- **Points System**: Earn points for victories and spend them on hints when you're stuck.
- **Smart Hints**: Reveal letters if you have enough points.
- **Auto-Save**: Never lose your progress; the game saves your state automatically.
- **Theming**: Full support for Light and Dark modes, plus system default syncing.
- **Analytics**: Integrated with Firebase for usage tracking.

## 🛠 Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Minimum Target**: iOS 17.2
- **External Services**: Firebase Analytics

## 📂 Project Structure

- **`App/`**: Entry point (`WordzPlusApp.swift`) and main setup.
- **`View/`**: SwiftUI views (`GameView`, `KeyboardView`, `SettingsView`).
- **`ViewModel/`**: Business logic and state management (`GameViewModel`).
- **`Model/`**: Data structures (`GameMode`, `Guess`, `WordList`).
- **`Resources/`**: Game data (`words.json`, `dictionary.json`) and fonts.

## 🚀 Getting Started

### Prerequisites
- Xcode 15 or later.
- iOS 17.2+ Simulator or Device.

### Installation

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    cd Wordz-Plus
    ```

2.  **Open the project**:
    Double-click `Wordz Plus.xcodeproj` to open it in Xcode.

3.  **Firebase Configuration**:
    The project relies on Firebase. Add your own `GoogleService-Info.plist` (download it from the Firebase console) to the `Wordz Plus/` root directory. This file is gitignored because it contains your API key.

4.  **Build and Run**:
    Select your target simulator or device and hit `Cmd + R`.

## 🎨 Customization

- **Fonts**: The app uses custom fonts `CutiveMono` and `JetBrainsMono`.
- **Word Lists**: Modify `words.json` to change the pool of target words or `dictionary.json` to update valid guesses.

## 📄 License

This project is for personal or educational use.
