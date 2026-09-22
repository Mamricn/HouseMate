import SwiftUI
import PhotosUI

@MainActor
@Observable
final class ProfileSettingsViewModel {

    private(set) var user: UserModel
    let actionState = AsyncActionState()

    private let interactor: CoreInteractor

    init(user: UserModel, interactor: CoreInteractor) {
        self.user = user
        self.interactor = interactor
    }

    func uploadImage(data: Data) async -> String? {
        interactor.trackEvent(Event.uploadImageStart)
        do {
            var uploadedURL: String?
            try await actionState.run {
                uploadedURL = try await interactor.uploadProfileImage(data: data, for: user)
            }
            guard let uploadedURL else { return nil }
            user.profileImageUrl = uploadedURL
            interactor.trackEvent(Event.uploadImageSuccess(imageURL: uploadedURL))
            return uploadedURL
        } catch {
            interactor.trackEvent(Event.uploadImageFail(error: error))
            return nil
        }
    }

    func removeImage() async -> Bool {
        guard user.profileImageUrl != nil else { return false }

        interactor.trackEvent(Event.removeImageStart)

        do {
            try await actionState.run { try await interactor.removeProfileImage(for: user) }
            user.profileImageUrl = nil
            interactor.trackEvent(Event.removeImageSuccess)
            return true
        } catch {
            interactor.trackEvent(Event.removeImageFail(error: error))
            return false
        }
    }

    enum Event: LoggableEvent {
        case uploadImageStart
        case uploadImageSuccess(imageURL: String)
        case uploadImageFail(error: Error)
        case removeImageStart
        case removeImageSuccess
        case removeImageFail(error: Error)

        var eventName: String {
            switch self {
            case .uploadImageStart: "ProfileSettingsView_UploadImage_Start"
            case .uploadImageSuccess: "ProfileSettingsView_UploadImage_Success"
            case .uploadImageFail: "ProfileSettingsView_UploadImage_Fail"
            case .removeImageStart: "ProfileSettingsView_RemoveImage_Start"
            case .removeImageSuccess: "ProfileSettingsView_RemoveImage_Success"
            case .removeImageFail: "ProfileSettingsView_RemoveImage_Fail"
            }
        }

        var parameters: [String: Any]? {
            switch self {
            case .uploadImageSuccess(let imageURL): ["profile_image_url": imageURL]
            case .uploadImageFail(let error), .removeImageFail(let error): error.eventParameters
            default: nil
            }
        }

        var type: LogType {
            switch self {
            case .uploadImageFail, .removeImageFail: .severe
            default: .analytic
            }
        }
    }
}

struct ProfileSettingsView: View {

    let viewModel: ProfileSettingsViewModel
    var onProfileImageChanged: (String?) -> Void = { _ in }

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageToCrop: UIImage?
    @State private var toast: AppToast?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .blue.opacity(0.15),
                    .purple.opacity(0.10),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                profileCard
                actionsCard
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
        }
        .navigationTitle("Profile Photo")
        .navigationBarTitleDisplayMode(.inline)
        .screenAppearAnalytics(name: "ProfileSettingsView")
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            prepareForCropping(item)
        }
        .sheet(
            isPresented: Binding(
                get: { imageToCrop != nil },
                set: { if !$0 { imageToCrop = nil } }
            )
        ) {
            if let imageToCrop {
                ProfileImageCropView(image: imageToCrop) { data in
                    upload(data)
                }
            }
        }
        .alert(
            "Unable to update photo",
            isPresented: errorBinding
        ) {
            Button("OK") {
                viewModel.actionState.clearError()
            }
        } message: {
            Text(
                viewModel.actionState.errorMessage
                    ?? "Please try again."
            )
        }
        .overlay(alignment: .top) {
            if let toast {
                AppToastView(toast: toast)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
    }

    private var profileCard: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                CachedProfileImage(
                    urlString: viewModel.user.profileImageUrl,
                    displayName: viewModel.user.name ?? "Housemate",
                    size: 132
                )
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.7), lineWidth: 3)
                }
                .shadow(color: .black.opacity(0.12), radius: 14, y: 7)

                if viewModel.actionState.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 38, height: 38)
                        .background(.blue, in: Circle())
                } else {
                    Image(systemName: "camera.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.blue, in: Circle())
                }
            }

            Text(viewModel.user.name ?? "Housemate")
                .font(.title2.bold())

            Text("Images are resized and compressed before upload.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(cardBackground)
    }

    private var actionsCard: some View {
        let photoButtonTitle = viewModel.user.profileImageUrl == nil
            ? "Choose Photo"
            : "Change Photo"

        return VStack(spacing: 12) {
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(
                    photoButtonTitle,
                    systemImage: "photo.on.rectangle"
                )
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(.blue, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.actionState.isLoading)

            if viewModel.user.profileImageUrl != nil {
                Button(role: .destructive) {
                    removePhoto()
                } label: {
                    Text("Remove Photo")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.actionState.isLoading)
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.45), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 14, y: 7)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.actionState.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.actionState.clearError()
                }
            }
        )
    }

    private func prepareForCropping(_ item: PhotosPickerItem) {
        Task {
            defer { selectedPhoto = nil }

            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                HapticFeedback.validationError()
                return
            }

            imageToCrop = image
        }
    }

    private func upload(_ data: Data) {
        Task {
            guard let url = await viewModel.uploadImage(data: data) else {
                return
            }

            onProfileImageChanged(url)
            showToast("Profile photo updated")
        }
    }

    private func removePhoto() {
        Task {
            guard await viewModel.removeImage() else { return }
            onProfileImageChanged(nil)
            showToast("Profile photo removed")
        }
    }

    private func showToast(_ message: String) {
        withAnimation(.smooth) {
            toast = AppToast(
                message: message,
                systemImage: "person.crop.circle.badge.checkmark",
                color: .green
            )
        }

        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.smooth) { toast = nil }
        }
    }
}

#Preview("Profile Settings") {
    let container = DependencyContainer.make(environment: .mock)
    let interactor = CoreInteractor(container: container)

    NavigationStack {
        ProfileSettingsView(
            viewModel: ProfileSettingsViewModel(
                user: .mock,
                interactor: interactor
            )
        )
    }
}
