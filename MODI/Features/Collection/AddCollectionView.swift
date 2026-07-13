import SwiftData
import SwiftUI

struct AddCollectionView: View {

    private let editingCollection: MODICollection?

    @Environment(CollectionRepository.self) private var collectionRepository
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var emoji: String
    @State private var missionPrompt: String
    @State private var description: String
    @State private var selectedColorHex: String
    @State private var autoFilledTitle: String?
    @State private var autoFilledMissionPrompt: String?
    @State private var autoFilledDescription: String?

    private let emojiOptions = [
        "🩷", "❤️", "🧡", "💛", "💚", "💙",
        "💜", "🖤", "🤍", "🤎", "🩵", "🩶",
        "📷", "☕️", "🍰", "🎵", "📚", "🚶",
        "🏠", "✨", "🎨", "🧸", "🌿", "🍜"
    ]

    private var isEditing: Bool { editingCollection != nil }

    private var titleIsUserEdited: Bool {
        fieldIsUserEdited(current: title, autoFilled: autoFilledTitle)
    }

    private var missionPromptIsUserEdited: Bool {
        fieldIsUserEdited(current: missionPrompt, autoFilled: autoFilledMissionPrompt)
    }

    private var descriptionIsUserEdited: Bool {
        fieldIsUserEdited(current: description, autoFilled: autoFilledDescription)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && !missionPrompt.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(editingCollection: MODICollection? = nil) {
        self.editingCollection = editingCollection
        _title = State(initialValue: editingCollection?.title ?? "")
        _emoji = State(initialValue: editingCollection?.emoji ?? "📷")
        _missionPrompt = State(initialValue: editingCollection?.missionPrompt ?? "")
        _description = State(initialValue: editingCollection?.collectionDescription ?? "")
        _selectedColorHex = State(
            initialValue: editingCollection?.themeColorHex ?? PhotoCollection.presetColorHexes[0]
        )
        _autoFilledTitle = State(initialValue: nil)
        _autoFilledMissionPrompt = State(initialValue: nil)
        _autoFilledDescription = State(initialValue: nil)
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
        .navigationTitle(isEditing ? "컬렉션 수정" : "컬렉션 추가")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Custom Collection")
                .font(AppFont.title2)
                .foregroundStyle(AppColor.Text.primary)

            Text(
                isEditing
                    ? "컬렉션 정보를 바꿔도 기존 사진은 그대로 남아요."
                    : "Custom Concept를 만들면, 그 Concept로 찍은 사진이 이 컬렉션에 쌓여요."
            )
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
                            selectEmoji(option)
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
                                            .foregroundStyle(AppColor.Accent.highlight)
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
        Button(isEditing ? "변경 저장" : "컬렉션 만들기") {
            saveCollection()
            dismiss()
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.5)
    }

    private func fieldIsUserEdited(current: String, autoFilled: String?) -> Bool {
        if let autoFilled {
            return current != autoFilled
        }
        return !current.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func selectEmoji(_ option: String) {
        emoji = option
        guard let preset = PhotoCollection.heartCollectionPreset(for: option) else { return }

        if !titleIsUserEdited {
            autoFilledTitle = preset.title
            title = preset.title
        }
        if !missionPromptIsUserEdited {
            autoFilledMissionPrompt = preset.missionPrompt
            missionPrompt = preset.missionPrompt
        }
        if !descriptionIsUserEdited {
            autoFilledDescription = preset.description
            description = preset.description
        }
    }

    private func saveCollection() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedMissionPrompt = missionPrompt.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = description.trimmingCharacters(in: .whitespaces)
        let resolvedDescription = trimmedDescription.isEmpty ? trimmedMissionPrompt : trimmedDescription

        if let editingCollection {
            collectionRepository.updateCustomCollection(
                editingCollection,
                title: trimmedTitle,
                emoji: emoji,
                missionPrompt: trimmedMissionPrompt,
                description: resolvedDescription,
                themeColorHex: selectedColorHex,
                accessToken: authManager.accessToken
            )
        } else {
            collectionRepository.addCustomCollection(
                title: trimmedTitle,
                emoji: emoji,
                missionPrompt: trimmedMissionPrompt,
                description: resolvedDescription,
                themeColorHex: selectedColorHex,
                accessToken: authManager.accessToken
            )
        }
    }
}

#Preview("Add") {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let schema = Schema([MODIRecord.self, MODICollection.self])
    let container = try! ModelContainer(for: schema, configurations: configuration)
    let collectionRepository = CollectionPreviewData.makeRepository(modelContext: container.mainContext)

    return NavigationStack {
        AddCollectionView()
    }
    .modelContainer(container)
    .environment(collectionRepository)
}

#Preview("Edit") {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let schema = Schema([MODIRecord.self, MODICollection.self])
    let container = try! ModelContainer(for: schema, configurations: configuration)
    let collectionRepository = CollectionPreviewData.makeRepository(
        modelContext: container.mainContext,
        withSampleData: true
    )
    let collection = collectionRepository.customCollections[0]

    return NavigationStack {
        AddCollectionView(editingCollection: collection)
    }
    .modelContainer(container)
    .environment(collectionRepository)
}
