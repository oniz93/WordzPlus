import SwiftUI

// --- NEW: Enum to represent all possible keys for a cleaner layout ---
enum KeyboardKey: Hashable {
    case letter(Character)
    case enter
    case delete
}

struct KeyboardView: View {
    let statuses: [Character: LetterStatus]
    
    // --- NEW: Properties to control the dynamic ENTER button ---
    let currentGuessLength: Int
    let wordLength: Int
    let isInvalidWord: Bool
    
    let onKeyPress: (Character) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void
    
    // --- UPDATED: The layout now matches your image ---
    private let keyRows: [[KeyboardKey]] = [
        [.letter("Q"), .letter("W"), .letter("E"), .letter("R"), .letter("T"), .letter("Y"), .letter("U"), .letter("I"), .letter("O"), .letter("P")],
        [.letter("A"), .letter("S"), .letter("D"), .letter("F"), .letter("G"), .letter("H"), .letter("J"), .letter("K"), .letter("L")],
        [.enter, .letter("Z"), .letter("X"), .letter("C"), .letter("V"), .letter("B"), .letter("N"), .letter("M"), .delete]
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(keyRows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        KeyButton(
                            key: key,
                            status: (key.isLetter ? statuses[key.characterValue!] : nil) ?? .tbd,
                            currentGuessLength: currentGuessLength,
                            wordLength: wordLength,
                            isInvalidWord: isInvalidWord,
                            onKeyPress: onKeyPress,
                            onDelete: onDelete,
                            onSubmit: onSubmit
                        )
                    }
                }
            }
        }
    }
}


// --- COMPLETELY REWRITTEN KeyButton to handle all cases ---
struct KeyButton: View {
    let key: KeyboardKey
    let status: LetterStatus
    
    // State for the ENTER button
    let currentGuessLength: Int
    let wordLength: Int
    let isInvalidWord: Bool
    
    // Actions
    let onKeyPress: (Character) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        Button(action: handleTap) {
            Group {
                switch key {
                case .letter(let char):
                    Text(String(char))
                case .enter:
                    // Conditional view for the ENTER button
                    if showInvalidWordState {
                        Text("Not a word")
                    } else {
                        HStack(spacing: 4) {
                            Text("ENTER")
                        }
                    }
                case .delete:
                    Image(systemName: "delete.left")
                }
            }
            .font(.system(size: key.isSpecial ? 14 : 18, weight: .semibold))
            .frame(maxWidth: .infinity) // Makes keys resize to fill space
            .frame(height: 50)
            .if(key.isSpecial) { view in // Use .if for conditional width
                view.frame(minWidth: 60)
            }
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(.plain) // Removes default button styling
        .disabled(key == .enter && isEnterDisabled)
    }

    // MARK: - Logic and Computed Properties
    
    private func handleTap() {
        switch key {
        case .letter(let char):
            onKeyPress(char)
        case .enter:
            onSubmit()
        case .delete:
            onDelete()
        }
    }
    
    private var showInvalidWordState: Bool {
        return key == .enter && currentGuessLength == wordLength && isInvalidWord
    }
    
    private var isEnterDisabled: Bool {
        return currentGuessLength < wordLength
    }
    
    private var backgroundColor: Color {
        if showInvalidWordState {
            return Color("brandDestructive") // Red for "Not a word"
        }
        
        // Use colors based on letter status (correct, present, absent)
        switch status {
        case .correct: return Color("brandPrimary")
        case .present: return Color("brandAccent")
        case .absent: return Color("brandMuted")
        default:
            // Default gray for unused keys and special buttons
            return Color(white: 0.3, opacity: isEnterDisabled && key == .enter ? 0.5 : 1.0)
        }
    }

    private var foregroundColor: Color {
        // All states should have white text for contrast on the dark/colored backgrounds
        return .white
    }
}

// MARK: - Helper Extensions

// Helper to avoid cluttering the view code
extension KeyboardKey {
    var isLetter: Bool {
        if case .letter = self { return true }
        return false
    }

    var isSpecial: Bool {
        return !isLetter
    }
    
    var characterValue: Character? {
        if case .letter(let char) = self { return char }
        return nil
    }
}

// A simple ViewModifier for conditional logic
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
