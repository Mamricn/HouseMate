import SwiftUI
import UIKit

@MainActor
final class ProfileImageCache {

    static let shared = ProfileImageCache()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let session: URLSession
    private var inFlightTasks: [URL: Task<UIImage, Error>] = [:]

    private init() {
        let diskCache = URLCache(
            memoryCapacity: 20 * 1_024 * 1_024,
            diskCapacity: 100 * 1_024 * 1_024,
            diskPath: "housemate-profile-images"
        )
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = diskCache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
        memoryCache.countLimit = 100
    }

    func image(for url: URL) async throws -> UIImage {
        if let image = memoryCache.object(forKey: url as NSURL) {
            return image
        }

        if let task = inFlightTasks[url] {
            return try await task.value
        }

        let task = Task<UIImage, Error> {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let image = UIImage(data: data)
            else {
                throw ProfileImageError.invalidImage
            }

            return image
        }

        inFlightTasks[url] = task

        do {
            let image = try await task.value
            memoryCache.setObject(image, forKey: url as NSURL)
            inFlightTasks[url] = nil
            return image
        } catch {
            inFlightTasks[url] = nil
            throw error
        }
    }

    func removeImage(for url: URL) {
        memoryCache.removeObject(forKey: url as NSURL)
        session.configuration.urlCache?.removeCachedResponse(
            for: URLRequest(url: url)
        )
    }
}

@MainActor
@Observable
private final class CachedProfileImageLoader {
    var image: UIImage?

    func load(url: URL?) async {
        image = nil
        guard let url else { return }
        image = try? await ProfileImageCache.shared.image(for: url)
    }
}

struct CachedProfileImage: View {

    let urlString: String?
    let displayName: String
    let size: CGFloat

    @State private var loader = CachedProfileImageLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: urlString) {
            await loader.load(
                url: urlString.flatMap(URL.init(string:))
            )
        }
    }

    private var fallback: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.32, weight: .bold))
                    .foregroundStyle(.white)
            }
    }

    private var initials: String {
        let characters = displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)

        return characters.isEmpty
            ? "?"
            : String(characters).uppercased()
    }
}

#Preview("Profile Image Fallback") {
    VStack(spacing: 24) {
        CachedProfileImage(
            urlString: nil,
            displayName: "Marcin Turek",
            size: 96
        )

        CachedProfileImage(
            urlString: nil,
            displayName: "Housemate",
            size: 48
        )
    }
    .padding()
}
