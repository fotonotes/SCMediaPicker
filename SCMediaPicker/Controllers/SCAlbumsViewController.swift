//
//  SCAlbumsViewController.swift
//  SCMediaPicker
//
//  Created by Glenn Posadas on 10/2/24.
//

import UIKit
import Photos

class SCAlbumsViewController: UITableViewController, PHPhotoLibraryChangeObserver {
    
    weak var imagePickerController: SCImagePickerController?
    private var doneButton: UIBarButtonItem!
    private var fetchResults: [PHFetchResult<PHAssetCollection>] = []
    private var assetCollections: [PHAssetCollection] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpToolbarItems()
        
        // Fetch user albums and smart albums
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        fetchResults = [smartAlbums, userAlbums]
        
        updateAssetCollections()
        
        // Register observer
        PHPhotoLibrary.shared().register(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure navigation item
        self.navigationItem.title = NSLocalizedString("albums.title", tableName: "SCImagePicker", bundle: imagePickerController?.assetBundle ?? .main, comment: "")
        self.navigationItem.prompt = imagePickerController?.prompt
        
        // Show/hide 'Done' button
        if imagePickerController?.allowsMultipleSelection == true {
            self.navigationItem.setRightBarButton(doneButton, animated: false)
        } else {
            self.navigationItem.setRightBarButton(nil, animated: false)
        }
        
        updateControlState()
        updateSelectionInfo()
    }
    
    deinit {
        // Deregister observer
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: - Storyboard
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let assetsViewController = segue.destination as? SCAssetsViewController {
            assetsViewController.imagePickerController = self.imagePickerController
            if let indexPath = tableView.indexPathForSelectedRow {
                assetsViewController.assetCollection = self.assetCollections[indexPath.row]
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func cancel(_ sender: Any) {
        imagePickerController?.delegate?.sc_imagePickerControllerDidCancel(imagePickerController!)
    }
    
    @IBAction func done(_ sender: Any) {
        if let selectedAssets = imagePickerController?.selectedAssets.array as? [PHAsset] {
            imagePickerController?.delegate?.sc_imagePickerController(imagePickerController!, didFinishPickingAssets: selectedAssets)
        }
    }
    
    // MARK: - Toolbar
    func setUpToolbarItems() {
        // Space
        let leftSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let rightSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // Info label
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.black]
        let infoButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        infoButtonItem.isEnabled = false
        infoButtonItem.setTitleTextAttributes(attributes, for: .normal)
        infoButtonItem.setTitleTextAttributes(attributes, for: .disabled)
        
        self.toolbarItems = [leftSpace, infoButtonItem, rightSpace]
    }
    
    func updateSelectionInfo() {
        guard let selectedAssets = imagePickerController?.selectedAssets else { return }
        
        if selectedAssets.count > 0 {
            let bundle = imagePickerController?.assetBundle ?? .main
            let format: String
            if selectedAssets.count > 1 {
                format = NSLocalizedString("assets.toolbar.items-selected", tableName: "SCImagePicker", bundle: bundle, comment: "")
            } else {
                format = NSLocalizedString("assets.toolbar.item-selected", tableName: "SCImagePicker", bundle: bundle, comment: "")
            }
            
            let title = String(format: format, selectedAssets.count)
            (self.toolbarItems?[1] as? UIBarButtonItem)?.title = title
        } else {
            (self.toolbarItems?[1] as? UIBarButtonItem)?.title = ""
        }
    }
    
    // MARK: - Fetching Asset Collections
    func updateAssetCollections() {
        // Filter albums
        guard let assetCollectionSubtypes = imagePickerController?.assetCollectionSubtypes else { return }
        var smartAlbums: [PHAssetCollectionSubtype: [PHAssetCollection]] = [:]
        var userAlbums: [PHAssetCollection] = []
        
        for fetchResult in fetchResults {
            fetchResult.enumerateObjects { assetCollection, _, _ in
                let subtype = assetCollection.assetCollectionSubtype
                
                if subtype == .albumRegular {
                    userAlbums.append(assetCollection)
                } else if assetCollectionSubtypes.contains(subtype) {
                    if smartAlbums[subtype] == nil {
                        smartAlbums[subtype] = []
                    }
                    smartAlbums[subtype]?.append(assetCollection)
                }
            }
        }
        
        var assetCollections: [PHAssetCollection] = []
        
        // Fetch smart albums
        for assetCollectionSubtype in assetCollectionSubtypes {
            if let collections = smartAlbums[assetCollectionSubtype] {
                assetCollections.append(contentsOf: collections)
            }
        }
        
        // Fetch user albums
        assetCollections.append(contentsOf: userAlbums)
        
        self.assetCollections = assetCollections
    }
    
    // MARK: - Checking for Selection Limit
    func isMinimumSelectionLimitFulfilled() -> Bool {
        return imagePickerController?.minimumNumberOfSelection ?? 0 <= imagePickerController?.selectedAssets.count ?? 0
    }
    
    func isMaximumSelectionLimitReached() -> Bool {
        guard let imagePickerController = imagePickerController else { return false }
        let minimumNumberOfSelection = max(1, imagePickerController.minimumNumberOfSelection)
        
        if minimumNumberOfSelection <= imagePickerController.maximumNumberOfSelection {
            return imagePickerController.maximumNumberOfSelection <= imagePickerController.selectedAssets.count
        }
        
        return false
    }
    
    func updateControlState() {
        doneButton.isEnabled = isMinimumSelectionLimitFulfilled()
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assetCollections.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumCell", for: indexPath) as? SCAlbumCell else {
            return UITableViewCell()
        }
        cell.tag = indexPath.row
        cell.borderWidth = 1.0 / UIScreen.main.scale
        
        // Thumbnail
        let assetCollection = assetCollections[indexPath.row]
        let options = PHFetchOptions()
        
        switch imagePickerController?.mediaType {
        case .image:
            options.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        case .video:
            options.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        case .any:
            if imagePickerController?.shouldFilterOutVideosWithMaxNumberOfSeconds == true {
                let duration = imagePickerController?.maxNumberOfSecondsForVideos ?? 0
                options.predicate = NSPredicate(format: "(mediaType == %ld AND duration <= %d) OR mediaType == %ld", PHAssetMediaType.video.rawValue, duration, PHAssetMediaType.image.rawValue)
            } else {
                options.predicate = NSPredicate(format: "(mediaType == %ld) OR mediaType == %ld", PHAssetMediaType.video.rawValue, PHAssetMediaType.image.rawValue)
            }
        default:
            break
        }
        
        let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: options)
        let imageManager = PHImageManager.default()
        
        if fetchResult.count >= 3 {
            cell.imageView3.isHidden = false
            
            imageManager.requestImage(for: fetchResult[fetchResult.count - 3],
                                      targetSize: CGSizeScale(cell.imageView3.frame.size, UIScreen.main.scale),
                                      contentMode: .aspectFill,
                                      options: nil) { result, _ in
                if cell.tag == indexPath.row, let result = result {
                    cell.imageView3.image = result
                }
            }
        } else {
            cell.imageView3.isHidden = true
        }
        
        if fetchResult.count >= 2 {
            cell.imageView2.isHidden = false
            
            imageManager.requestImage(for: fetchResult[fetchResult.count - 2],
                                      targetSize: CGSizeScale(cell.imageView2.frame.size, UIScreen.main.scale),
                                      contentMode: .aspectFill,
                                      options: nil) { result, _ in
                if cell.tag == indexPath.row, let result = result {
                    cell.imageView2.image = result
                }
            }
        } else {
            cell.imageView2.isHidden = true
        }
        
        if fetchResult.count >= 1 {
            imageManager.requestImage(for: fetchResult[fetchResult.count - 1],
                                      targetSize: CGSizeScale(cell.imageView1.frame.size, UIScreen.main.scale),
                                      contentMode: .aspectFill,
                                      options: nil) { result, _ in
                if cell.tag == indexPath.row, let result = result {
                    cell.imageView1.image = result
                }
            }
        }
        
        if fetchResult.count == 0 {
            cell.imageView3.isHidden = false
            cell.imageView2.isHidden = false
            
            // Set placeholder image
            let placeholderImage = placeholderImageWithSize(size: cell.imageView1.frame.size)
            cell.imageView1.image = placeholderImage
            cell.imageView2.image = placeholderImage
            cell.imageView3.image = placeholderImage
        }
        
        // Album title
        cell.titleLabel.text = assetCollection.localizedTitle
        
        // Number of photos
        cell.countLabel.text = "\(fetchResult.count)"
        
        return cell
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            var updatedFetchResults = self.fetchResults
            
            for (index, fetchResult) in self.fetchResults.enumerated() {
                if let changeDetails = changeInstance.changeDetails(for: fetchResult) {
                    updatedFetchResults[index] = changeDetails.fetchResultAfterChanges
                }
            }
            
            if self.fetchResults != updatedFetchResults {
                self.fetchResults = updatedFetchResults
                
                // Reload albums
                self.updateAssetCollections()
                self.tableView.reloadData()
            }
        }
    }
    
    // Helper function to scale a CGSize
    private func CGSizeScale(_ size: CGSize, _ scale: CGFloat) -> CGSize {
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
    
    // Placeholder image
    private func placeholderImageWithSize(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        let backgroundColor = UIColor(red: 239.0 / 255.0, green: 239.0 / 255.0, blue: 244.0 / 255.0, alpha: 1.0)
        let iconColor = UIColor(red: 179.0 / 255.0, green: 179.0 / 255.0, blue: 182.0 / 255.0, alpha: 1.0)
        
        // Background
        context.setFillColor(backgroundColor.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Icon (back)
        let backIconRect = CGRect(x: size.width * (16.0 / 68.0), y: size.height * (20.0 / 68.0), width: size.width * (32.0 / 68.0), height: size.height * (24.0 / 68.0))
        
        context.setFillColor(iconColor.cgColor)
        context.fill(backIconRect)
        
        context.setFillColor(backgroundColor.cgColor)
        context.fill(backIconRect.insetBy(dx: 1.0, dy: 1.0))
        
        // Icon (front)
        let frontIconRect = CGRect(x: size.width * (20.0 / 68.0), y: size.height * (24.0 / 68.0), width: size.width * (32.0 / 68.0), height: size.height * (24.0 / 68.0))
        
        context.setFillColor(backgroundColor.cgColor)
        context.fill(frontIconRect.insetBy(dx: -1.0, dy: -1.0))
        
        context.setFillColor(iconColor.cgColor)
        context.fill(frontIconRect)
        
        context.setFillColor(backgroundColor.cgColor)
        context.fill(frontIconRect.insetBy(dx: 1.0, dy: 1.0))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
