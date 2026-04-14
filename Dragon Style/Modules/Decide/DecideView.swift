import SwiftUI
import SwiftData
import Observation

// MARK: - Decision Model

struct Decision: Identifiable {
    let id = UUID()
    let question: String
    let yesMessage: String   // shown when user taps YES
    let noMessage: String    // shown when user taps NO
}

// MARK: - Decision Bank

private let decisionBank: [Decision] = [
    Decision(
        question: "Help someone who needs it?",
        yesMessage: "Discomfort forges power",
        noMessage: "Fire doesn't hesitate"
    ),
    Decision(
        question: "Take the difficult conversation now?",
        yesMessage: "Courage builds with every word",
        noMessage: "Silence has a cost too"
    ),
    Decision(
        question: "Start the task you've been avoiding?",
        yesMessage: "Action breaks the spell",
        noMessage: "Tomorrow is another dragon"
    ),
    Decision(
        question: "Say no to something that drains you?",
        yesMessage: "Boundaries are fire",
        noMessage: "Every yes costs something"
    ),
    Decision(
        question: "Reach out to someone you miss?",
        yesMessage: "Connection is strength",
        noMessage: "Silence speaks too"
    ),
    Decision(
        question: "Do the thing that scares you most today?",
        yesMessage: "Fear fed is fear defeated",
        noMessage: "The dragon waits"
    ),
    Decision(
        question: "Apologize first, even if it wasn't your fault?",
        yesMessage: "Humility is a warrior's weapon",
        noMessage: "Pride has a heavy price"
    ),
    Decision(
        question: "Put the phone down and be present?",
        yesMessage: "Real life burns brightest",
        noMessage: "The scroll never ends"
    ),
    Decision(
        question: "Ask for help instead of struggling alone?",
        yesMessage: "Dragons travel in clans",
        noMessage: "Solitude is its own lesson"
    ),
]

// MARK: - View State

enum DecideState {
    case idle
    case countdown
    case result(answeredYes: Bool)
}

// MARK: - ViewModel

@Observable
final class DecideViewModel {
    var state: DecideState = .idle
    var currentDecision: Decision = decisionBank.randomElement()!
    var countdown: Int = 7
    var user: UserModel?

    private var timer: Timer?

    // decisions made today
    var decisionsToday: Int {
        guard let user else { return 0 }
        return user.decisionsMade.filter { Calendar.current.isDateInToday($0.date) }.count
    }

    func loadOrCreateUser(context: ModelContext) {
        let descriptor = FetchDescriptor<UserModel>()
        if let existing = try? context.fetch(descriptor), let first = existing.first {
            user = first
        } else {
            let newUser = UserModel(xp: 0, level: 1, breatheSessions: [], decisionsMade: [], actionsComplete: [])
            context.insert(newUser)
            try? context.save()
            user = newUser
        }
    }

    func startCountdown() {
        countdown = 7
        state = .countdown
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.countdown > 1 {
                self.countdown -= 1
            } else {
                // Time's up → treat as NO
                self.answer(yes: false)
            }
        }
    }

    func answer(yes: Bool, context: ModelContext? = nil) {
        timer?.invalidate()
        timer = nil
        withAnimation(.easeInOut(duration: 0.3)) {
            state = .result(answeredYes: yes)
        }
        // save XP & append decision
        if let user {
            let decision = DecisionModel(saysYes: yes, date: Date())
            user.decisionsMade.append(decision)
            user.xp += yes ? 10 : -10
            try? context?.save()
        }
    }

    func next() {
        currentDecision = decisionBank.randomElement()!
        withAnimation(.easeInOut(duration: 0.25)) {
            state = .idle
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Idle Card

private struct IdleCard: View {
    let decision: Decision

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.10))

            Text(decision.question)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color(white: 0.10))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Countdown Card

private struct CountdownCard: View {
    let vm: DecideViewModel
    let onYes: () -> Void
    let onNo: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.5))
                Text("seconds")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.5))
            }

            Image(systemName: "flame")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.10))

            Text(vm.currentDecision.question)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button(action: onYes) {
                    Text("YES")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(red: 1.0, green: 0.55, blue: 0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.5), radius: 10, y: 4)
                }
                .buttonStyle(.plain)

                Button(action: onNo) {
                    Text("NO")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(white: 0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(white: 0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(red: 0.16, green: 0.10, blue: 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Result Card

private struct ResultCard: View {
    let decision: Decision
    let answeredYes: Bool
    let onNext: () -> Void

    private var message: String { answeredYes ? decision.yesMessage : decision.noMessage }
    private var xpText: String { answeredYes ? "+10 XP" : "-10 XP" }
    private var xpColor: Color { answeredYes ? Color(red: 1.0, green: 0.65, blue: 0.10) : Color(white: 0.55) }
    private var cardBg: Color {
        answeredYes
            ? Color(red: 0.20, green: 0.12, blue: 0.02)
            : Color(white: 0.10)
    }
    private var iconColor: Color {
        answeredYes
            ? Color(red: 1.0, green: 0.60, blue: 0.10)
            : Color(white: 0.4)
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(iconColor)

            Text(message)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(xpText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(xpColor)

            Text("Why did you choose this?")
                .font(.system(size: 14))
                .foregroundStyle(Color(white: 0.45))

            Button(action: onNext) {
                Text("Next Decision")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.60, blue: 0.10),
                                Color(red: 0.85, green: 0.40, blue: 0.02)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.4), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - DecideView

struct DecideView: View {
    @Environment(\.modelContext) private var context
    @State private var vm = DecideViewModel()

    var body: some View {
        
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Fire Decisions")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.15))

                    Text("Dragons don't hesitate - 7 seconds to choose")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(white: 0.55))

                    HStack(spacing: 6) {
                        Image(systemName: "flame")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 1.0, green: 0.60, blue: 0.10))
                        Text("\(vm.decisionsToday) decisions today")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(red: 1.0, green: 0.60, blue: 0.10))
                    }
                    .padding(.top, 4)
                }
                .padding(.bottom, 24)

                // Countdown number (only during countdown)
                if case .countdown = vm.state {
                    Text("\(vm.countdown)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.65, blue: 0.10))
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: vm.countdown)
                        .padding(.bottom, 16)
                } else {
                    Spacer()
                }

                // Card
                Group {
                    switch vm.state {
                    case .idle:
                        IdleCard(decision: vm.currentDecision)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))

                    case .countdown:
                        CountdownCard(
                            vm: vm,
                            onYes: { vm.answer(yes: true, context: context) },
                            onNo:  { vm.answer(yes: false, context: context) }
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))

                    case .result(let answeredYes):
                        ResultCard(
                            decision: vm.currentDecision,
                            answeredYes: answeredYes,
                            onNext: { vm.next() }
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: stateKey)
                .padding(.horizontal, 20)

                Spacer()

                // Start button (idle only)
                if case .idle = vm.state {
                    Button { vm.startCountdown() } label: {
                        Text("Start")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.65, blue: 0.10),
                                        Color(red: 0.90, green: 0.45, blue: 0.02)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: Color(red: 1.0, green: 0.55, blue: 0.0).opacity(0.5), radius: 16, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.bottom, 100)
            .animation(.easeInOut(duration: 0.3), value: stateKey)
        
        .onAppear { vm.loadOrCreateUser(context: context) }
        .onDisappear { vm.stop() }
    }

    // Hashable key to drive animation
    private var stateKey: String {
        switch vm.state {
        case .idle:                   return "idle"
        case .countdown:              return "countdown"
        case .result(let yes):        return "result-\(yes)"
        }
    }
}

// MARK: - Preview

#Preview {
    DecideView()
        .modelContainer(for: UserModel.self, inMemory: true)
}
