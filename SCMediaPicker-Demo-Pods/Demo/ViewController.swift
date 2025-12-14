//
//  ViewController.swift
//  SCMediaPicker-Demo
//
//  Created by Glenn Posadas on 10/1/24.
//

import SCMediaPicker
import UIKit
import Photos

class ViewController: UITableViewController, SCImagePickerControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let imagePickerController = SCImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.mediaType = .any
        imagePickerController.allowsMultipleSelection = (indexPath.section == 1)
        imagePickerController.showsNumberOfSelectedAssets = true

        if indexPath.section == 1 {
            switch indexPath.row {
            case 1:
                imagePickerController.minimumNumberOfSelection = 3
            case 2:
                imagePickerController.maximumNumberOfSelection = 6
            case 3:
                imagePickerController.minimumNumberOfSelection = 3
                imagePickerController.maximumNumberOfSelection = 6
            case 4:
                imagePickerController.maximumNumberOfSelection = 2
                if let lastAsset = PHAsset.fetchAssets(with: nil).lastObject {
                    imagePickerController.selectedAssets.add(lastAsset)
                }
            default:
                break
            }
        }

        present(imagePickerController, animated: true, completion: nil)
    }

    // MARK: - SCImagePickerControllerDelegate

    func sc_imagePickerController(_ imagePickerController: SCImagePickerController, didFinishPickingAssets assets: [PHAsset]) {
        print("Selected assets:")
        print(assets)

        // Example 1: Extract EXIF metadata including creation date
        print("\n=== EXIF Metadata Example ===")
        for (index, asset) in assets.enumerated() {
            print("\nAsset \(index + 1):")
            asset.requestImageDataPreservingEXIF { data, uti, orientation, metadata in
                if let metadata = metadata {
                    print("Full metadata: \(metadata)")

                    // Extract EXIF data
                    if let exif = metadata[kCGImagePropertyExifDictionary] as? [String: Any] {
                        print("EXIF Data:")
                        if let dateTimeOriginal = exif[kCGImagePropertyExifDateTimeOriginal as String] {
                            print("  Date Taken: \(dateTimeOriginal)")
                        }
                        if let dateTimeDigitized = exif[kCGImagePropertyExifDateTimeDigitized as String] {
                            print("  Date Digitized: \(dateTimeDigitized)")
                        }
                    }

                    // Extract TIFF data (contains additional date info)
                    if let tiff = metadata[kCGImagePropertyTIFFDictionary] as? [String: Any] {
                        print("TIFF Data:")
                        if let dateTime = tiff[kCGImagePropertyTIFFDateTime as String] {
                            print("  DateTime: \(dateTime)")
                        }
                    }

                    // Extract GPS data
                    if let gps = metadata[kCGImagePropertyGPSDictionary] as? [String: Any] {
                        print("GPS Data:")
                        if let latitude = gps[kCGImagePropertyGPSLatitude as String],
                           let longitude = gps[kCGImagePropertyGPSLongitude as String] {
                            print("  Location: \(latitude), \(longitude)")
                        }
                        if let timeStamp = gps[kCGImagePropertyGPSTimeStamp as String] {
                            print("  GPS Time: \(timeStamp)")
                        }
                    }
                } else {
                    print("No metadata found for asset \(index + 1)")
                }
            }
        }

        // Example 2: Export image data with EXIF preserved
        print("\n=== Export with EXIF Preserved ===")
        if let firstAsset = assets.first {
            firstAsset.exportImageDataWithEXIF(compressionQuality: 0.9) { imageData in
                if let imageData = imageData {
                    print("Exported image data size: \(imageData.count) bytes")
                    print("This data includes all EXIF metadata and can be saved to disk or uploaded")

                    // Verify EXIF is preserved in exported data
                    if let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
                       let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
                        print("EXIF preserved in exported data: \(properties.keys.contains(kCGImagePropertyExifDictionary as String))")
                    }
                } else {
                    print("Failed to export image data")
                }
            }
        }

        dismiss(animated: true, completion: nil)
    }

    func sc_imagePickerControllerDidCancel(_ imagePickerController: SCImagePickerController) {
        print("Canceled.")
        
        dismiss(animated: true, completion: nil)
    }
}
