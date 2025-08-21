import SwiftUI

// Enum to define our theme choices and make them persistable
enum ColorSchemeChoice: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: Self { self }
}

struct SettingsView: View {
    // This property reads/writes the user's choice to UserDefaults
    @Binding var colorScheme: ColorSchemeChoice
    @Binding var gameMode: GameMode
    
    // Environment value to dismiss the sheet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Game Mode")) {
                    Picker("Mode", selection: $gameMode) {
                        ForEach(GameMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 5)
                }

                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $colorScheme) {
                        ForEach(ColorSchemeChoice.allCases) { scheme in
                            Text(scheme.rawValue).tag(scheme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 5)
                }
                
                Section(header: Text("Credits")) {
                    Text("Created by: Teo Miscia")
                    Text("Feedbacks: teo.miscia@gmail.com")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(colorScheme: .constant(.system), gameMode: .constant(.normal))
}
