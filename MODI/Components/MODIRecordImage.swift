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
                    .foregroundStyle(AppColor.Accent.highlight.opacity(0.5))
            }
        }
    }
}

extension View {
    /// 기록 이미지 표시 시 프레임 베이크 여부에 맞는 모서리 클립을 적용합니다.
    func modiRecordClipShape(for record: MODIRecord) -> some View {
        clipShape(RecordDisplayClipShape(record: record))
    }
}

private struct RecordDisplayClipShape: Shape {
    let record: MODIRecord

    func path(in rect: CGRect) -> Path {
        RoundedRectangle(
            cornerRadius: record.displayCornerRadius(forDisplaySize: rect.size),
            style: .continuous
        ).path(in: rect)
    }
}

#Preview {
    let (_, repository) = RecordPreviewData.makeRepository(withSampleData: true)
    return MODIRecordImage(record: repository.fetchAllRecords()[0])
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.photo, style: .continuous))
}
