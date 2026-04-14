import SwiftUI
import SwiftData
import Observation

// MARK: - Breathe Element Model

enum BreatheElement: CaseIterable {
    case water, fire, earth

    var title: String {
        switch self {
        case .water: return "Water"
        case .fire:  return "Fire"
        case .earth: return "Earth"
        }
    }

    var icon: String {
        switch self {
        case .water: return "drop"
        case .fire:  return "flame"
        case .earth: return "mountain.2"
        }
    }

    var color: Color {
        switch self {
        case .water: return Color(red: 0.20, green: 0.60, blue: 1.00)
        case .fire:  return Color(red: 1.00, green: 0.55, blue: 0.10)
        case .earth: return Color(red: 0.20, green: 0.78, blue: 0.35)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .water: return [Color(red: 0.25, green: 0.65, blue: 1.0), Color(red: 0.10, green: 0.75, blue: 0.95)]
        case .fire:  return [Color(red: 1.0, green: 0.60, blue: 0.10), Color(red: 1.0, green: 0.40, blue: 0.05)]
        case .earth: return [Color(red: 0.22, green: 0.82, blue: 0.38), Color(red: 0.15, green: 0.65, blue: 0.28)]
        }
    }
}

// MARK: - Date helper

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

// MARK: - ViewModel

@Observable
final class BreatheViewModel {
    var selectedElement: BreatheElement = .water
    var user: UserModel?

    func loadOrCreateUser(context: ModelContext) {
        let descriptor = FetchDescriptor<UserModel>()
        if let existing = try? context.fetch(descriptor), let first = existing.first {
            user = first
        } else {
            let newUser = UserModel(
                xp: 0,
                level: 1,
                breatheSessions: [],
                decisionsMade: [],
                actionsComplete: []
            )
            context.insert(newUser)
            try? context.save()
            user = newUser
        }
    }
}

// MARK: - Element Selector Card

private struct ElementCard: View {
    let element: BreatheElement
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: element.icon)
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(.white)
                Text(element.title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? element.color : Color(white: 0.12))
            }
            .animation(.easeInOut(duration: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main Circle (selection screen)

private struct BreathCircle: View {
    let element: BreatheElement

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: element.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: "sparkles")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.white)
            }
            .animation(.easeInOut(duration: 0.4), value: element)
    }
}

// MARK: - Breathe Phase

enum BreathePhase {
    case breatheIn, hold, breatheOut

    var label: String {
        switch self {
        case .breatheIn:  return "Breathe In"
        case .hold:       return "Hold"
        case .breatheOut: return "Breathe Out"
        }
    }

    var duration: Int {
        switch self {
        case .breatheIn:  return 4
        case .hold:       return 4
        case .breatheOut: return 6
        }
    }

    var next: BreathePhase {
        switch self {
        case .breatheIn:  return .hold
        case .hold:       return .breatheOut
        case .breatheOut: return .breatheIn
        }
    }
}

// MARK: - Session ViewModel

@Observable
final class BreatheSessionViewModel {
    let element: BreatheElement
    let totalCycles: Int = 10

    var phase: BreathePhase = .breatheIn
    var currentCycle: Int = 1
    var countdown: Int = BreathePhase.breatheIn.duration
    var isRunning: Bool = false
    var isComplete: Bool = false
    var circleProgress: Double = 0

    private var timer: Timer?

    init(element: BreatheElement) {
        self.element = element
    }

    var assetName: String {
        let prefix: String
        switch element {
        case .water: prefix = "water"
        case .fire:  prefix = "fire"
        case .earth: prefix = "earth"
        }
        switch phase {
        case .breatheIn:  return "\(prefix)-breathe"
        case .hold:       return "\(prefix)-hold"
        case .breatheOut: return "\(prefix)-breatheOut"
        }
    }

    var phaseGradient: [Color] {
        switch phase {
        case .breatheIn:  return element.gradientColors
        case .hold:       return [Color(red: 0.9, green: 0.7, blue: 0.1), Color(red: 0.7, green: 0.4, blue: 0.0)]
        case .breatheOut: return [element.color.opacity(0.5), element.color.opacity(0.2)]
        }
    }

    var glowColor: Color {
        switch phase {
        case .breatheIn:  return element.color.opacity(0.5)
        case .hold:       return Color.yellow.opacity(0.4)
        case .breatheOut: return element.color.opacity(0.2)
        }
    }

    func start() {
        isRunning = true
        phase = .breatheIn
        countdown = phase.duration
        currentCycle = 1
        circleProgress = 0
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        if countdown > 1 {
            countdown -= 1
            let elapsed = Double(phase.duration - countdown + 1)
            withAnimation(.linear(duration: 1)) {
                circleProgress = elapsed / Double(phase.duration)
            }
        } else {
            advancePhase()
        }
    }

    private func advancePhase() {
        let next = phase.next
        if phase == .breatheOut {
            if currentCycle >= totalCycles {
                timer?.invalidate()
                timer = nil
                withAnimation { isComplete = true; isRunning = false }
                return
            }
            currentCycle += 1
        }
        phase = next
        countdown = next.duration
        withAnimation(.easeInOut(duration: 0.3)) { circleProgress = 0 }
    }
}

// MARK: - Breathing Circle

private struct BreathingCircle: View {
    let vm: BreatheSessionViewModel
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(vm.glowColor)
                .scaleEffect(pulse ? 1.2 : 1.0)
                .blur(radius: 36)
                .animation(
                    vm.phase == .hold
                        ? .easeInOut(duration: 1.1).repeatForever(autoreverses: true)
                        : .easeInOut(duration: 0.5),
                    value: pulse
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [vm.phaseGradient[0], vm.phaseGradient[1]],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )

            Circle()
                .trim(from: 0, to: vm.circleProgress)
                .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Image(vm.assetName)
                .resizable()
                .scaledToFit()
                .padding(20)

            VStack(spacing: 2) {
                Spacer()
                Text(vm.phase.label)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                Text("\(vm.countdown)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                Spacer().frame(height: 20)
            }
        }
        .onChange(of: vm.phase) { _, _ in pulse = vm.phase == .hold }
        .onAppear { pulse = vm.phase == .hold }
    }
}

// MARK: - Cycle Progress Bar

private struct CycleProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text("Cycle ")
                    .foregroundStyle(Color(white: 0.55))
                Text("\(current)")
                    .foregroundStyle(.yellow)
                    .fontWeight(.bold)
                Text(" / \(total)")
                    .foregroundStyle(Color(white: 0.55))
            }
            .font(.system(size: 15))

            HStack(spacing: 4) {
                ForEach(1...total, id: \.self) { i in
                    Capsule()
                        .fill(i <= current ? Color.yellow : Color(white: 0.22))
                        .frame(height: 4)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Completion Overlay

private struct CompletionOverlay: View {
    let sessionsToday: Int
    let onContinue: () -> Void

    var body: some View {
        Color.black.opacity(0.55)
            .ignoresSafeArea()
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.20, green: 0.13, blue: 0.04))
                    .overlay {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(white: 0.18))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 34, weight: .light))
                                    .foregroundStyle(.yellow)
                            }

                            Text("You breathed like\na dragon!")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.yellow)
                                .multilineTextAlignment(.center)

                            Text("+15 XP earned")
                                .font(.system(size: 15))
                                .foregroundStyle(Color(white: 0.75))

                            Text("Sessions today: \(sessionsToday)")
                                .font(.system(size: 15))
                                .foregroundStyle(Color(white: 0.5))

                            Button(action: onContinue) {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(red: 0.42, green: 0.20, blue: 0.02))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 28)
            }
    }
}

// MARK: - BreatheSessionView

struct BreatheSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var vm: BreatheSessionViewModel
    @State private var user: UserModel?

    init(element: BreatheElement) {
        _vm = State(initialValue: BreatheSessionViewModel(element: element))
    }

    private var sessionsToday: Int {
        user?.breatheSessions.filter { Calendar.current.isDateInToday($0.date) }.count ?? 1
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Dragon Breath")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.15))
                Text("Find your calm through ancient breathing")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(white: 0.6))
            }
            .padding(.bottom, 16)

            Spacer()

            BreathingCircle(vm: vm)
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 40)

            Spacer()

            CycleProgressBar(current: vm.currentCycle, total: vm.totalCycles)
                .padding(.bottom, 24)

            Button {
                vm.stop()
                dismiss()
            } label: {
                Text("Stop")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(red: 0.42, green: 0.07, blue: 0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .onAppear {
            vm.start()
            user = try? context.fetch(FetchDescriptor<UserModel>()).first
        }
        .onDisappear { vm.stop() }
        .overlay {
            if vm.isComplete {
                CompletionOverlay(sessionsToday: sessionsToday) {
                    saveSession()
                    dismiss()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: vm.isComplete)
    }

    private func saveSession() {
        guard let user else { return }
        let session = BreathingSession(isSuccessful: true, date: Date())
        user.breatheSessions.append(session)
        user.xp += 15
        try? context.save()
    }
}

// MARK: - BreatheView (selection screen)

struct BreatheView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = BreatheViewModel()
    @State private var showSession = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24.fitH) {
                VStack(spacing: 8) {
                    Text("Dragon Breath")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.15))

                    Text("Find your calm through ancient breathing")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(white: 0.6))
                }
                .padding(.bottom, 24)

                HStack(spacing: 10) {
                    ForEach(BreatheElement.allCases, id: \.self) { element in
                        ElementCard(
                            element: element,
                            isSelected: viewModel.selectedElement == element,
                            onTap: { viewModel.selectedElement = element }
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                BreathCircle(element: viewModel.selectedElement)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal, 36)

                Spacer()

                Button {
                    showSession = true
                } label: {
                    Text("Start Breathing")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.65, blue: 0.10),
                                    Color(red: 0.95, green: 0.50, blue: 0.05)
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
            }
            Spacer(minLength: 100.fitH)
        }
        .fullScreenCover(isPresented: $showSession) {
            BreatheSessionView(element: viewModel.selectedElement)
        }
        .onAppear {
            viewModel.loadOrCreateUser(context: context)
        }
    }
}

// MARK: - Preview

#Preview {
    BreatheView()
        .modelContainer(for: UserModel.self, inMemory: true)
}
