import SwiftUI
import SwiftData
import Observation

// MARK: - Dragon Stage

enum DragonStage {
    case egg        // level 0
    case snake      // level 1
    case cloudDragon // level 2
    case fireDragon  // level 3
    case heavenlyDragon // level 4+

    var name: String {
        switch self {
        case .egg:             return "Dragon Egg"
        case .snake:           return "Snake"
        case .cloudDragon:     return "Cloud Dragon"
        case .fireDragon:      return "Fire Dragon"
        case .heavenlyDragon:  return "Heavenly Dragon"
        }
    }

    var asset: String {
        switch self {
        case .egg:             return "egg"
        case .snake:           return "snake"
        case .cloudDragon:     return "cloudD"
        case .fireDragon:      return "fireD"
        case .heavenlyDragon:  return "heavenlyD"
        }
    }

    var glowColor: Color {
        switch self {
        case .egg:             return Color(red: 1.0, green: 0.70, blue: 0.0)
        case .snake:           return Color(red: 0.20, green: 0.80, blue: 0.20)
        case .cloudDragon:     return Color(red: 0.85, green: 0.90, blue: 1.0)
        case .fireDragon:      return Color(red: 1.0, green: 0.30, blue: 0.0)
        case .heavenlyDragon:  return Color(red: 0.30, green: 0.50, blue: 1.0)
        }
    }

    static func stage(for level: Int) -> DragonStage {
        switch level {
        case 0:       return .egg
        case 1:       return .snake
        case 2:       return .cloudDragon
        case 3:       return .fireDragon
        default:      return .heavenlyDragon
        }
    }
}

// MARK: - ViewModel

@Observable
final class HomeViewModel {
    var user: UserModel?

    var stage: DragonStage {
        DragonStage.stage(for: user?.level ?? 0)
    }

    var xp: Int { user?.xp ?? 0 }
    var level: Int { user?.level ?? 0 }

    // XP needed per level
    let xpPerLevel = 100

    var xpProgress: Double {
        let current = xp % xpPerLevel
        return Double(current) / Double(xpPerLevel)
    }

    var xpDisplay: String { "\(xp % xpPerLevel) / \(xpPerLevel) XP" }

    var breathingToday: Int {
        user?.breatheSessions
            .filter { Calendar.current.isDateInToday($0.date) }
            .count ?? 0
    }

    var decisionsToday: Int {
        user?.decisionsMade
            .filter { Calendar.current.isDateInToday($0.date) }
            .count ?? 0
    }

    func loadOrCreateUser(context: ModelContext) {
        let descriptor = FetchDescriptor<UserModel>()
        if let existing = try? context.fetch(descriptor), let first = existing.first {
            user = first
            syncLevel()
        } else {
            let newUser = UserModel(xp: 0, level: 0, breatheSessions: [], decisionsMade: [], actionsComplete: [])
            context.insert(newUser)
            try? context.save()
            user = newUser
        }
    }

    private func syncLevel() {
        guard let user else { return }
        user.level = user.xp / xpPerLevel
    }
}

// MARK: - Dragon View

private struct DragonView: View {
    let stage: DragonStage
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Glow circle background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [stage.glowColor.opacity(0.45), stage.glowColor.opacity(0.0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .scaleEffect(pulse ? 1.08 : 0.95)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulse)

            Image(stage.asset)
                .resizable()
                .scaledToFit()
        }
        .onAppear { pulse = true }
        .animation(.easeInOut(duration: 0.5), value: stage.asset)
    }
}

// MARK: - XP Progress Bar

private struct XPProgressBar: View {
    let level: Int
    let xpDisplay: String
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Level \(level)")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(white: 0.6))
                Spacer()
                Text(xpDisplay)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 1.0, green: 0.70, blue: 0.10))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(white: 0.18))
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.65, blue: 0.10),
                                    Color(red: 0.95, green: 0.45, blue: 0.02)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * max(0.01, progress), height: 6)
                        .animation(.easeInOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: Int
    let label: String
    let color: Color
    let bgColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color(white: 0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - HomeView

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @State private var vm = HomeViewModel()
    @State var showHistory = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color(red: 0.45, green: 0.28, blue: 0.02))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color(red: 1.0, green: 0.55, blue: 0.0).opacity(0.4), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 4)
                
                // Dragon name
                Text(vm.stage.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.15))
                    .padding(.bottom, 8)
                
                Spacer()
                
                // Dragon image
                DragonView(stage: vm.stage)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // XP bar
                XPProgressBar(
                    level: vm.level,
                    xpDisplay: vm.xpDisplay,
                    progress: vm.xpProgress
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Stats
                HStack(spacing: 12) {
                    StatCard(
                        value: vm.breathingToday,
                        label: "Breathing",
                        color: Color(red: 0.25, green: 0.75, blue: 1.0),
                        bgColor: Color(red: 0.06, green: 0.14, blue: 0.22)
                    )
                    StatCard(
                        value: vm.decisionsToday,
                        label: "Decisions",
                        color: Color(red: 1.0, green: 0.70, blue: 0.15),
                        bgColor: Color(red: 0.18, green: 0.11, blue: 0.03)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                Spacer(minLength: 100.fitH)
            }
        }
        .fullScreenCover(isPresented: $showHistory) {
            HistoryView()
        }
        .onAppear {
            vm.loadOrCreateUser(context: context)
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: UserModel.self, inMemory: true)
}
