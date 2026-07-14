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

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: AppSpacing.sm),
        count: 3
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text(action.message)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.Text.secondary)

                    LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                        ForEach(collections, id: \.id) { collection in
                            Button {
                                onSelect(collection)
                                dismiss()
                            } label: {
                                collectionGridItem(collection)
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

    private func collectionGridItem(_ collection: MODICollection) -> some View {
        let count = photoCount(collection.id)

        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColor.emojiBackground(from: collection.themeColorHex))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Text(collection.emoji)
                        .font(.system(size: 28))
                }
                .overlay(alignment: .topTrailing) {
                    if count > 0 {
                        Text("\(count)")
                            .font(AppFont.caption2)
                            .foregroundStyle(AppColor.Text.onAccent)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, 2)
                            .background(AppColor.Accent.primary, in: Capsule())
                            .padding(AppSpacing.xs)
                    }
                }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(collection.title)
                    .font(AppFont.caption1)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)

                Text(collection.missionPrompt)
                    .font(AppFont.caption2)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(padding: AppSpacing.sm)
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
