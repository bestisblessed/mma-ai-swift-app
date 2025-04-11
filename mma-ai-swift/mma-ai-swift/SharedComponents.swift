import SwiftUI

struct LoadingDots: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 6, height: 6)
                    .scaleEffect(index < dotCount ? 1.0 : 0.5)
                    .opacity(index < dotCount ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.3), value: dotCount)
            }
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}

struct FullScreenImageView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .edgesIgnoringSafeArea(.all)
            .contextMenu {
                Button(action: {
                    shareImage(image)
                }) {
                    Text("Share")
                    Image(systemName: "square.and.arrow.up")
                }
            }
    }
    
    private func shareImage(_ image: UIImage) {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    VStack {
        LoadingDots()
    }
    .padding()
    .background(AppTheme.background)
} 