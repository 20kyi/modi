import SwiftUI

// MARK: - MissionPhotoImage

struct MissionPhotoImage: View {

    let fileName: String?
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
            if let fileName, let uiImage = PhotoStorage.image(for: fileName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(AppColor.Accent.primary.opacity(0.5))
            }
        }
    }
}
