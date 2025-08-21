import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case beginner = "Beginner Mode"
    case normal = "Normal Game"

    var id: String { self.rawValue }
}
