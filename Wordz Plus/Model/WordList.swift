import Foundation

// A singleton to manage loading and accessing word lists from words.json
class WordList {
    static let shared = WordList()

    // The internal storage is now much simpler: a dictionary mapping an Int (word length)
    // to a Set of words. A Set is used for efficient lookup.
    private var wordsByLength: [Int: Set<String>] = [:]
    private var dictionaryByLength: [Int: Set<String>] = [:]

    private init() {
        loadWords()
        loadDictionary()
    }

    private func loadWords() {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json") else {
            fatalError("Could not find words.json in the app bundle.")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Could not load words.json from the app bundle.")
        }

        let decoder = JSONDecoder()
        guard let decodedData = try? decoder.decode([String: [String]].self, from: data) else {
            fatalError("Could not decode words.json. Make sure it matches the format {\"4\": [\"WORD1\", \"WORD2\"], ...}")
        }

        for (lengthStr, words) in decodedData {
            if let length = Int(lengthStr) {
                wordsByLength[length] = Set(words.map { $0.uppercased() })
            }
        }
    }

    private func loadDictionary() {
        guard let url = Bundle.main.url(forResource: "dictionary", withExtension: "json") else {
            fatalError("Could not find dictionary.json in the app bundle.")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Could not load dictionary.json from the app bundle.")
        }

        let decoder = JSONDecoder()
        guard let decodedData = try? decoder.decode([String: [String]].self, from: data) else {
            fatalError("Could not decode dictionary.json. Make sure it matches the format {\"4\": [\"WORD1\", \"WORD2\"], ...}")
        }

        for (lengthStr, words) in decodedData {
            if let length = Int(lengthStr) {
                dictionaryByLength[length] = Set(words.map { $0.uppercased() })
            }
        }
    }

    // This function now reads from the simplified data structure.
    func getRandomWord(for length: Int) -> String {
        guard let words = dictionaryByLength[length], !words.isEmpty else {
            // Fallback word in case of an error
            return "ERROR".padding(toLength: length, withPad: "X", startingAt: 0)
        }
        return words.randomElement()!
    }

    // This function is also simplified.
    func isValid(word: String) -> Bool {
        let uppercasedWord = word.uppercased()
        let wordLength = uppercasedWord.count

        let inWords = wordsByLength[wordLength]?.contains(uppercasedWord) ?? false
        let inDictionary = dictionaryByLength[wordLength]?.contains(uppercasedWord) ?? false

        return inWords || inDictionary
    }
    
    // This function is also simplified.
    func getValidWords(for length: Int) -> Set<String> {
        return wordsByLength[length] ?? []
    }

    // The 'WordsForLength' helper struct is no longer needed and has been removed.
}
