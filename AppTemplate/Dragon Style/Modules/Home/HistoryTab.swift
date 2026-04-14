import SwiftUI
import SwiftData
import Observation

// MARK: - History Tab

enum HistoryTab: CaseIterable {
    case breathing, decisions, actions

    var title: String {
        switch self {
        case .breathing:  return "Breathing"
        case .decisions:  return "Decisions"
        case .actions:    return "Actions"
        }
    }

    var icon: String {
        switch self {
        case .breathing:  return "wind"
        case .decisions:  return "flame"
        case .actions:    return "checkmark.square"
        }
    }

    var color: Color {
        switch self {
        case .breathing:  return Color(red: 0.20, green: 0.75, blue: 0.85)
        case .decisions:  return Color(red: 1.0, green: 0.60, blue: 0.10)
        case .actions:    return Color(red: 0.60, green: 0.35, blue: 1.0)
        }
    }

    var bgColor: Color {
        switch self {
        case .breathing:  return Color(red: 0.05, green: 0.18, blue: 0.20)
        case .decisions:  return Color(red: 0.22, green: 0.12, blue: 0.02)
        case .actions:    return Color(red: 0.14, green: 0.08, blue: 0.26)
        }
    }
}

// MARK: - Relative time helper

private func relativeTime(_ date: Date) -> String {
    let seconds = Int(Date().timeIntervalSince(date))
    if seconds < 60 { return "Just now" }
    let minutes = seconds / 60
    if minutes < 60 { return "\(minutes)m ago" }
    let hours = minutes / 60
    if hours < 24 { return "\(hours)h ago" }
    let days = hours / 24
    return "\(days)d ago"
}

// MARK: - History Entry Row

private struct HistoryRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let date: Date
    let xp: Int
    let tab: HistoryTab

    var xpText: String { xp >= 0 ? "+\(xp) XP" : "\(xp) XP" }
    var xpColor: Color { xp >= 0 ? .green : Color(red: 1.0, green: 0.30, blue: 0.30) }

    var body: some View {
        HStack(spacing: 14) {
            // Icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tab.color.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(tab.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.55))
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(white: 0.40))
                    Text(relativeTime(date))
                        .font(.system(size: 12))
                        .foregroundStyle(Color(white: 0.40))
                }
            }

            Spacer()

            Text(xpText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(xpColor)
        }
        .padding(16)
        .background(tab.bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let entries: Int
    let totalXP: Int

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("Total entries:")
                        .foregroundStyle(Color(white: 0.55))
                    Text("\(entries)")
                        .foregroundStyle(Color(red: 1.0, green: 0.70, blue: 0.15))
                        .fontWeight(.bold)
                }
                HStack(spacing: 4) {
                    Text("Total XP:")
                        .foregroundStyle(Color(white: 0.55))
                    Text(totalXP >= 0 ? "\(totalXP)" : "\(totalXP)")
                        .foregroundStyle(totalXP >= 0 ? Color(red: 1.0, green: 0.70, blue: 0.15) : Color(red: 1.0, green: 0.30, blue: 0.30))
                        .fontWeight(.bold)
                }
            }
            .font(.system(size: 14))
            Spacer()
        }
        .padding(.vertical, 18)
        .background(Color(white: 0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - HistoryViewModel

@Observable
final class HistoryViewModel {
    var selectedTab: HistoryTab = .breathing
    var user: UserModel?

    func load(context: ModelContext) {
        let descriptor = FetchDescriptor<UserModel>()
        user = try? context.fetch(descriptor).first
    }

    // MARK: Breathing entries
    var breathingEntries: [(session: BreathingSession, xp: Int)] {
        (user?.breatheSessions ?? [])
            .sorted { $0.date > $1.date }
            .map { ($0, $0.isSuccessful ? 15 : 0) }
    }

    var breathingTotalXP: Int {
        breathingEntries.reduce(0) { $0 + $1.xp }
    }

    // MARK: Decision entries
    var decisionEntries: [(decision: DecisionModel, xp: Int)] {
        (user?.decisionsMade ?? [])
            .sorted { $0.date > $1.date }
            .map { ($0, $0.saysYes ? 10 : -10) }
    }

    var decisionsTotalXP: Int {
        decisionEntries.reduce(0) { $0 + $1.xp }
    }

    // MARK: Action entries
    var actionEntries: [(action: ActionModel, xp: Int)] {
        (user?.actionsComplete ?? [])
            .filter { $0.isComplete }
            .sorted { $0.date > $1.date }
            .map { ($0, 10) }
    }

    var actionsTotalXP: Int {
        actionEntries.reduce(0) { $0 + $1.xp }
    }
}

// MARK: - HistoryView

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var vm = HistoryViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .padding(.top, 30)

            VStack(spacing: 6) {
                Text("History")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.15))
                Text("Your dragon's journey")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(white: 0.55))
            }
            .padding(.bottom, 24)

            // Tab selector
            HStack(spacing: 8) {
                ForEach(HistoryTab.allCases, id: \.self) { tab in
                    Button { vm.selectedTab = tab } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13))
                            Text(tab.title)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(vm.selectedTab == tab ? .white : Color(white: 0.45))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(vm.selectedTab == tab ? tab.color.opacity(0.85) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.2), value: vm.selectedTab)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(white: 0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            // Content
            ScrollView {
                VStack(spacing: 10) {
                    switch vm.selectedTab {
                    case .breathing:
                        if vm.breathingEntries.isEmpty {
                            EmptyHistoryView(tab: .breathing)
                        } else {
                            ForEach(vm.breathingEntries, id: \.session.id) { entry in
                                HistoryRow(
                                    icon: "wind",
                                    title: "Breathing",
                                    subtitle: "Breathing session completed",
                                    date: entry.session.date,
                                    xp: entry.xp,
                                    tab: .breathing
                                )
                            }
                            SummaryCard(entries: vm.breathingEntries.count, totalXP: vm.breathingTotalXP)
                        }

                    case .decisions:
                        if vm.decisionEntries.isEmpty {
                            EmptyHistoryView(tab: .decisions)
                        } else {
                            ForEach(vm.decisionEntries, id: \.decision.id) { entry in
                                HistoryRow(
                                    icon: "flame",
                                    title: "Decision",
                                    subtitle: entry.decision.saysYes ? "Yes - Fire decision" : "No - Hesitation",
                                    date: entry.decision.date,
                                    xp: entry.xp,
                                    tab: .decisions
                                )
                            }
                            SummaryCard(entries: vm.decisionEntries.count, totalXP: vm.decisionsTotalXP)
                        }

                    case .actions:
                        if vm.actionEntries.isEmpty {
                            EmptyHistoryView(tab: .actions)
                        } else {
                            ForEach(vm.actionEntries, id: \.action.id) { entry in
                                HistoryRow(
                                    icon: "checkmark.square",
                                    title: "Action",
                                    subtitle: "\(entry.action.title.capitalized) task completed",
                                    date: entry.action.date,
                                    xp: entry.xp,
                                    tab: .actions
                                )
                            }
                            SummaryCard(entries: vm.actionEntries.count, totalXP: vm.actionsTotalXP)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .onAppear { vm.load(context: context) }
    }
}

// MARK: - Empty State

private struct EmptyHistoryView: View {
    let tab: HistoryTab
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: tab.icon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(tab.color.opacity(0.5))
            Text("No \(tab.title.lowercased()) yet")
                .font(.system(size: 16))
                .foregroundStyle(Color(white: 0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: UserModel.self, inMemory: true)
}
