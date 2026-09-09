import SwiftUI
import UIKit

@MainActor
private final class ProfileCropController {
    weak var cropView: ProfileCropScrollView?

    func croppedJPEG() -> Data? {
        cropView?.croppedJPEG()
    }
}

private final class ProfileCropScrollView: UIScrollView,
    UIScrollViewDelegate {

    private let sourceImage: UIImage
    private let imageView: UIImageView
    private var didConfigureZoom = false

    init(image: UIImage) {
        sourceImage = image
        imageView = UIImageView(image: image)
        super.init(frame: .zero)

        delegate = self
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = .fast
        backgroundColor = .black

        imageView.frame = CGRect(origin: .zero, size: image.size)
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        contentSize = image.size
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !didConfigureZoom,
              bounds.width > 0,
              bounds.height > 0,
              sourceImage.size.width > 0,
              sourceImage.size.height > 0
        else { return }

        let fillScale = max(
            bounds.width / sourceImage.size.width,
            bounds.height / sourceImage.size.height
        )
        minimumZoomScale = fillScale
        maximumZoomScale = max(fillScale * 5, fillScale)
        zoomScale = fillScale
        centerImage()
        didConfigureZoom = true
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }

    private func centerImage() {
        let horizontalInset = max(
            0,
            (bounds.width - contentSize.width) / 2
        )
        let verticalInset = max(
            0,
            (bounds.height - contentSize.height) / 2
        )
        contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }

    func croppedJPEG() -> Data? {
        let cropRect = convert(bounds, to: imageView)
            .intersection(imageView.bounds)
        guard !cropRect.isEmpty else { return nil }

        let outputSize = CGSize(width: 1_024, height: 1_024)
        let horizontalScale = outputSize.width / cropRect.width
        let verticalScale = outputSize.height / cropRect.height
        let renderer = UIGraphicsImageRenderer(size: outputSize)
        let image = renderer.image { _ in
            sourceImage.draw(
                in: CGRect(
                    x: -cropRect.minX * horizontalScale,
                    y: -cropRect.minY * verticalScale,
                    width: sourceImage.size.width * horizontalScale,
                    height: sourceImage.size.height * verticalScale
                )
            )
        }

        return image.jpegData(compressionQuality: 0.82)
    }
}

private struct ProfileCropRepresentable: UIViewRepresentable {
    let image: UIImage
    let controller: ProfileCropController

    func makeUIView(context: Context) -> ProfileCropScrollView {
        let view = ProfileCropScrollView(image: image)
        controller.cropView = view
        return view
    }

    func updateUIView(
        _ uiView: ProfileCropScrollView,
        context: Context
    ) {}
}





struct ProfileImageCropView: View {
    let image: UIImage
    let onUsePhoto: (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var controller = ProfileCropController()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Move and zoom the photo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProfileCropRepresentable(
                    image: image,
                    controller: controller
                )
                .aspectRatio(1, contentMode: .fit)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.8), lineWidth: 3)
                        .allowsHitTesting(false)
                }
                .shadow(color: .black.opacity(0.18), radius: 18, y: 8)

                Text("This is how your profile photo will appear.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(22)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Adjust Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Use Photo") {
                        guard let data = controller.croppedJPEG() else {
                            HapticFeedback.validationError()
                            return
                        }
                        onUsePhoto(data)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview("Profile Image Crop") {
    ProfileImageCropView(
        image: UIImage(systemName: "person.crop.square.fill")!
    ) { _ in }
}
