import Foundation
import SwiftUI
import FirebaseAnalytics

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Game Settings
    let maxAttempts = 6
    @Published var wordLength = 5

    // MARK: - Published Game State
    @Published var targetWord = ""
    @Published var guesses: [Guess] = []
    @Published var currentGuess = ""
    @Published var keyboardStatuses: [Character: LetterStatus] = [:]
    @Published var gameStatus: GameStatus = .playing
    @Published var isInvalidWord = false

    // MARK: - Alerts
    @Published var showWinAlert = false
    @Published var showLoseAlert = false
    @Published var showHintAlert = false
    @Published var hintMessage = ""
    @Published var showLengthChangeConfirmAlert = false
    private var pendingWordLength: Int?
    
    // --- NEW: Property for the reload confirmation alert ---
    @Published var xshowReloadConfirmAlert = false

    init() {
        startNewGame()
    }

    // MARK: - Game Flow
    func startNewGame() {
        // Log abandoned game if a game was in progress
        if gameStatus == .playing && !guesses.isEmpty {
            Analytics.logEvent("game_abandoned", parameters: [
                "word_length": wordLength,
                "guesses_made": guesses.count
            ])
        }

        self.targetWord = WordList.shared.getRandomWord(for: wordLength).uppercased()
        self.guesses = []
        self.currentGuess = ""
        self.gameStatus = .playing
        self.showWinAlert = false
        self.showLoseAlert = false
        self.isInvalidWord = false
        self.showHintAlert = false
        self.hintMessage = ""
        resetKeyboard()
        print("New game started. Target word: \(targetWord)")
        
        // Log new game event
        Analytics.logEvent("game_started", parameters: ["word_length": wordLength])
    }
    
    // --- NEW: Function to trigger the confirmation prompt ---
    // Instead of restarting directly, the reload button will call this function.
    func promptForNewGame() {
        // Don't show the prompt if the game is already over.
        guard gameStatus == .playing else { 
            startNewGame()
            return 
        }
        self.xshowReloadConfirmAlert = true
    }

    func changeWordLength(to newLength: Int) {
        guard [4, 5, 6].contains(newLength) else { return }
        if wordLength == newLength { return }

        if !guesses.isEmpty {
            pendingWordLength = newLength
            showLengthChangeConfirmAlert = true
        } else {
            wordLength = newLength
            startNewGame()
        }
    }

    func confirmChangeWordLength() {
        if let newLength = pendingWordLength {
            // Log abandoned game if a game was in progress
            if gameStatus == .playing && !guesses.isEmpty {
                Analytics.logEvent("game_abandoned", parameters: [
                    "word_length": wordLength,
                    "guesses_made": guesses.count
                ])
            }
            
            wordLength = newLength
            startNewGame()
            pendingWordLength = nil
        }
    }

    // MARK: - User Input Handling
    func keyPress(_ letter: Character) {
        guard gameStatus == .playing && currentGuess.count < wordLength else { return }
        currentGuess.append(letter)
    }

    func deletePress() {
        guard !currentGuess.isEmpty else { return }
        currentGuess.removeLast()
        if isInvalidWord {
           isInvalidWord = false
        }
    }

    func submitGuess() {
        guard gameStatus == .playing else { return }
        guard currentGuess.count == wordLength else { return }
        guard WordList.shared.isValid(word: currentGuess) else {
            triggerInvalidWord()
            return
        }

        let feedback = getFeedback(for: currentGuess, with: targetWord)
        let newGuess = Guess(word: currentGuess, feedback: feedback)
        guesses.append(newGuess)
        updateKeyboard(with: newGuess)

        if currentGuess == targetWord {
            gameStatus = .won
            Analytics.logEvent("game_won", parameters: [
                "word_length": wordLength,
                "guesses": guesses.count
            ])
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.showWinAlert = true }
        } else if guesses.count == maxAttempts {
            gameStatus = .lost
            Analytics.logEvent("game_lost", parameters: ["word_length": wordLength])
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.showLoseAlert = true }
        }
        
        currentGuess = ""
    }

    private func triggerInvalidWord() {
        isInvalidWord = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.isInvalidWord = false }
    }
    
    func getHint() {
        Analytics.logEvent("hint_used", parameters: ["word_length": wordLength])
        let allValidWords = WordList.shared.getValidWords(for: wordLength)
        let guessedWords = Set(guesses.map { $0.word })

        let possibleSolutions = allValidWords.filter { potentialWord in
            return guesses.allSatisfy { guess in
                let hypotheticalFeedback = getFeedback(for: guess.word, with: potentialWord)
                return hypotheticalFeedback == guess.feedback
            }
        }

        let hintOptions = possibleSolutions.filter { $0 != targetWord && !guessedWords.contains($0) }

        if let hint = hintOptions.randomElement() {
            self.hintMessage = "You could try the word: \(hint)"
        } else if possibleSolutions.count == 1 && possibleSolutions.first == targetWord {
            self.hintMessage = "I don't want to spoil the solution 😁"
        } else {
            self.hintMessage = "No valid hints could be found based on your guesses."
        }
        self.showHintAlert = true
    }

    // MARK: - Internal Logic
    private func getFeedback(for guess: String, with target: String) -> [LetterStatus] {
        let guessChars = Array(guess.uppercased())
        let targetChars = Array(target.uppercased())
        var feedback = [LetterStatus](repeating: .absent, count: wordLength)
        var targetLetterCounts = targetChars.reduce(into: [:]) { $0[$1, default: 0] += 1 }

        for i in 0..<wordLength {
            if guessChars[i] == targetChars[i] {
                feedback[i] = .correct
                targetLetterCounts[guessChars[i], default: 1] -= 1
            }
        }

        for i in 0..<wordLength {
            if feedback[i] == .correct { continue }
            let char = guessChars[i]
            if targetChars.contains(char) && targetLetterCounts[char, default: 0] > 0 {
                feedback[i] = .present
                targetLetterCounts[char, default: 1] -= 1
            }
        }
        return feedback
    }
    
    private func resetKeyboard() {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        keyboardStatuses = [:]
        alphabet.forEach { keyboardStatuses[$0] = .tbd }
    }

    private func updateKeyboard(with guess: Guess) {
        for (index, char) in guess.word.enumerated() {
            let status = guess.feedback[index]
            let currentStatus = keyboardStatuses[char] ?? .tbd
            switch currentStatus {
            case .correct: continue
            case .present: if status == .correct { keyboardStatuses[char] = .correct }
            default: keyboardStatuses[char] = status
            }
        }
    }
}
