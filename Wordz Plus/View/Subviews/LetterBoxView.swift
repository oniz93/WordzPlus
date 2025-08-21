import SwiftUI

struct LetterBoxView: View {
    let letter: String?
    let status: LetterStatus
    var isRevealing: Bool = false
    var animationDelay: Double = 0.0

    @State private var hasAnimated = false

    private var opacity: Double {
        if isRevealing {
            return hasAnimated ? 1 : 0
        } else {
            return 1
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(backgroundColor)
                .strokeBorder(borderColor, lineWidth: 3)
                // --- FIX ---
                // Add a subtle pop-in animation for the current guess letters
                .scaleEffect(status == .tbd && letter != nil ? 1.1 : 1.0)

            if let letter = letter {
                Text(letter)
                    .font(.custom("JetBrainsMono-SemiBold", size: 38))
                    .foregroundColor(foregroundColor)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.vertical, -3)
        .opacity(opacity)
        // The onAppear logic is now safe because the view is visible from the start
        // if it's not a 'revealing' box.
        .onAppear {
            guard isRevealing else { return }
            withAnimation(.easeIn(duration: 0.2).delay(animationDelay)) {
                hasAnimated = true
            }
        }
        // Animate the pop-in effect for a better feel
        .animation(.easeIn(duration: 0.2).delay(animationDelay), value: opacity)
    }

    private var backgroundColor: Color {
        switch status {
        case .correct: return Color("brandPrimary")
        case .present: return Color("brandAccent")
        case .absent: return Color("brandMuted")
        // Use the card/background color for TBD and Empty states
        case .tbd: return Color("brandCard")
        case .empty: return Color("brandCard")
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .correct: return Color("brandPrimaryFg")
        case .present: return Color("brandAccentFg")
        case .absent: return Color("brandMutedFg")
        default: return Color("brandForeground")
        }
    }
    
    private var borderColor: Color {
        switch status {
        case .correct, .present, .absent:
            // No separate border color needed when filled
            return .clear
        case .tbd:
            // Border for the box the user is currently typing in
            return Color("brandMuted")
        case .empty:
            // Border for an empty, future box
            return Color("brandBorder")
        }
    }
}
