/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An object that writes photos to the user's Photos library.
*/

import Photos
import UIKit

actor MediaLibrary {
    
    enum Error: Swift.Error {
        case unauthorized
        case saveFailed
    }
    
    /// Async stream for thumbnails of saved photos
    let thumbnails: AsyncStream<CGImage?>
    private let continuation: AsyncStream<CGImage?>.Continuation?
    
    init() {
        let (thumbnails, continuation) = AsyncStream.makeStream(of: CGImage?.self)
        self.thumbnails = thumbnails
        self.continuation = continuation
    }
    
    // MARK: - Photo Saving
    
    func save(photo: Photo) async throws {
        guard await isAuthorized else {
            throw Error.unauthorized
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                creationRequest.addResource(with: .photo, data: photo.data, options: options)
            }
            
            if let latestAsset = fetchLatestAsset() {
                await createThumbnail(for: latestAsset)
            }
        } catch {
            throw Error.saveFailed
        }
    }
    
    // MARK: - Private Helpers
    
    private var isAuthorized: Bool {
        get async {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            var authorized = status == .authorized
            
            if status == .notDetermined {
                authorized = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
            }
            
            return authorized
        }
    }
    
    private func fetchLatestAsset() -> PHAsset? {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 1
        return PHAsset.fetchAssets(with: options).firstObject
    }
    
    private func createThumbnail(for asset: PHAsset) async {
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 256, height: 256),
            contentMode: .aspectFill,
            options: nil
        ) { [weak self] image, _ in
            self?.continuation?.yield(image?.cgImage)
        }
    }
}
