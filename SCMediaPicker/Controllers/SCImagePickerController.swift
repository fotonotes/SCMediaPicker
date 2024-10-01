//
//  SCImagePickerController.swift
//  SCMediaPicker
//
//  Created by Glenn Posadas on 10/2/24.
//

import UIKit
import Photos

public protocol SCImagePickerControllerDelegate: AnyObject {
    func sc_imagePickerController(_ imagePickerController: SCImagePickerController, didFinishPickingAssets assets: [PHAsset])
    func sc_imagePickerControllerDidCancel(_ imagePickerController: SCImagePickerController)

    func sc_imagePickerController(_ imagePickerController: SCImagePickerController, shouldSelectAsset asset: PHAsset) -> Bool
    func sc_imagePickerController(_ imagePickerController: SCImagePickerController, didSelectAsset asset: PHAsset)
    func sc_imagePickerController(_ imagePickerController: SCImagePickerController, didDeselectAsset asset: PHAsset)
}

// Optional
public extension SCImagePickerControllerDelegate {
    func sc_imagePickerController(_ imagePickerController: SCImagePickerController, shouldSelectAsset asset: PHAsset) -> Bool { return true }
    func sc_imagePickerController(_ imagePickerController: SCImagePickerController, didSelectAsset asset: PHAsset) { }
    func sc_imagePickerController(_ imagePickerController: SCImagePickerController, didDeselectAsset asset: PHAsset) { }
}

public enum SCImagePickerMediaType: UInt {
    case any = 0
    case image
    case video
}

public class SCImagePickerController: UIViewController {
    
    public weak var delegate: SCImagePickerControllerDelegate?
    
    public var selectedAssets = NSMutableOrderedSet()
    
    public var assetCollectionSubtypes: [PHAssetCollectionSubtype] = [
        .smartAlbumUserLibrary,
        .albumMyPhotoStream,
        .smartAlbumPanoramas,
        .smartAlbumVideos,
        .smartAlbumBursts
    ]
    public var mediaType: SCImagePickerMediaType = .any

    public var allowsMultipleSelection = false
    public var minimumNumberOfSelection: Int = 1
    public var maximumNumberOfSelection: Int = 0

    public var prompt: String?
    public var showsNumberOfSelectedAssets = false

    public var numberOfColumnsInPortrait: Int = 4
    public var numberOfColumnsInLandscape: Int = 7

    public var shouldFilterOutVideosWithMaxNumberOfSeconds = false
    public var maxNumberOfSecondsForVideos: Int = 100

    public var albumsNavigationController: UINavigationController?
    public var assetBundle: Bundle?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUp()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }
    
    private func setUp() {
        // Get asset bundle
        assetBundle = Bundle(for: type(of: self))
        if let bundlePath = assetBundle?.path(forResource: "SCImagePicker", ofType: "bundle") {
            assetBundle = Bundle(path: bundlePath)
        }

        setUpAlbumsViewController()
        
        // Set instance
        if let albumsViewController = albumsNavigationController?.topViewController as? SCAlbumsViewController {
            albumsViewController.imagePickerController = self
        }
    }

    private func setUpAlbumsViewController() {
        // Add SCAlbumsViewController as a child
        let storyboard = UIStoryboard(name: "SCImagePicker", bundle: assetBundle)
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: "SCAlbumsNavigationController") as? UINavigationController else { return }

        addChild(navigationController)
        navigationController.view.frame = view.bounds
        view.addSubview(navigationController.view)
        navigationController.didMove(toParent: self)
        
        self.albumsNavigationController = navigationController
    }
}
