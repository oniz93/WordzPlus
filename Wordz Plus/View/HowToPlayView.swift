import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color("brandBackground").ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    Text("How To Play")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("brandForeground"))
                        .padding(.top, 20)

                    Text("Guess the secret word in 6 tries.\nSelect a word length of 4, 5, or 6 letters.")
                        .font(.body)
                        .foregroundColor(Color("brandForeground"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Divider().padding(.horizontal)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Examples")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("brandForeground"))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Example 1: Correct
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                LetterBoxView(letter: "W", status: .correct, isRevealing: true, animationDelay: 0.2)
                                LetterBoxView(letter: "E", status: .empty, isRevealing: false)
                                LetterBoxView(letter: "A", status: .empty, isRevealing: false)
                                LetterBoxView(letter: "R", status: .empty, isRevealing: false)
                                LetterBoxView(letter: "Y", status: .empty, isRevealing: false)
                            }
                            .frame(height: 50)
                            Text("**W** is in the word and in the correct spot.")
                                .foregroundColor(Color("brandForeground"))
                        }

                        // Example 2: Present
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                LetterBoxView(letter: "P", status: .empty, isRevealing: false)
                                LetterBoxView(letter: "I", status: .present, isRevealing: true, animationDelay: 0.2)
                                LetterBoxView(letter: "L", status: .empty, isRevealing: false)
                                LetterBoxView(letter: "O", status: .empty, isRevealing: false)
                                LetterBoxView(letter: "T", status: .empty, isRevealing: false)
                            }
                            .frame(height: 50)
                            Text("**I** is in the word but in the wrong spot.")
                                .foregroundColor(Color("brandForeground"))
                        }

                        // Example 3: Absent
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                LetterBoxView(letter: "V", status: .empty, isRevealing: false)
                                LetterBoxView(letter: "A", status: .empty, isRevealing: false)
                                LetterBoxView(letter: "G", status: .absent, isRevealing: true, animationDelay: 0.2)
                                LetterBoxView(letter: "U", status: .empty, isRevealing: false)
                                LetterBoxView(letter: "E", status: .empty, isRevealing: false)
                            }
                            .frame(height: 50)
                            Text("**G** is not in the word in any spot.")
                                .foregroundColor(Color("brandForeground"))
                        }
                    }
                    .padding(.horizontal)

                    Divider().padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hints")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("brandForeground"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 15) {
                            Image(systemName: "lightbulb.fill")
                                .font(.title)
                                .foregroundStyle(Color("brandAccent"))
                            Text("If you're stuck, tap the lightbulb icon to get a suggestion for a valid word.")
                                .foregroundColor(Color("brandForeground"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Let's Play!")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("brandPrimaryFg"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("brandPrimary"))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)

                }
            }
        }
    }
}

struct HowToPlayView_Previews: PreviewProvider {
    static var previews: some View {
        HowToPlayView()
    }
}
