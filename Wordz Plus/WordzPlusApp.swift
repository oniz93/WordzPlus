import SwiftUI
import FirebaseCore

@main
struct WordzPlusApp: App {
    // Read the saved theme choice from UserDefaults
    @AppStorage("colorScheme") private var colorScheme: ColorSchemeChoice = .system

    init() {
        FirebaseApp.configure()
    }

    // Convert our enum to SwiftUI's ColorScheme type
    private var selectedScheme: ColorScheme? {
        switch colorScheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // 'nil' tells SwiftUI to follow the system setting
        }
    }

    var body: some Scene {
        WindowGroup {
            GameView()
                .preferredColorScheme(selectedScheme) // Apply the chosen theme
        }
    }
}
