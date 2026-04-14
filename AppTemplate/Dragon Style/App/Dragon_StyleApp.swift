import SwiftUI
import SwiftData

struct Dragon_StyleApp: View {
    var body: some View {
        LoadingScreen()
            .preferredColorScheme(.dark)
            .modelContainer(for: [
                UserModel.self,
                BreathingSession.self,
                DecisionModel.self,
                ActionModel.self,
            ])
    }
}
