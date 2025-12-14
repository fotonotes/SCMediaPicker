//
//  PHAsset+ImageData.swift
//  SCMediaPicker
//
//  Created by Glenn Posadas on 12/14/24.
//

import Photos
import UIKit
import UniformTypeIdentifiers

public extension PHAsset {

    /// Requests image data with EXIF metadata preserved
    /// - Parameters:
    ///   - completionHandler: Called with the image data, UTI, orientation, and metadata (including EXIF)
    func requestImageDataPreservingEXIF(completionHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable: Any]?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestImageDataAndOrientation(for: self, options: options) { data, uti, orientation, info in
            // Get the metadata including EXIF
            let uiOrientation = orientation.toUIImageOrientation()

            if let url = info?["PHImageFileURLKey"] as? URL {
                if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
                    let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any]
                    completionHandler(data, uti, uiOrientation, metadata)
                    return
                }
            }

            // Fallback: try to get metadata from the data itself
            if let data = data,
               let imageSource = CGImageSourceCreateWithData(data as CFData, nil) {
                let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any]
                completionHandler(data, uti, uiOrientation, metadata)
            } else {
                completionHandler(data, uti, uiOrientation, nil)
            }
        }
    }

    /// Converts PHAsset image data to UIImage with EXIF metadata preserved in a new Data object
    /// - Parameters:
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0). Default is 0.9
    ///   - completionHandler: Called with image data that includes EXIF metadata
    func exportImageDataWithEXIF(compressionQuality: CGFloat = 0.9, completionHandler: @escaping (Data?) -> Void) {
        requestImageDataPreservingEXIF { data, uti, orientation, metadata in
            guard let data = data else {
                completionHandler(nil)
                return
            }

            // Create image from data
            guard let image = UIImage(data: data),
                  let imageData = image.jpegData(compressionQuality: compressionQuality) else {
                completionHandler(nil)
                return
            }

            // If we have metadata, write it back to the new JPEG data
            if let metadata = metadata {
                guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
                      let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                    completionHandler(imageData)
                    return
                }

                let mutableData = NSMutableData()
                guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
                    completionHandler(imageData)
                    return
                }

                CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)

                if CGImageDestinationFinalize(destination) {
                    completionHandler(mutableData as Data)
                } else {
                    completionHandler(imageData)
                }
            } else {
                completionHandler(imageData)
            }
        }
    }
}

private extension CGImagePropertyOrientation {
    func toUIImageOrientation() -> UIImage.Orientation {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        }
    }
}
