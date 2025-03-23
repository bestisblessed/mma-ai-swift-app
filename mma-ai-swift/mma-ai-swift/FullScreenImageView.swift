import SwiftUI

struct FullScreenImageView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .edgesIgnoringSafeArea(.all)
    }
} 
