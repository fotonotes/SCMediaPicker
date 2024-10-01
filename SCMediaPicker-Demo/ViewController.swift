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
        
        dismiss(animated: true, completion: nil)
    }

    func sc_imagePickerControllerDidCancel(_ imagePickerController: SCImagePickerController) {
        print("Canceled.")
        
        dismiss(animated: true, completion: nil)
    }
}
