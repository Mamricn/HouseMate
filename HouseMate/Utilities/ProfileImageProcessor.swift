import UIKit

enum ProfileImageProcessor {

    static func compressedJPEG(
        from data: Data,
        maximumDimension: CGFloat = 1_024,
        compressionQuality: CGFloat = 0.78
    ) throws -> Data {
        guard let image = UIImage(data: data) else {
            throw ProfileImageError.invalidImage
        }

        let largestDimension = max(
            image.size.width,
            image.size.height
        )
        let scale = min(1, maximumDimension / largestDimension)
        let targetSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let jpegData = resizedImage.jpegData(
            compressionQuality: compressionQuality
        ) else {
            throw ProfileImageError.invalidImage
        }

        return jpegData
    }
}
