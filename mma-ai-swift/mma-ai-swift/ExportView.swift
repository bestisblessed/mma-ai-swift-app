import SwiftUI
import UIKit
import PDFKit

struct ExportView: View {
    let text: String
    let images: [Data]
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedFormat: ExportFormat = .text
    @State private var showingFormatPicker = false
    
    enum ExportFormat: String, CaseIterable {
        case text = "Text"
        case pdf = "PDF"
        case html = "HTML"
        case combinedImage = "Combined Image"
    }
    
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
                    Button(action: {
                        showingFormatPicker = true
                    }) {
                        HStack {
                            Text("Export Format: \(selectedFormat.rawValue)")
                            Image(systemName: "chevron.down")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.cardBackground)
                        .foregroundColor(AppTheme.textPrimary)
                        .cornerRadius(10)
                    }
                    
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
            .actionSheet(isPresented: $showingFormatPicker) {
                ActionSheet(
                    title: Text("Select Export Format"),
                    buttons: ExportFormat.allCases.map { format in
                        .default(Text(format.rawValue)) {
                            selectedFormat = format
                        }
                    } + [.cancel()]
                )
            }
        }
    }
    
    private func shareContent() {
        var activityItems: [Any] = []
        
        switch selectedFormat {
        case .text:
            activityItems = [text] + images.compactMap { UIImage(data: $0) }
            
        case .pdf:
            if let pdfData = createPDF() {
                activityItems = [pdfData]
            }
            
        case .html:
            if let htmlData = createHTML() {
                activityItems = [htmlData]
            }
            
        case .combinedImage:
            if let combinedImage = createCombinedImage() {
                activityItems = [combinedImage]
            }
        }
        
        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func createPDF() -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "MMA AI",
            kCGPDFContextAuthor: "MMA AI App"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth: CGFloat = 8.5 * 72.0
        let pageHeight: CGFloat = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Draw text
            let textAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)
            ]
            text.draw(at: CGPoint(x: 50, y: 50), withAttributes: textAttributes)
            
            // Draw images
            var yOffset: CGFloat = 200
            for imageData in images {
                if let image = UIImage(data: imageData) {
                    let imageRect = CGRect(x: 50, y: yOffset, width: pageWidth - 100, height: 200)
                    image.draw(in: imageRect)
                    yOffset += 220
                }
            }
        }
        
        return data
    }
    
    private func createHTML() -> Data? {
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>MMA AI Conversation</title>
            <style>
                body { font-family: -apple-system, sans-serif; padding: 20px; }
                .message { margin-bottom: 20px; }
                .image { max-width: 100%; margin: 10px 0; }
            </style>
        </head>
        <body>
            <h1>MMA AI Conversation Export</h1>
            <p>Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))</p>
        """
        
        // Add messages
        let messages = text.components(separatedBy: "\n\n")
        for message in messages {
            html += "<div class='message'>\(message)</div>"
        }
        
        // Add images
        for imageData in images {
            if let base64String = String(data: imageData, encoding: .utf8) {
                html += "<img class='image' src='data:image/png;base64,\(base64String)' />"
            }
        }
        
        html += "</body></html>"
        return html.data(using: .utf8)
    }
    
    private func createCombinedImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 1600))
        
        return renderer.image { context in
            // Draw background
            UIColor.systemBackground.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1200, height: 1600))
            
            // Draw text
            let textAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                NSAttributedString.Key.foregroundColor: UIColor.label
            ]
            text.draw(at: CGPoint(x: 40, y: 40), withAttributes: textAttributes)
            
            // Draw images
            var yOffset: CGFloat = 400
            for imageData in images {
                if let image = UIImage(data: imageData) {
                    let imageRect = CGRect(x: 40, y: yOffset, width: 1120, height: 300)
                    image.draw(in: imageRect)
                    yOffset += 320
                }
            }
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

// import SwiftUI
// import UIKit

// struct ExportView: View {
//     let text: String
//     let images: [Data]
//     @Environment(\.presentationMode) var presentationMode
    
//     var body: some View {
//         NavigationView {
//             VStack {
//                 ScrollView {
//                     VStack(alignment: .leading, spacing: 16) {
//                         Text(text)
//                             .font(.body)
                        
//                         if !images.isEmpty {
//                             Text("\nImages:")
//                                 .font(.headline)
//                                 .padding(.top)
                            
//                             ForEach(images.indices, id: \.self) { index in
//                                 if let uiImage = UIImage(data: images[index]) {
//                                     Image(uiImage: uiImage)
//                                         .resizable()
//                                         .scaledToFit()
//                                         .frame(maxWidth: 300)
//                                         .cornerRadius(10)
//                                 }
//                             }
//                         }
//                     }
//                     .padding()
//                 }
                
//                 Button("Share") {
//                     var activityItems: [Any] = [text]
                    
//                     // Add images to activity items
//                     for imageData in images {
//                         if let uiImage = UIImage(data: imageData) {
//                             activityItems.append(uiImage)
//                         }
//                     }
                    
//                     let activityVC = UIActivityViewController(
//                         activityItems: activityItems,
//                         applicationActivities: nil
//                     )
                    
//                     // Present the view controller
//                     if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//                        let rootViewController = windowScene.windows.first?.rootViewController {
//                         rootViewController.present(activityVC, animated: true)
//                     }
//                 }
//                 .padding()
//                 .frame(maxWidth: .infinity)
//                 .background(AppTheme.accent)
//                 .foregroundColor(.white)
//                 .cornerRadius(10)
//                 .padding()
//             }
//             .navigationTitle("Export Conversation")
//             .navigationBarItems(trailing: Button("Done") {
//                 presentationMode.wrappedValue.dismiss()
//             })
//         }
//     }
// }

// // Changed from struct to class since UIActivityItemProvider is a class
// class TextActivityItem: UIActivityItemProvider {
//     var text: String
    
//     init(_ text: String) {
//         self.text = text
//         super.init(placeholderItem: text)
//     }
    
//     override var item: Any {
//         return text
//     }
// }

// #Preview {
//     ExportView(text: "Sample conversation text for preview", images: [])
// } 