import SwiftUI

// MARK: - EditorFrameMetadata

/// 프레임에 표시할 메타데이터 구조.
struct EditorFrameMetadata: Equatable {
    var showDate: Bool = true
    var showConceptName: Bool = true
    var date: Date = .now
    var conceptTitle: String?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

// MARK: - FramePickerView

/// 하단 툴바에 표시되는 프레임 선택 패널.
struct FramePickerView: View {

    @Binding var selectedFrame: EditorFrameStyle
    let metadata: EditorFrameMetadata
    let themeColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            frameStylePicker

            frameMetadataPreview
        }
    }

    private var frameStylePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(EditorFrameStyle.allCases) { frame in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            selectedFrame = frame
                        }
                    } label: {
                        VStack(spacing: AppSpacing.xs) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                    .fill(AppColor.Background.tertiary)
                                    .frame(width: 52, height: 52)

                                framePreview(for: frame)
                            }
                            .overlay {
                                if selectedFrame == frame {
                                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                        .strokeBorder(AppColor.Accent.highlight, lineWidth: 2)
                                }
                            }

                            Text(frame.displayName)
                                .font(AppFont.caption2)
                                .foregroundStyle(
                                    selectedFrame == frame
                                        ? AppColor.Accent.highlight
                                        : AppColor.Text.secondary
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: 64)
                }
            }
        }
    }

    private var frameMetadataPreview: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("프레임 정보")
                .font(AppFont.caption1)
                .foregroundStyle(AppColor.Text.tertiary)

            HStack(spacing: AppSpacing.md) {
                if metadata.showDate {
                    metadataChip(
                        icon: "calendar",
                        label: metadata.formattedDate
                    )
                }

                if metadata.showConceptName, let title = metadata.conceptTitle {
                    metadataChip(
                        icon: "sparkles",
                        label: title
                    )
                }

                if !metadata.showDate && (metadata.conceptTitle == nil || !metadata.showConceptName) {
                    Text("컨셉을 연결하면 이름이 표시돼요")
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.tertiary)
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppColor.Background.secondary,
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
        )
    }

    private func metadataChip(icon: String, label: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(AppFont.caption1)
                .lineLimit(1)
        }
        .foregroundStyle(AppColor.Text.secondary)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            themeColor.opacity(0.25),
            in: Capsule()
        )
    }

    @ViewBuilder
    private func framePreview(for frame: EditorFrameStyle) -> some View {
        RoundedRectangle(cornerRadius: frame == .rounded ? 6 : 3, style: .continuous)
            .fill(AppColor.Surface.muted)
            .frame(width: 36, height: 36)
            .padding(frame == .none ? 0 : 4)
            .background {
                if frame != .none {
                    RoundedRectangle(cornerRadius: frame == .rounded ? 8 : 5, style: .continuous)
                        .fill(frame.borderColor(themeColor: themeColor))
                }
            }
    }
}

#Preview {
    FramePickerView(
        selectedFrame: .constant(.accent),
        metadata: EditorFrameMetadata(conceptTitle: "Cloud Hunter"),
        themeColor: Color(hex: "E4ECF4")
    )
    .padding()
    .appScreenBackground()
}
