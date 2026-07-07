import SwiftData
import SwiftUI

// MARK: - MODIRecordImage

struct MODIRecordImage: View {

    let record: MODIRecord
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
            if let uiImage = UIImage(data: record.imageData) {
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

#Preview {
    let (_, repository) = MODIPreviewData.makeRepository(withSampleData: true)
    return MODIRecordImage(record: repository.fetchAllRecords()[0])
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
}
