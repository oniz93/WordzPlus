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
struct Guess: Identifiable, Equatable {
    let id = UUID()
    let word: String
    let feedback: [LetterStatus]

    var letters: [String] {
        word.map { String($0) }
    }
}

// Represents the current state of the game
enum GameStatus {
    case playing, won, lost
}
