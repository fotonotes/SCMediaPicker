//
//  SCAssetsViewController.swift
//  SCMediaPicker
//
//  Created by Glenn Posadas on 10/2/24.
//

import UIKit
import Photos

extension IndexSet {
    func sc_indexPathsFromIndexes(withSection section: Int) -> [IndexPath] {
        return self.map { IndexPath(item: $0, section: section) }
    }
    
    func sc_containsAnyIndex(of otherSet: IndexSet) -> Bool {
        for index in otherSet {
            if self.contains(index) {
                return true
            }
        }
        return false
    }
}

extension UICollectionView {
    func sc_indexPathsForElements(in rect: CGRect) -> [IndexPath]? {
        let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElements(in: rect)
        guard let attributes = allLayoutAttributes, !attributes.isEmpty else { return nil }
        
        return attributes.map { $0.indexPath }
    }
}

class SCAssetsViewController: UICollectionViewController, PHPhotoLibraryChangeObserver, UICollectionViewDelegateFlowLayout {
    
    // MARK: -
    // MARK: Properties
        
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    weak var imagePickerController: SCImagePickerController?
    
    var assetCollection: PHAssetCollection? {
        didSet {
            updateFetchRequest()
            collectionView.reloadData()
        }
    }
    
    private var fetchResult: PHFetchResult<PHAsset>!
    private var imageManager = PHCachingImageManager()
    private var previousPreheatRect = CGRect.zero
    private var disableScrollToBottom = false
    private var lastSelectedItemIndexPath: IndexPath?
    
    // MARK: -
    // MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpToolbarItems()
        resetCachedAssets()
        
        PHPhotoLibrary.shared().register(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = assetCollection?.localizedTitle
        navigationItem.prompt = imagePickerController?.prompt
        collectionView.allowsMultipleSelection = imagePickerController?.allowsMultipleSelection ?? false
        
        if imagePickerController?.allowsMultipleSelection == true {
            navigationItem.setRightBarButton(doneButton, animated: false)
        } else {
            navigationItem.setRightBarButton(nil, animated: false)
        }
        
        updateDoneButtonState()
        updateSelectionInfo()
        collectionView.reloadData()
        
        if let fetchResult = fetchResult, fetchResult.count > 0, isMovingToParent, !disableScrollToBottom {
            DispatchQueue.main.async {
                let indexPath = IndexPath(item: fetchResult.count - 1, section: 0)
                self.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disableScrollToBottom = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableScrollToBottom = false
        updateCachedAssets()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let indexPath = collectionView.indexPathsForVisibleItems.last
        
        collectionViewLayout.invalidateLayout()
        
        coordinator.animate(alongsideTransition: nil) { _ in
            if let indexPath = indexPath {
                self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
            }
        }
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func setUpToolbarItems() {
        let leftSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let rightSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let infoButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        infoButtonItem.isEnabled = false
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.black]
        infoButtonItem.setTitleTextAttributes(attributes, for: .normal)
        infoButtonItem.setTitleTextAttributes(attributes, for: .disabled)
        
        toolbarItems = [leftSpace, infoButtonItem, rightSpace]
    }
    
    func updateSelectionInfo() {
        guard let selectedAssets = imagePickerController?.selectedAssets else { return }
        
        let bundle = imagePickerController?.assetBundle ?? .main
        
        if selectedAssets.count > 0 {
            let format: String
            if selectedAssets.count > 1 {
                format = bundle.localizedString(forKey: "assets.toolbar.items-selected", value: "%ld Items Selected", table: "SCImagePicker")
            } else {
                format = bundle.localizedString(forKey: "assets.toolbar.item-selected", value: "%ld Item Selected", table: "SCImagePicker")
            }
            
            let title = String(format: format, selectedAssets.count)
            (toolbarItems?[1] as? UIBarButtonItem)?.title = title
        } else {
            (toolbarItems?[1] as? UIBarButtonItem)?.title = ""
        }
    }
    
    func updateFetchRequest() {
        guard let assetCollection = assetCollection, let imagePickerController = imagePickerController else {
            fetchResult = nil
            return
        }
        
        let options = PHFetchOptions()
        switch imagePickerController.mediaType {
        case .image:
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        case .video:
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        case .any:
            if imagePickerController.shouldFilterOutVideosWithMaxNumberOfSeconds {
                let duration = imagePickerController.maxNumberOfSecondsForVideos
                options.predicate = NSPredicate(format: "(mediaType == %d AND duration <= %d) OR mediaType == %d", PHAssetMediaType.video.rawValue, duration, PHAssetMediaType.image.rawValue)
            } else {
                options.predicate = NSPredicate(format: "(mediaType == %d) OR mediaType == %d", PHAssetMediaType.video.rawValue, PHAssetMediaType.image.rawValue)
            }
        }
        
        fetchResult = PHAsset.fetchAssets(in: assetCollection, options: options)
        
        if isAutoDeselectEnabled, let selectedAsset = imagePickerController.selectedAssets.firstObject as? PHAsset {
            let assetIndex = fetchResult.index(of: selectedAsset)
            lastSelectedItemIndexPath = IndexPath(item: assetIndex, section: 0)
        }
    }
    
    var isAutoDeselectEnabled: Bool {
        guard let imagePickerController = imagePickerController else { return false }
        return (imagePickerController.maximumNumberOfSelection == 1 &&
                imagePickerController.maximumNumberOfSelection >= imagePickerController.minimumNumberOfSelection)
    }
    
    func updateDoneButtonState() {
        doneButton.isEnabled = isMinimumSelectionLimitFulfilled()
    }
    
    func isMinimumSelectionLimitFulfilled() -> Bool {
        guard let imagePickerController = imagePickerController else { return false }
        return imagePickerController.minimumNumberOfSelection <= imagePickerController.selectedAssets.count
    }
    
    func isMaximumSelectionLimitReached() -> Bool {
        guard let imagePickerController = imagePickerController else { return false }
        let minimumNumberOfSelection = max(1, imagePickerController.minimumNumberOfSelection)
        
        if minimumNumberOfSelection <= imagePickerController.maximumNumberOfSelection {
            return imagePickerController.maximumNumberOfSelection <= imagePickerController.selectedAssets.count
        }
        
        return false
    }
    
    func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    func updateCachedAssets() {
        guard isViewLoaded, view.window != nil else { return }
        
        let preheatRect = collectionView.bounds.insetBy(dx: 0, dy: -0.5 * collectionView.bounds.height)
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        
        if delta > collectionView.bounds.height / 3 {
            var addedIndexPaths = [IndexPath]()
            var removedIndexPaths = [IndexPath]()
            
            computeDifferenceBetweenRect(oldRect: previousPreheatRect, newRect: preheatRect,
                                         addedHandler: { addedRect in
                if let indexPaths = collectionView.sc_indexPathsForElements(in: addedRect) {
                    addedIndexPaths.append(contentsOf: indexPaths)
                }
            },
                                         removedHandler: { removedRect in
                if let indexPaths = collectionView.sc_indexPathsForElements(in: removedRect) {
                    removedIndexPaths.append(contentsOf: indexPaths)
                }
            })
            
            let assetsToStartCaching = assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = assetsAtIndexPaths(removedIndexPaths)
            
            let itemSize = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
            let targetSize = CGSize(width: itemSize.width * UIScreen.main.scale, height: itemSize.height * UIScreen.main.scale)
            
            imageManager.startCachingImages(for: assetsToStartCaching, targetSize: targetSize, contentMode: .aspectFill, options: nil)
            imageManager.stopCachingImages(for: assetsToStopCaching, targetSize: targetSize, contentMode: .aspectFill, options: nil)
            
            previousPreheatRect = preheatRect
        }
    }
    
    func computeDifferenceBetweenRect(oldRect: CGRect, newRect: CGRect, addedHandler: (CGRect) -> Void, removedHandler: (CGRect) -> Void) {
        if oldRect.intersects(newRect) {
            let oldMaxY = oldRect.maxY
            let oldMinY = oldRect.minY
            let newMaxY = newRect.maxY
            let newMinY = newRect.minY
            
            if newMaxY > oldMaxY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: oldMaxY, width: newRect.width, height: newMaxY - oldMaxY)
                addedHandler(rectToAdd)
            }
            if oldMinY > newMinY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: newMinY, width: newRect.width, height: oldMinY - newMinY)
                addedHandler(rectToAdd)
            }
            if newMaxY < oldMaxY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: newMaxY, width: newRect.width, height: oldMaxY - newMaxY)
                removedHandler(rectToRemove)
            }
            if oldMinY < newMinY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.width, height: newMinY - oldMinY)
                removedHandler(rectToRemove)
            }
        } else {
            addedHandler(newRect)
            removedHandler(oldRect)
        }
    }
    
    func assetsAtIndexPaths(_ indexPaths: [IndexPath]) -> [PHAsset] {
        guard !indexPaths.isEmpty else { return [] }
        
        var assets = [PHAsset]()
        for indexPath in indexPaths {
            if indexPath.item < fetchResult.count {
                let asset = fetchResult.object(at: indexPath.item)
                assets.append(asset)
            }
        }
        return assets
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResult = fetchResult else { return }
        
        DispatchQueue.main.async {
            if let collectionChanges = changeInstance.changeDetails(for: fetchResult) {
                self.fetchResult = collectionChanges.fetchResultAfterChanges
                
                if collectionChanges.hasIncrementalChanges {
                    self.collectionView.performBatchUpdates {
                        if let removedIndexes = collectionChanges.removedIndexes {
                            let indexPaths = removedIndexes.sc_indexPathsFromIndexes(withSection: 0)
                            self.collectionView.deleteItems(at: indexPaths)
                        }
                        if let insertedIndexes = collectionChanges.insertedIndexes {
                            let indexPaths = insertedIndexes.sc_indexPathsFromIndexes(withSection: 0)
                            self.collectionView.insertItems(at: indexPaths)
                        }
                        if let changedIndexes = collectionChanges.changedIndexes {
                            let indexPaths = changedIndexes.sc_indexPathsFromIndexes(withSection: 0)
                            self.collectionView.reloadItems(at: indexPaths)
                        }
                    }
                } else {
                    self.collectionView.reloadData()
                }
                self.resetCachedAssets()
            }
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetCell", for: indexPath) as? SCAssetCell else {
            fatalError("Unexpected cell in collection view")
        }
        
        cell.tag = indexPath.item
        cell.showsOverlayViewWhenSelected = imagePickerController?.allowsMultipleSelection ?? false
        
        // Image
        let asset = fetchResult.object(at: indexPath.item)
        let itemSize = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        let targetSize = CGSize(width: itemSize.width * UIScreen.main.scale, height: itemSize.height * UIScreen.main.scale)
        
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { (result, _) in
            if cell.tag == indexPath.item, let result = result {
                cell.imageView.image = result
            }
        }
        
        // Video indicator
        if asset.mediaType == .video {
            cell.videoIndicatorView.isHidden = false
            cell.videoIndicatorView.timeLabel.text = self.formattedDuration(from: asset.duration)
            
            if asset.mediaSubtypes.contains(.videoHighFrameRate) {
                cell.videoIndicatorView.videoIcon.isHidden = true
                cell.videoIndicatorView.slomoIcon.isHidden = false
            } else {
                cell.videoIndicatorView.videoIcon.isHidden = false
                cell.videoIndicatorView.slomoIcon.isHidden = true
            }
        } else {
            cell.videoIndicatorView.isHidden = true
        }
        
        // Selection state
        if imagePickerController?.selectedAssets.contains(asset) == true {
            cell.isSelected = true
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: UICollectionView.ScrollPosition.centeredVertically)
        }
        
        return cell
    }
    
    func formattedDuration(from interval: TimeInterval) -> String {
        let interval = round(interval)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        
        if interval >= 3600 {
            formatter.allowedUnits = [.hour, .minute, .second]
        } else {
            formatter.allowedUnits = [.minute, .second]
        }
        
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? ""
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FooterView", for: indexPath)
            
            if let label = footerView.viewWithTag(1) as? UILabel {
                let bundle = imagePickerController?.assetBundle ?? .main
                let numberOfPhotos = fetchResult.countOfAssets(with: .image)
                let numberOfVideos = fetchResult.countOfAssets(with: .video)
                
                var format = ""
                
                if let mediaType = imagePickerController?.mediaType {
                    switch mediaType {
                    case .any:
                        if numberOfPhotos == 1 {
                            format = bundle.localizedString(forKey: "assets.footer.photo-and-video", value: "%ld Photo, %ld Video", table: "SCImagePicker")
                        } else if numberOfVideos == 1 {
                            format = bundle.localizedString(forKey: "assets.footer.photos-and-video", value: "%ld Photos, %ld Video", table: "SCImagePicker")
                        } else {
                            format = bundle.localizedString(forKey: "assets.footer.photos-and-videos", value: "%ld Photos, %ld Videos", table: "SCImagePicker")
                        }
                        
                    case .image:
                        let key = numberOfPhotos == 1 ? "assets.footer.photo" : "assets.footer.photos"
                        let val = numberOfPhotos == 1 ? "%ld Photo" : "%ld Photos"
                        format = bundle.localizedString(forKey: key, value: val, table: "SCImagePicker")
                        
                    case .video:
                        let key = numberOfVideos == 1 ? "assets.footer.video" : "assets.footer.videos"
                        let val = numberOfPhotos == 1 ? "%ld Video" : "%ld Videos"
                        format = bundle.localizedString(forKey: key, value: val, table: "SCImagePicker")
                    }
                }
                
                label.text =  String(format: format, numberOfPhotos, numberOfVideos)
            }
            
            return footerView
        }
        
        return UICollectionReusableView()
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let delegate = imagePickerController?.delegate, let asset = fetchResult?.object(at: indexPath.item) {
            return delegate.sc_imagePickerController(imagePickerController!, shouldSelectAsset: asset)
        }
        
        return !isMaximumSelectionLimitReached()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let imagePickerController = imagePickerController else { return }
        let selectedAssets = imagePickerController.selectedAssets
        
        let asset = fetchResult.object(at: indexPath.item)
        
        if imagePickerController.allowsMultipleSelection {
            if isAutoDeselectEnabled, selectedAssets.count > 0 {
                selectedAssets.removeObject(at: 0)
                
                if let lastIndexPath = lastSelectedItemIndexPath {
                    collectionView.deselectItem(at: lastIndexPath, animated: false)
                }
            }
            
            selectedAssets.add(asset)
            lastSelectedItemIndexPath = indexPath
            updateDoneButtonState()
            
            if imagePickerController.showsNumberOfSelectedAssets {
                updateSelectionInfo()
                
                if selectedAssets.count == 1 {
                    navigationController?.setToolbarHidden(false, animated: true)
                }
            }
        } else {
            imagePickerController.delegate?.sc_imagePickerController(imagePickerController, didFinishPickingAssets: [asset])
        }
        
        imagePickerController.delegate?.sc_imagePickerController(imagePickerController, didSelectAsset: asset)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let imagePickerController = imagePickerController, imagePickerController.allowsMultipleSelection else { return }
        
        let asset = fetchResult.object(at: indexPath.item)
        imagePickerController.selectedAssets.remove(asset)
        lastSelectedItemIndexPath = nil
        updateDoneButtonState()
        
        if imagePickerController.showsNumberOfSelectedAssets {
            updateSelectionInfo()
            
            if imagePickerController.selectedAssets.count == 0 {
                navigationController?.setToolbarHidden(true, animated: true)
            }
        }
        
        imagePickerController.delegate?.sc_imagePickerController(imagePickerController, didDeselectAsset: asset)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: Int
        if UIApplication.shared.statusBarOrientation.isPortrait {
            numberOfColumns = imagePickerController?.numberOfColumnsInPortrait ?? 3
        } else {
            numberOfColumns = imagePickerController?.numberOfColumnsInLandscape ?? 5
        }
        
        let width = (view.frame.width - 2.0 * CGFloat(numberOfColumns - 1)) / CGFloat(numberOfColumns)
        return CGSize(width: width, height: width)
    }
}
