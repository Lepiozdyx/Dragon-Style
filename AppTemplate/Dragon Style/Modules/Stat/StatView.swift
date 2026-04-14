import SwiftUI
import SwiftData
import Observation

// MARK: - ViewModel

@Observable
final class StatViewModel {
    var user: UserModel?

    func load(context: ModelContext) {
        let descriptor = FetchDescriptor<UserModel>()
        user = try? context.fetch(descriptor).first
    }

    var totalXP: Int { user?.xp ?? 0 }
    var level: Int { user?.level ?? 0 }

    var stageName: String { DragonStage.stage(for: level).name }

    // Streak — consecutive days with any activity
    var streak: Int {
        guard let user else { return 0 }
        let calendar = Calendar.current
        var allDates: Set<Date> = []
        user.breatheSessions.forEach { allDates.insert(calendar.startOfDay(for: $0.date)) }
        user.decisionsMade.forEach { allDates.insert(calendar.startOfDay(for: $0.date)) }
        user.actionsComplete.forEach { allDates.insert(calendar.startOfDay(for: $0.date)) }

        var count = 0
        var check = calendar.startOfDay(for: Date())
        while allDates.contains(check) {
            count += 1
            check = calendar.date(byAdding: .day, value: -1, to: check)!
        }
        return count
    }

    var sessionsToday: Int {
        user?.breatheSessions.filter { Calendar.current.isDateInToday($0.date) }.count ?? 0
    }

    var breathingTotal: Int { user?.breatheSessions.count ?? 0 }
    var decisionsTotal: Int { user?.decisionsMade.count ?? 0 }
    var actionsTotal: Int { user?.actionsComplete.filter { $0.isComplete }.count ?? 0 }

    // XP per day for last 6 days
    var xpGrowthData: [(label: String, xp: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<6).reversed().map { offset -> (String, Int) in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let xp = xpOnDay(day)
            return ("Day \(6 - offset)", xp)
        }
    }

    private func xpOnDay(_ day: Date) -> Int {
        guard let user else { return 0 }
        let cal = Calendar.current
        var xp = 0
        user.breatheSessions.filter { cal.isDate($0.date, inSameDayAs: day) && $0.isSuccessful }.forEach { _ in xp += 15 }
        user.decisionsMade.filter { cal.isDate($0.date, inSameDayAs: day) }.forEach { xp += $0.saysYes ? 10 : -10 }
        user.actionsComplete.filter { cal.isDate($0.date, inSameDayAs: day) && $0.isComplete }.forEach { _ in xp += 10 }
        return max(0, xp)
    }

    // Pillar balance — count per pillar key today
    var pillarCounts: [(key: String, count: Int, color: Color)] {
        guard let user else { return [] }
        let keys = ["focus", "patience", "generosity", "courage", "silence"]
        let colors: [Color] = [
            Color(red: 0.30, green: 0.55, blue: 1.0),
            Color(red: 0.60, green: 0.35, blue: 1.0),
            Color(red: 0.90, green: 0.30, blue: 0.50),
            Color(red: 1.0, green: 0.55, blue: 0.10),
            Color(red: 0.20, green: 0.75, blue: 0.70),
        ]
        return keys.enumerated().map { i, key in
            let count = user.actionsComplete.filter { $0.title == key && $0.isComplete }.count
            return (key, count, colors[i])
        }
    }

    var yesDecisions: Int { user?.decisionsMade.filter { $0.saysYes }.count ?? 0 }
    var noDecisions: Int { user?.decisionsMade.filter { !$0.saysYes }.count ?? 0 }

    var decisionPattern: String {
        let yes = yesDecisions
        let no = noDecisions
        let total = yes + no
        guard total > 0 else { return "No decisions yet" }
        let ratio = Double(yes) / Double(total)
        if ratio > 0.7 { return "You act with dragon courage!" }
        if ratio > 0.5 { return "You lean towards action" }
        if ratio == 0.5 { return "Perfect balance between yes and no" }
        return "You proceed with caution - thoughtful hesitation"
    }
}

// MARK: - Stat Card (top 4)

private struct TopStatCard: View {
    let icon: String
    let iconColor: Color
    let bgColor: Color
    let label: String
    let value: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.5))
            }
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.45))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color(white: 0.65))
            Spacer()
            Text("\(value)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

// MARK: - XP Line Chart

private struct XPLineChart: View {
    let data: [(label: String, xp: Int)]

    private var maxXP: Int { max(data.map(\.xp).max() ?? 1, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent XP Growth")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let pts = chartPoints(w: w, h: h)

                ZStack(alignment: .bottomLeading) {
                    // Grid lines
                    ForEach([0, 0.25, 0.5, 0.75, 1.0], id: \.self) { frac in
                        Path { p in
                            let y = h * (1 - frac) - 20
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: w, y: y))
                        }
                        .stroke(Color(white: 0.15), lineWidth: 1)
                    }

                    // Y labels
                    ForEach([0, 0.5, 1.0], id: \.self) { frac in
                        Text("\(Int(Double(maxXP) * frac))")
                            .font(.system(size: 9))
                            .foregroundStyle(Color(white: 0.35))
                            .position(x: 12, y: h * (1 - frac) - 20)
                    }

                    // Line
                    if pts.count > 1 {
                        Path { p in
                            p.move(to: pts[0])
                            for pt in pts.dropFirst() { p.addLine(to: pt) }
                        }
                        .stroke(
                            LinearGradient(colors: [Color(red: 1.0, green: 0.60, blue: 0.10), Color(red: 1.0, green: 0.80, blue: 0.20)],
                                           startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )

                        // Dots
                        ForEach(pts.indices, id: \.self) { i in
                            Circle()
                                .fill(Color(red: 1.0, green: 0.70, blue: 0.10))
                                .frame(width: 7, height: 7)
                                .position(pts[i])
                        }
                    }

                    // X labels
                    ForEach(data.indices, id: \.self) { i in
                        Text(data[i].label)
                            .font(.system(size: 9))
                            .foregroundStyle(Color(white: 0.35))
                            .position(x: pts[i].x, y: h - 6)
                    }
                }
            }
            .frame(height: 130)
        }
        .padding(16)
        .background(Color(white: 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func chartPoints(w: CGFloat, h: CGFloat) -> [CGPoint] {
        let usableH = h - 28
        let step = data.count > 1 ? w / CGFloat(data.count - 1) : w
        return data.enumerated().map { i, d in
            let x = CGFloat(i) * step
            let y = usableH - (usableH * CGFloat(d.xp) / CGFloat(maxXP)) + 4
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Donut Chart

private struct DonutChart: View {
    let data: [(key: String, count: Int, color: Color)]

    private var total: Int { max(data.map(\.count).reduce(0, +), 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Five Pillars Balance")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            HStack(spacing: 24) {
                ZStack {
                    ForEach(slices().indices, id: \.self) { i in
                        let s = slices()[i]
                        DonutSlice(startAngle: s.start, endAngle: s.end, color: data[i].color)
                    }
                    Circle()
                        .fill(Color(white: 0.07))
                        .frame(width: 60, height: 60)
                }
                .frame(width: 110, height: 110)

                // Legend
                let cols = data.chunked(into: 2)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(data.indices, id: \.self) { i in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(data[i].color)
                                .frame(width: 8, height: 8)
                            Text("\(data[i].key.capitalized): \(data[i].count)")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(white: 0.65))
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color(white: 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func slices() -> [(start: Angle, end: Angle)] {
        var result: [(Angle, Angle)] = []
        var current = -90.0
        for d in data {
            let frac = Double(d.count) / Double(total)
            let sweep = frac * 360
            result.append((.degrees(current), .degrees(current + sweep)))
            current += sweep
        }
        return result
    }
}

private struct DonutSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let r = min(geo.size.width, geo.size.height) / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            Path { p in
                p.addArc(center: center, radius: r, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                p.addArc(center: center, radius: r * 0.55, startAngle: endAngle, endAngle: startAngle, clockwise: true)
                p.closeSubpath()
            }
            .fill(color)
        }
    }
}

// MARK: - Decision Bar Chart

private struct DecisionBarChart: View {
    let yes: Int
    let no: Int
    let pattern: String

    private var maxVal: Int { max(yes, no, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Decision Pattern")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: 24) {
                Spacer()
                BarColumn(label: "YES", value: yes, maxValue: maxVal,
                          color: Color(red: 1.0, green: 0.60, blue: 0.10))
                BarColumn(label: "NO", value: no, maxValue: maxVal,
                          color: Color(white: 0.30))
                Spacer()
            }
            .frame(height: 100)

            // Axis
            Rectangle()
                .fill(Color(white: 0.18))
                .frame(height: 1)

            Text(pattern)
                .font(.system(size: 13))
                .foregroundStyle(Color(white: 0.50))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color(white: 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct BarColumn: View {
    let label: String
    let value: Int
    let maxValue: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 11))
                .foregroundStyle(Color(white: 0.5))
            GeometryReader { geo in
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color)
                        .frame(height: geo.size.height * CGFloat(value) / CGFloat(maxValue))
                }
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(white: 0.5))
                .padding(.top)
        }
        .frame(width: 48)
    }
}

// MARK: - Array chunk helper

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}

// MARK: - StatView

struct StatView: View {
    @Environment(\.modelContext) private var context
    @State private var vm = StatViewModel()
    @State private var showHistory = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 6) {
                    Text("Dragon Stats")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.15))
                    Text("Track your evolution")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(white: 0.55))
                }
                .padding(.bottom, 8)

                // Top 4 stat cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    TopStatCard(
                        icon: "star.circle",
                        iconColor: Color(red: 1.0, green: 0.75, blue: 0.15),
                        bgColor: Color(red: 0.20, green: 0.12, blue: 0.02),
                        label: "Total XP",
                        value: "\(vm.totalXP)",
                        subtitle: nil
                    )
                    TopStatCard(
                        icon: "arrow.up.circle",
                        iconColor: Color(red: 0.60, green: 0.35, blue: 1.0),
                        bgColor: Color(red: 0.10, green: 0.07, blue: 0.22),
                        label: "Level",
                        value: "\(vm.level)",
                        subtitle: vm.stageName
                    )
                    TopStatCard(
                        icon: "flame",
                        iconColor: Color(red: 1.0, green: 0.55, blue: 0.10),
                        bgColor: Color(red: 0.20, green: 0.10, blue: 0.02),
                        label: "Streak",
                        value: "\(vm.streak)",
                        subtitle: "days"
                    )
                    TopStatCard(
                        icon: "wind",
                        iconColor: Color(red: 0.20, green: 0.75, blue: 0.85),
                        bgColor: Color(red: 0.05, green: 0.15, blue: 0.20),
                        label: "Sessions",
                        value: "\(vm.sessionsToday)",
                        subtitle: "today"
                    )
                }
                .padding(.horizontal, 20)

                // Activity Summary
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.square")
                            .foregroundStyle(Color(red: 0.60, green: 0.35, blue: 1.0))
                        Text("Activity Summary")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Divider().background(Color(white: 0.18))

                    ActivityRow(label: "Breathing Sessions",
                                value: vm.breathingTotal,
                                color: Color(red: 0.20, green: 0.75, blue: 0.85))
                    ActivityRow(label: "Decisions Made",
                                value: vm.decisionsTotal,
                                color: Color(red: 1.0, green: 0.60, blue: 0.10))
                    ActivityRow(label: "Actions Completed",
                                value: vm.actionsTotal,
                                color: Color(red: 0.60, green: 0.35, blue: 1.0))
                }
                .padding(16)
                .background(Color(white: 0.07))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)

                // XP Growth Chart
                XPLineChart(data: vm.xpGrowthData)
                    .padding(.horizontal, 20)

                // Pillars Donut
                DonutChart(data: vm.pillarCounts)
                    .padding(.horizontal, 20)

                // Decision Bar Chart
                DecisionBarChart(yes: vm.yesDecisions, no: vm.noDecisions, pattern: vm.decisionPattern)
                    .padding(.horizontal, 20)

                // View History button
                Button { showHistory = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                        Text("View History")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color(white: 0.55))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(white: 0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .padding(.top, 8)
            
            Spacer(minLength: 100.fitH)
        }
        .fullScreenCover(isPresented: $showHistory) {
            HistoryView()
        }
        .onAppear { vm.load(context: context) }
    }
}

// MARK: - Preview

#Preview {
    StatView()
        .modelContainer(for: UserModel.self, inMemory: true)
}
