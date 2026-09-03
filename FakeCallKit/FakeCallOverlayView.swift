import SwiftUI

// вспомогательное превью экрана звонка для тестирования
struct FakeCallOverlayView: View {
    @ObservedObject var callManager = CallManager.shared

    var callerName: String {
        callManager.currentScript?.callerName ?? "Абонент"
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("сотовый вызов")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))

                Text(callerName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .preferredColorScheme(.dark)
    }
}
