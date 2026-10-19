import SwiftUI

/// Local admission states deliberately show no analysis percentage.
struct LocalUploadProgressCard: View {
    let state: PendingUploadState
    let errorMessage: String?
    var needsVideo = false

    private var title: String {
        switch state {
        case .pending: return AppTextExamProgress.uploadWaitingTitle
        case .uploading: return AppTextExam.uploadQueueUploading
        case .failed: return AppTextExamProgress.uploadNeedsAttentionTitle
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(AppTypography.s4_1)
                .foregroundStyle(AppColors.slate900)
                .frame(maxWidth: .infinity, alignment: .leading)

            if state == .uploading {
                ProgressView()
                    .controlSize(.large)
                    .tint(AppColors.purple500)
                    .accessibilityLabel(title)
            } else {
                Image(systemName: state == .failed ? AppIcon.warning : AppIcon.cloudArrowUp)
                    .font(.system(size: 48))
                    .foregroundStyle(state == .failed ? AppColors.orange500 : AppColors.purple500)
                    .accessibilityHidden(true)
            }

            Text(needsVideo ? AppTextExam.uploadQueueMissingFile : (state == .failed ? AppTextExamProgress.uploadRetryHint : AppTextExamProgress.uploadSavedHint))
                .font(AppTypography.p2)
                .foregroundStyle(AppColors.slate600)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if state == .failed, !needsVideo, let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.slate600)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(state == .failed ? AppColors.orange50 : AppColors.purple50)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("Saved offline") {
    LocalUploadProgressCard(state: .pending, errorMessage: nil).padding()
}

#Preview("Sending video") {
    LocalUploadProgressCard(state: .uploading, errorMessage: nil).padding()
}

#Preview("Upload needs attention") {
    LocalUploadProgressCard(state: .failed, errorMessage: AppTextExam.uploadQueueMaxRetries).padding()
}
