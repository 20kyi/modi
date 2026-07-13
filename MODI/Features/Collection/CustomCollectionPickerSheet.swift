import SwiftData
import SwiftUI

// MARK: - CustomCollectionPickerAction

enum CustomCollectionPickerAction: Identifiable {
    case edit
    case delete

    var id: Self { self }

    var navigationTitle: String {
        switch self {
        case .edit: "컬렉션 수정"
        case .delete: "컬렉션 삭제"
        }
    }

    var message: String {
        switch self {
        case .edit: "설정할 컬렉션을 골라주세요."
        case .delete: "삭제할 컬렉션을 골라주세요. 사진도 함께 지워져요."
        }
    }
}

// MARK: - CustomCollectionPickerSheet

struct CustomCollectionPickerSheet: View {

    let action: CustomCollectionPickerAction
    let collections: [MODICollection]
    let photoCount: (UUID) -> Int
    var onSelect: (MODICollection) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text(action.message)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.Text.secondary)

                    VStack(spacing: AppSpacing.sm) {
                        ForEach(collections, id: \.id) { collection in
                            Button {
                                onSelect(collection)
                                dismiss()
                            } label: {
                                collectionRow(collection)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .appScreenPadding()
                .padding(.vertical, AppSpacing.sm)
            }
            .appScreenBackground()
            .navigationTitle(action.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.Text.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func collectionRow(_ collection: MODICollection) -> some View {
        let count = photoCount(collection.id)

        return HStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(collection.themeColor)
                .frame(width: 48, height: 48)
                .overlay {
                    Text(collection.emoji)
                        .font(.system(size: 24))
                }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(collection.title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.primary)

                Text(collection.missionPrompt)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if count > 0 {
                Text("\(count)")
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.Text.tertiary)
        }
        .appCardStyle()
    }
}

// MARK: - Preview

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let schema = Schema([MODIRecord.self, MODICollection.self])
    let container = try! ModelContainer(for: schema, configurations: configuration)
    let collectionRepository = CollectionPreviewData.makeRepository(
        modelContext: container.mainContext,
        withSampleData: true
    )

    return Color.clear
        .sheet(isPresented: .constant(true)) {
            CustomCollectionPickerSheet(
                action: .edit,
                collections: collectionRepository.customCollections,
                photoCount: { collectionRepository.photoCount(for: $0) },
                onSelect: { _ in }
            )
        }
        .modelContainer(container)
}
