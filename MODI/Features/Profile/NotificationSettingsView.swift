import SwiftUI

struct NotificationSettingsView: View {

    @Environment(NotificationManager.self) private var notificationManager
    @Environment(MissionManager.self) private var missionManager
    @Environment(\.openURL) private var openURL

    @State private var notificationTime: Date = .now
    @State private var showsPermissionAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                toggleSection
                if notificationManager.isEnabled {
                    timeSection
                }
                if notificationManager.isPermissionDenied {
                    permissionDeniedSection
                }
                previewSection
            }
            .appScreenPadding()
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .appScreenBackground()
        .navigationTitle("알림 설정")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notificationTime = notificationManager.notificationTime()
        }
        .alert("알림 권한이 필요해요", isPresented: $showsPermissionAlert) {
            Button("설정 열기") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("설정 앱에서 MODI 알림을 허용해 주세요.")
        }
    }

    // MARK: - Toggle

    private var toggleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "일일 알림")

            VStack(spacing: 0) {
                Toggle(isOn: notificationToggleBinding) {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppColor.Accent.primary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text("오늘의 Concept 알림")
                                .font(AppFont.body)
                                .foregroundStyle(AppColor.Text.primary)

                            Text("매일 새로운 발견을 잊지 않도록 알려드려요")
                                .font(AppFont.footnote)
                                .foregroundStyle(AppColor.Text.secondary)
                        }
                    }
                }
                .tint(AppColor.Accent.primary)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .frame(minHeight: AppSpacing.minTouchTarget)
            }
            .appCardStyle(padding: 0)
        }
    }

    private var notificationToggleBinding: Binding<Bool> {
        Binding(
            get: { notificationManager.isEnabled },
            set: { newValue in
                Task {
                    if newValue {
                        let granted = await notificationManager.enableNotifications(
                            missionManager: missionManager
                        )
                        if !granted {
                            showsPermissionAlert = true
                        }
                    } else {
                        notificationManager.isEnabled = false
                    }
                }
            }
        )
    }

    // MARK: - Time

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "알림 시간")

            VStack(spacing: 0) {
                DatePicker(
                    selection: $notificationTime,
                    displayedComponents: .hourAndMinute
                ) {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppColor.Accent.primary)
                            .frame(width: 28)

                        Text("알림 받을 시간")
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.Text.primary)
                    }
                }
                .tint(AppColor.Accent.primary)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .frame(minHeight: AppSpacing.minTouchTarget)
                .onChange(of: notificationTime) { _, newValue in
                    notificationManager.updateNotificationTime(from: newValue)
                }
            }
            .appCardStyle(padding: 0)
        }
    }

    // MARK: - Permission Denied

    private var permissionDeniedSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppColor.Semantic.warning)

                Text("알림이 꺼져 있어요")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)
            }

            Text("iOS 설정에서 MODI 알림을 허용하면 매일 오늘의 Concept을 받을 수 있어요.")
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("설정 열기") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .appCardStyle()
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader(title: "알림 미리보기")

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(NotificationManager.notificationTitle)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)

                Text(previewBody)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .appCardStyle()
        }
    }

    private var previewBody: String {
        if let concept = missionManager.todaysConcept {
            return NotificationManager.notificationBody(for: concept)
        }
        return "오늘은 ☁️ Cloud를 찾아보세요"
    }

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(AppFont.title3)
            .foregroundStyle(AppColor.Text.primary)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .environment(NotificationManager.mock)
    .environment(MissionManager.mock)
}
