import SwiftUI
import Observation

// MARK: - Tab Model

enum AppTab: CaseIterable {
    case home, breathe, decide, act, stats

    var title: String {
        switch self {
        case .home:    return "Home"
        case .breathe: return "Breathe"
        case .decide:  return "Decide"
        case .act:     return "Act"
        case .stats:   return "Stats"
        }
    }

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .breathe: return "wind"
        case .decide:  return "flame"
        case .act:     return "checkmark.square"
        case .stats:   return "chart.bar"
        }
    }
}

// MARK: - ViewModel

@Observable
final class TabBarViewModel {
    var selectedTab: AppTab = .home
}

// MARK: - Tab Item View

struct TabItemView: View {
    let tab: AppTab
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.orange : Color(white: 0.5))

                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.orange : Color(white: 0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.orange.opacity(0.15))
                        .padding(.horizontal, 4)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

// MARK: - TabBar View

struct TabBarView: View {
    @Bindable var viewModel: TabBarViewModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabItemView(
                    tab: tab,
                    isSelected: viewModel.selectedTab == tab,
                    onTap: { viewModel.selectedTab = tab }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .background(Color(white: 0.07))
    }
}

// MARK: - Root Content View (Usage Example)

struct ContentView: View {
    @State private var viewModel = TabBarViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch viewModel.selectedTab {
                case .home:    HomeView()
                case .breathe: BreatheView()
                case .decide:  DecideView()
                case .act:     ActView()
                case .stats:   StatView()
                }
            }
            .padding(.top, 55.fitH)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TabBarView(viewModel: viewModel)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.black)
    }
}

// MARK: - Placeholder screens

struct HomePageView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Home")
                .foregroundStyle(.white)
                .font(.largeTitle.bold())
        }
    }
}

struct PlaceholderView: View {
    let title: String
    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .foregroundStyle(.white)
                .font(.largeTitle.bold())
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
