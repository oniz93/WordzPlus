import Foundation

// Represents the evaluation status of a single letter
enum LetterStatus: String, Codable, Equatable {
    case correct   // Green: Correct letter, correct position
    case present   // Yellow: Correct letter, wrong position
    case absent    // Gray: Letter not in the word
    case tbd       // To-be-determined: For the current typing row
    case empty     // Not yet filled
}

// Represents a single submitted guess
struct Guess: Identifiable, Codable, Equatable {
    let id: String
    let word: String
    let feedback: [LetterStatus]

    init(word: String, feedback: [LetterStatus]) {
        self.id = UUID().uuidString
        self.word = word
        self.feedback = feedback
    }

    var letters: [String] {
        word.map { String($0) }
    }
}

// Represents the current state of the game
enum GameStatus: String, Codable {
    case playing, won, lost
}
