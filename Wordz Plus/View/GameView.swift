import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var isShowingSettings = false
    @State private var isShowingHowToPlay = false
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @AppStorage("colorScheme") private var colorScheme: ColorSchemeChoice = .system

    private var selectedScheme: ColorScheme? {
        switch colorScheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }

    var body: some View {
        let hintCost = {
            viewModel.gameMode == .beginner ? "20" : "40"
        }
        VStack(spacing: 0) {
            let wordLengthBinding = Binding<Int>(
                get: { viewModel.wordLength },
                set: { viewModel.changeWordLength(to: $0) }
            )
            

            HeaderView(
                wordLength: wordLengthBinding,
                userPoints: viewModel.userPoints,
                onLengthChange: { _ in /* Handled by binding */ },
                onHint: viewModel.getHint,
                onSettings: { isShowingSettings = true },
                onHowToPlay: { isShowingHowToPlay = true },
                onReload: viewModel.promptForNewGame
            )

            Spacer()

            ScrollView {
                GameBoardView(
                    guesses: viewModel.guesses,
                    currentGuess: viewModel.currentGuess,
                    wordLength: viewModel.wordLength,
                    isInvalidWord: viewModel.isInvalidWord,
                    maxAttempts: viewModel.maxAttempts
                )
            }
            .padding(.horizontal)

            Spacer()

            KeyboardView(
                statuses: viewModel.keyboardStatuses,
                currentGuessLength: viewModel.currentGuess.count,
                wordLength: viewModel.wordLength,
                isInvalidWord: viewModel.isInvalidWord,
                onKeyPress: viewModel.keyPress,
                onDelete: viewModel.deletePress,
                onSubmit: viewModel.submitGuess
            )
            .padding(.horizontal, 4)
            .padding(.bottom, 8)

            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("brandBackground"))
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(
                colorScheme: $colorScheme,
                gameMode: $viewModel.gameMode,
                onGameModeChange: viewModel.changeGameMode
            )
            .preferredColorScheme(selectedScheme)
        }
        .sheet(isPresented: $isShowingHowToPlay) {
            HowToPlayView()
        }
        .onAppear {
            if isFirstLaunch {
                DispatchQueue.main.async {
                    isShowingHowToPlay = true
                    isFirstLaunch = false
                }
            }
        }
        // --- NEW: Alert modifier for the reload confirmation ---
        .alert("New Game", isPresented: $viewModel.xshowReloadConfirmAlert) {
            Button("OK", role: .destructive) {
                // If OK is tapped, start a new game and reveal the previous word
                viewModel.startNewGame(revealPreviousWord: true)
            }
            Button("Cancel", role: .cancel) {
                // The cancel role automatically handles dismissal
            }
        } message: {
            Text("Are you sure you want to start a new game? Your current progress will be lost.")
        }
        // --- NEW: Popup revealing the previous word after a reset ---
        .alert("Previous Word", isPresented: $viewModel.showPreviousWordAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The word you were trying to guess was '\(viewModel.previousTargetWord)'.")
        }
        .alert("Hint", isPresented: $viewModel.showHintAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.hintMessage)
        }
        .alert("You Win!", isPresented: $viewModel.showWinAlert) {
            Button("Play Again", role: .cancel) { viewModel.startNewGame() }
        } message: {
            Text("Congratulations! You guessed the word '\(viewModel.targetWord)' in \(viewModel.guesses.count) tries and won \(viewModel.lastGamePoints) points.")
        }
        .alert("You Lose!", isPresented: $viewModel.showLoseAlert) {
            Button("Play Again", role: .cancel) { viewModel.startNewGame() }
        } message: {
            Text("The correct word was '\(viewModel.targetWord)'. Better luck next time!")
        }
        .alert("Not Enough Points", isPresented: $viewModel.showNotEnoughPointsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You need at least \(hintCost()) points to use a hint.")
        }
        .alert("Use Hint?", isPresented: $viewModel.showHintConfirmationAlert) {
            Button("Yes", role: .destructive) {
                viewModel.confirmGetHint()
            }
            Button("No", role: .cancel) {}
        } message: {
            Text("Using a hint will cost \(hintCost()) points. Are you sure?")
        }
    }
}

// No changes needed below this line, but included for completeness

struct HeaderView: View {
    @Binding var wordLength: Int
    var userPoints: Int
    var onLengthChange: (Int) -> Void
    var onHint: () -> Void
    var onSettings: () -> Void
    var onHowToPlay: () -> Void
    var onReload: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                HStack(spacing: 20) {
                    Button(action: onSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(Color.gray)
                    }
                    Button(action: onHowToPlay) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundStyle(Color.gray)
                    }
                }
                
                Spacer()
                
                VStack {
                    Text("Wordz Plus")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("brandForeground"))
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.yellow)
                        Text("\(userPoints)")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: onHint) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                            .foregroundStyle(Color.gray)
                    }
                    Button(action: onReload) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .foregroundStyle(Color.gray)
                    }
                }
            }
            .padding(.horizontal)

            Picker("Word Length", selection: $wordLength) {
                Text("4").tag(4)
                Text("5").tag(5)
                Text("6").tag(6)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: wordLength) { newValue in
                onLengthChange(newValue)
            }
        }
        .padding(.vertical)
        .background(Color("brandBackground"))
    }
}

struct AdPlaceholderView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .ignoresSafeArea(.container, edges: .bottom)
            
            Text("Ad Placeholder")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .frame(height: 50)
    }
}


#Preview {
    GameView()
}