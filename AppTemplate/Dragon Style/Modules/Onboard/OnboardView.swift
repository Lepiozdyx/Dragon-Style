import SwiftUI
import Observation

@Observable
class OnboardViewModel {
    var state: OnboardState = .first

    func next() {
        switch state {
        case .first:
            state = .second
        case .second:
            state = .third
        case .third:
            break
        }
    }

    func reset() {
        state = .first
    }
}

struct OnboardView: View {
    var onEnd: () -> Void
    @State private var viewModel = OnboardViewModel()
    var isSE: Bool { UIScreen.isIphoneSEClassic }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { onEnd() }) {
                    Text("Skip")
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 20.fitW)
            .padding(.top, 55.fitH)

            if isSE {
                Image(viewModel.state.rawValue)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .padding(.top)
            } else {
                Image(viewModel.state.rawValue)
                    .resizable()
                    .scaledToFit()
            }

            Button(action: {
                switch viewModel.state {
                case .first:
                    viewModel.state = .second
                case .second:
                    viewModel.state = .third
                case .third:
                    onEnd()
                }
            }) {
                switch viewModel.state {
                case .first:
                    Image(.enterBtn)
                        .resizable().scaledToFit().padding()
                case .second:
                    Image(.continueBtn)
                        .resizable().scaledToFit().padding()
                case .third:
                    Image(.startBtn)
                        .resizable().scaledToFit().padding()
                }
            }
            .padding(.bottom, 20.fitH)
        }
    }
}

enum OnboardState: String, CaseIterable {
    case first, second, third
}
