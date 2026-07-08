import SwiftData
import SwiftUI

struct AddCollectionView: View {

    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(MissionManager.self) private var missionManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var emoji = "📷"
    @State private var missionPrompt = ""
    @State private var description = ""
    @State private var selectedColorHex = PhotoCollection.presetColorHexes[0]

    private let emojiOptions = ["📷", "☕️", "🍰", "🎵", "📚", "🚶", "🏠", "✨", "🎨", "🧸", "🌿", "🍜"]

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && !missionPrompt.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                headerSection
                formSection
                saveButton
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .appScreenBackground()
        .navigationTitle("컬렉션 추가")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Custom Collection")
                .font(AppFont.title2)
                .foregroundStyle(AppColor.Text.primary)

            Text("Custom Concept를 만들면, 그 Concept로 찍은 사진이 이 컬렉션에 쌓여요.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.secondary)
        }
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            formField(title: "컬렉션 이름", placeholder: "예: 커피 타임", text: $title)
            formField(title: "미션 문구", placeholder: "예: 커피를 찍으세요", text: $missionPrompt)
            formField(title: "설명 (선택)", placeholder: "이 컬렉션에 담고 싶은 순간", text: $description)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("이모지")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.Text.primary)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 6),
                    spacing: AppSpacing.sm
                ) {
                    ForEach(emojiOptions, id: \.self) { option in
                        Button {
                            emoji = option
                        } label: {
                            Text(option)
                                .font(.system(size: 24))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    emoji == option ? AppColor.Accent.soft : AppColor.Background.secondary,
                                    in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("테마 색")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.Text.primary)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 6),
                    spacing: AppSpacing.sm
                ) {
                    ForEach(PhotoCollection.presetColorHexes, id: \.self) { hex in
                        Button {
                            selectedColorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(height: 36)
                                .overlay {
                                    if selectedColorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(AppColor.Accent.primary)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .appCardStyle()
    }

    private func formField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppFont.subheadline)
                .foregroundStyle(AppColor.Text.primary)

            TextField(placeholder, text: text)
                .font(AppFont.body)
                .padding(AppSpacing.md)
                .background(AppColor.Background.secondary, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
    }

    private var saveButton: some View {
        Button("컬렉션 만들기") {
            let collection = collectionRepository.addCustomCollection(
                title: title.trimmingCharacters(in: .whitespaces),
                emoji: emoji,
                missionPrompt: missionPrompt.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces).isEmpty
                    ? missionPrompt.trimmingCharacters(in: .whitespaces)
                    : description.trimmingCharacters(in: .whitespaces),
                themeColorHex: selectedColorHex
            )
            missionManager.registerCustomConcept(collection.concept)
            dismiss()
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.5)
    }
}

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let schema = Schema([MODIRecord.self, MODICollection.self])
    let container = try! ModelContainer(for: schema, configurations: configuration)
    let collectionRepository = CollectionPreviewData.makeRepository(modelContext: container.mainContext)

    return NavigationStack {
        AddCollectionView()
    }
    .modelContainer(container)
    .environment(collectionRepository)
    .environment(MissionManager())
}
