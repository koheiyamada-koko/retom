import SwiftUI

struct PhotoDetailView: View {
    let photo: PhotoItem
    
    var body: some View {
        VStack {
            if let uiImage = loadImage(photo: photo) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            } else {
                ProgressView()
            }
        }
        .navigationTitle("写真")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// Documents から画像を読み込む
    private func loadImage(photo: PhotoItem) -> UIImage? {
        let url = photo.imageDataURL
        guard let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data) else {
            return nil
        }
        return uiImage
    }
}

