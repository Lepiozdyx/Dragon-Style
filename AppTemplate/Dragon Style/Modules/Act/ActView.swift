import SwiftUI
import SwiftData
import Observation

// MARK: - Pillar Model

struct Pillar: Identifiable {
    let id = UUID()
    let key: String          // stable key for persistence
    let title: String
    let subtitle: String
    let task: String
    let icon: String
    let color: Color
    let bgColor: Color
}

private let pillars: [Pillar] = [
    Pillar(
        key: "focus",
        title: "Focus",
        subtitle: "Concentrate your energy",
        task: "Read for 20 minutes without interruption",
        icon: "eye",
        color: Color(red: 0.30, green: 0.55, blue: 1.0),
        bgColor: Color(red: 0.08, green: 0.12, blue: 0.28)
    ),
    Pillar(
        key: "patience",
        title: "Patience",
        subtitle: "Master the art of waiting",
        task: "Listen to someone without interrupting",
        icon: "brain",
        color: Color(red: 0.60, green: 0.35, blue: 1.0),
        bgColor: Color(red: 0.12, green: 0.08, blue: 0.28)
    ),
    Pillar(
        key: "generosity",
        title: "Generosity",
        subtitle: "Give without expectation",
        task: "Share knowledge or resources freely",
        icon: "heart",
        color: Color(red: 0.90, green: 0.30, blue: 0.50),
        bgColor: Color(red: 0.22, green: 0.08, blue: 0.14)
    ),
    Pillar(
        key: "courage",
        title: "Courage",
        subtitle: "Face your fears",
        task: "Speak up for your beliefs",
        icon: "bolt",
        color: Color(red: 1.0, green: 0.55, blue: 0.10),
        bgColor: Color(red: 0.22, green: 0.10, blue: 0.02)
    ),
    Pillar(
        key: "silence",
        title: "Silence",
        subtitle: "Find power in stillness",
        task: "Practice not speaking unless necessary",
        icon: "speaker.slash",
        color: Color(red: 0.20, green: 0.75, blue: 0.70),
        bgColor: Color(red: 0.04, green: 0.18, blue: 0.18)
    ),
]

// MARK: - ViewModel

@Observable
final class ActViewModel {
    // checked[pillarKey] = date it was checked (startOfDay)
    var checked: [String: Date] = [:]
    var user: UserModel?

    func loadOrCreateUser(context: ModelContext) {
        let descriptor = FetchDescriptor<UserModel>()
        if let existing = try? context.fetch(descriptor), let first = existing.first {
            user = first
            restoreChecked()
        } else {
            let newUser = UserModel(xp: 0, level: 1, breatheSessions: [], decisionsMade: [], actionsComplete: [])
            context.insert(newUser)
            try? context.save()
            user = newUser
        }
    }

    /// Restore checked state from persisted ActionModels completed today
    private func restoreChecked() {
        guard let user else { return }
        checked = [:]
        let today = Date().startOfDay
        for action in user.actionsComplete where Calendar.current.isDateInToday(action.date) && action.isComplete {
            checked[action.title] = today
        }
    }

    func isChecked(_ pillar: Pillar) -> Bool {
        checked[pillar.key] == Date().startOfDay
    }

    func toggle(_ pillar: Pillar, context: ModelContext) {
        let today = Date().startOfDay
        if checked[pillar.key] == today {
            // uncheck — remove the matching ActionModel
            checked[pillar.key] = nil
            user?.actionsComplete.removeAll {
                $0.title == pillar.key && Calendar.current.isDateInToday($0.date)
            }
            user?.xp = max(0, (user?.xp ?? 0) - 10)
        } else {
            // check
            checked[pillar.key] = today
            let action = ActionModel(isComplete: true, title: pillar.key, date: Date())
            user?.actionsComplete.append(action)
            user?.xp = (user?.xp ?? 0) + 10
        }
        try? context.save()
    }

    var completedToday: Int {
        let today = Date().startOfDay
        return checked.values.filter { $0 == today }.count
    }

    var totalCompleted: Int {
        user?.actionsComplete.filter { $0.isComplete }.count ?? 0
    }
}

// MARK: - Stats Bar

private struct StatsBar: View {
    let today: Int
    let total: Int

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("\(today)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.15))
                Text("Today")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.5))
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color(white: 0.2))
                .frame(width: 1, height: 40)

            VStack(spacing: 4) {
                Text("\(total)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.15))
                Text("Total")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.5))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(Color(red: 0.14, green: 0.09, blue: 0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Pillar Row

private struct PillarRow: View {
    let pillar: Pillar
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(pillar.color.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: pillar.icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(pillar.color)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(pillar.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(0) total")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(white: 0.45))
                }
                Text(pillar.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(pillar.color.opacity(0.8))

                Text(pillar.task)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.65))
                    .padding(.top, 4)
            }

            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(isChecked ? pillar.color : Color(white: 0.35), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if isChecked {
                        Circle()
                            .fill(pillar.color)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isChecked)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(pillar.bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - ActView

struct ActView: View {
    @Environment(\.modelContext) private var context
    @State private var vm = ActViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Five Pillars")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.15))
                    Text("Daily actions forge the dragon within")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(white: 0.55))
                }
                .padding(.bottom, 20)

                // Stats
                StatsBar(today: vm.completedToday, total: vm.totalCompleted)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                // Pillars
                VStack(spacing: 12) {
                    ForEach(pillars) { pillar in
                        PillarRow(
                            pillar: pillar,
                            isChecked: vm.isChecked(pillar),
                            onToggle: { vm.toggle(pillar, context: context) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            Spacer(minLength: 100.fitH)
        }
        .onAppear {
            vm.loadOrCreateUser(context: context)
        }
    }
}

// MARK: - Preview

#Preview {
    ActView()
        .modelContainer(for: UserModel.self, inMemory: true)
}
