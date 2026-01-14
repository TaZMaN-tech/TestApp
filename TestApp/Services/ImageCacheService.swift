//
//  ImageCacheService.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 2026-01-14.
//

import UIKit

/// Service for caching downloaded images in memory and disk
final class ImageCacheService {

    static let shared = ImageCacheService()

    // MARK: - Properties

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    // MARK: - Initialization

    private init() {
        // Setup memory cache
        memoryCache.countLimit = 100 // Maximum 100 images in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB

        // Setup disk cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache", isDirectory: true)

        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public Methods

    /// Load image from URL with caching
    /// - Parameter url: Image URL
    /// - Returns: UIImage if successfully loaded or cached
    func loadImage(from url: URL) async throws -> UIImage {
        let cacheKey = url.absoluteString as NSString

        // 1. Check memory cache first
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }

        // 2. Check disk cache
        if let diskImage = loadFromDisk(url: url) {
            // Save to memory cache for faster access next time
            memoryCache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }

        // 3. Download from network
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let image = UIImage(data: data) else {
            throw ImageCacheError.invalidImageData
        }

        // 4. Save to both caches
        memoryCache.setObject(image, forKey: cacheKey)
        saveToDisk(image: image, url: url)

        return image
    }

    /// Clear all cached images
    func clearCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Clear memory cache only (keeps disk cache)
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    // MARK: - Private Methods

    private func cacheFilePath(for url: URL) -> URL {
        let fileName = url.absoluteString
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        return cacheDirectory.appendingPathComponent(fileName)
    }

    private func loadFromDisk(url: URL) -> UIImage? {
        let filePath = cacheFilePath(for: url)
        guard let data = try? Data(contentsOf: filePath),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    private func saveToDisk(image: UIImage, url: URL) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let filePath = cacheFilePath(for: url)
        try? data.write(to: filePath)
    }
}

// MARK: - Errors

enum ImageCacheError: Error {
    case invalidImageData
    case downloadFailed
}

// MARK: - UIImageView Extension

extension UIImageView {

    /// Load and set image from URL with caching
    /// - Parameters:
    ///   - url: Image URL
    ///   - placeholder: Optional placeholder image while loading
    func setImage(from url: URL?, placeholder: UIImage? = nil) {
        // Set placeholder immediately
        self.image = placeholder

        guard let url = url else { return }

        Task { @MainActor in
            do {
                let image = try await ImageCacheService.shared.loadImage(from: url)
                self.image = image
            } catch {
                print("❌ Failed to load image: \(error)")
            }
        }
    }

    /// Convenience method for loading from URL string
    func setImage(from urlString: String?, placeholder: UIImage? = nil) {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            self.image = placeholder
            return
        }
        setImage(from: url, placeholder: placeholder)
    }
}
