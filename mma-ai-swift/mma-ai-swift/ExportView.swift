import SwiftUI
import UIKit
import PDFKit

struct ExportView: View {
    let text: String
    let images: [Data]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(text)
                            .font(.body)
                        
                        if !images.isEmpty {
                            Text("\nImages:")
                                .font(.headline)
                                .padding(.top)
                            
                            ForEach(images.indices, id: \.self) { index in
                                if let uiImage = UIImage(data: images[index]) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 300)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                VStack(spacing: 12) {
                    Button("Share") {
                        shareContent()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Export Conversation")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func shareContent() {
        var activityItems: [Any] = [text] + images.compactMap { UIImage(data: $0) }
        
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            // Find the topmost view controller
            var topController = rootViewController
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            // Present the activity view controller
            topController.present(activityVC, animated: true)
        }
    }
}

// Changed from struct to class since UIActivityItemProvider is a class
class TextActivityItem: UIActivityItemProvider, @unchecked Sendable {
    var text: String
    
    init(_ text: String) {
        self.text = text
        super.init(placeholderItem: text)
    }
    
    override var item: Any {
        return text
    }
}

#Preview {
    ExportView(text: "Sample conversation text for preview", images: [])
}