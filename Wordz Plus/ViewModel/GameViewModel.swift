import Foundation
import SwiftUI
import FirebaseAnalytics

// MARK: - Game State Persistence
struct GameState: Codable {
    var targetWord: String
    var guesses: [Guess]
    var keyboardStatuses: [String: LetterStatus] // Changed to String key
    var gameStatus: GameStatus
    var wordLength: Int
    var currentGuess: String
}

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Game Settings
    var maxAttempts: Int {
        gameMode == .beginner ? 8 : 6
    }
    var hintPoints: Int {
        gameMode == .beginner ? 20 : 40
    }
    @Published var wordLength = 5

    // MARK: - Published Game State
    @Published var targetWord = ""
    @Published var guesses: [Guess] = []
    @Published var currentGuess = ""
    @Published var keyboardStatuses: [Character: LetterStatus] = [:]
    @Published var gameStatus: GameStatus = .playing
    @Published var isInvalidWord = false
    @AppStorage("userPoints") var userPoints: Int = 0
    @AppStorage("gameMode") private var gameMode: GameMode = .normal

    // MARK: - Alerts
    @Published var showWinAlert = false
    @Published var showLoseAlert = false
    @Published var showHintAlert = false
    @Published var hintMessage = ""
    @Published var showLengthChangeConfirmAlert = false
    private var pendingWordLength: Int?
    @Published var showNotEnoughPointsAlert = false
    @Published var showHintConfirmationAlert = false
    @Published var lastGamePoints = 0
    
    // --- NEW: Property for the reload confirmation alert ---
    @Published var xshowReloadConfirmAlert = false

    private let gameStateKey = "gameState"
    private let recentWordsKey = "recentWords"
    private var recentWords: [String: [String]] = [:]

    init() {
        loadRecentWords()
        if !loadState() {
            startNewGame()
        }
    }

    // MARK: - Game State Persistence
    private func saveState() {
        let savableKeyboardStatuses = Dictionary(uniqueKeysWithValues: keyboardStatuses.map { key, value in (String(key), value) })
        
        let gameState = GameState(
            targetWord: targetWord,
            guesses: guesses,
            keyboardStatuses: savableKeyboardStatuses,
            gameStatus: gameStatus,
            wordLength: wordLength,
            currentGuess: currentGuess
        )
        if let encoded = try? JSONEncoder().encode(gameState) {
            UserDefaults.standard.set(encoded, forKey: gameStateKey)
        }
    }

    private func loadState() -> Bool {
        guard let savedData = UserDefaults.standard.data(forKey: gameStateKey),
              let gameState = try? JSONDecoder().decode(GameState.self, from: savedData) else {
            return false
        }

        self.targetWord = gameState.targetWord
        self.guesses = gameState.guesses
        self.gameStatus = gameState.gameStatus
        self.wordLength = gameState.wordLength
        self.currentGuess = gameState.currentGuess
        
        // Convert keyboard status keys back to Character
        self.keyboardStatuses = Dictionary(uniqueKeysWithValues: gameState.keyboardStatuses.map { key, value in (Character(key), value) })

        return true
    }

    private func clearState() {
        UserDefaults.standard.removeObject(forKey: gameStateKey)
    }

    private func saveRecentWords() {
        UserDefaults.standard.set(recentWords, forKey: recentWordsKey)
    }

    private func loadRecentWords() {
        if let loadedWords = UserDefaults.standard.dictionary(forKey: recentWordsKey) as? [String: [String]] {
            recentWords = loadedWords
        }
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

        var newWord = ""
        repeat {
            newWord = WordList.shared.getRandomWord(for: wordLength).uppercased()
        } while (recentWords[String(wordLength)] ?? []).contains(newWord)

        self.targetWord = newWord
        
        let key = String(wordLength)
        if recentWords[key] == nil {
            recentWords[key] = []
        }
        recentWords[key]?.append(newWord)
        if (recentWords[key]?.count ?? 0) > 10 {
            recentWords[key]?.removeFirst()
        }
        saveRecentWords()

        self.guesses = []
        self.currentGuess = ""
        self.gameStatus = .playing
        self.showWinAlert = false
        self.showLoseAlert = false
        self.isInvalidWord = false
        self.showHintAlert = false
        self.hintMessage = ""
        resetKeyboard()
        clearState()
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
        saveState()
    }

    func deletePress() {
        guard !currentGuess.isEmpty else { return }
        currentGuess.removeLast()
        if isInvalidWord {
           isInvalidWord = false
        }
        saveState()
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
            let basePoints = gameMode == .beginner ? 90 : 70
            let pointsWon = basePoints - (guesses.count - 1) * 10
            userPoints += pointsWon
            lastGamePoints = pointsWon
            Analytics.logEvent("game_won", parameters: [
                "word_length": wordLength,
                "guesses": guesses.count,
                "points_won": pointsWon
            ])
            clearState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.showWinAlert = true }
        } else if guesses.count == maxAttempts {
            gameStatus = .lost
            Analytics.logEvent("game_lost", parameters: ["word_length": wordLength])
            clearState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.showLoseAlert = true }
        }
        
        currentGuess = ""
        saveState()
    }

    private func triggerInvalidWord() {
        isInvalidWord = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.isInvalidWord = false }
    }
    
    func getHint() {
        let allValidWords = WordList.shared.getValidWords(for: wordLength)
        let guessedWords = Set(guesses.map { $0.word })

        let possibleSolutions = allValidWords.filter { potentialWord in
            return guesses.allSatisfy { guess in
                let hypotheticalFeedback = getFeedback(for: guess.word, with: potentialWord)
                return hypotheticalFeedback == guess.feedback
            }
        }

        if possibleSolutions.count == 1 && possibleSolutions.first == targetWord {
            self.hintMessage = "I don't want to spoil the solution 😁"
            self.showHintAlert = true
        } else if userPoints >= hintPoints {
            showHintConfirmationAlert = true
        } else {
            showNotEnoughPointsAlert = true
        }
    }

    func confirmGetHint() {
        userPoints -= hintPoints
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
