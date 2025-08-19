import SwiftUI

struct GameBoardView: View {
    let guesses: [Guess]
    let currentGuess: String
    let wordLength: Int
    let isInvalidWord: Bool
    
    private let maxAttempts = 6

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<maxAttempts, id: \.self) { index in
                // This structure is correct because each branch returns a single View.
                if index < guesses.count {
                    // Submitted row
                    LetterRowView(guess: guesses[index], wordLength: wordLength, isRevealing: true)
                } else if index == guesses.count {
                    // Current typing row
                    LetterRowView(word: currentGuess, wordLength: wordLength, isCurrent: true)
                        .modifier(ShakeEffect(shakes: isInvalidWord ? 2 : 0))
                        .animation(isInvalidWord ? .default : nil, value: isInvalidWord)
                } else {
                    // Empty future row
                    LetterRowView(word: "", wordLength: wordLength)
                }
            }
        }
        .frame(maxWidth: CGFloat(wordLength) * 70) // Adjust max width based on word length
    }
}

struct LetterRowView: View {
    var guess: Guess?
    var word: String = ""
    let wordLength: Int
    var isCurrent: Bool = false
    var isRevealing: Bool = false

    // This struct holds the pre-computed data for each letter box.
    // It's a clean way to separate data logic from view logic.
    private struct LetterDisplayData: Identifiable {
        let id: Int
        let letter: String?
        let status: LetterStatus
    }

    // This computed property prepares all data for the row BEFORE the view is built.
    // This is the key to fixing the 'buildExpression' error.
    private var rowData: [LetterDisplayData] {
        // 1. Determine the source letters (from a submitted guess or the current typing)
        let sourceLetters = guess?.letters ?? word.padding(toLength: wordLength, withPad: " ", startingAt: 0).map { String($0) }
        
        // 2. Map the letters and indices to the data needed by LetterBoxView
        return (0..<wordLength).map { index in
            let letter = sourceLetters[index].trimmingCharacters(in: .whitespaces)
            
            let status: LetterStatus
            if let guess = self.guess {
                // Status from a submitted guess
                status = guess.feedback[index]
            } else {
                // Status for current typing row or an empty future row
                status = self.isCurrent && !letter.isEmpty ? .tbd : .empty
            }
            
            return LetterDisplayData(
                id: index,
                letter: letter.isEmpty ? nil : letter,
                status: status
            )
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // The ForEach loop is now very simple. It just iterates over the
            // pre-computed `rowData` and creates a view for each item.
            ForEach(rowData) { data in
                LetterBoxView(
                    letter: data.letter,
                    status: data.status,
                    isRevealing: self.isRevealing && self.guess != nil, // Reveal only for submitted guesses
                    animationDelay: Double(data.id) * 0.2
                )
            }
        }
    }
}
