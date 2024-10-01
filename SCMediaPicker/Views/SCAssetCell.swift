//
//  SCAssetCell.swift
//  SCMediaPicker
//
//  Created by Glenn Posadas on 10/1/24.
//

import UIKit

class SCAssetCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var videoIndicatorView: SCVideoIndicatorView!
    @IBOutlet weak var overlayView: UIView!

    var showsOverlayViewWhenSelected: Bool = false

    override var isSelected: Bool {
        didSet {
            // Show/hide overlay view
            overlayView.isHidden = !(isSelected && showsOverlayViewWhenSelected)
        }
    }
}
