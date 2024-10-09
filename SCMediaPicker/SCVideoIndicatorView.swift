//
//  SCVideoIndicatorView.swift
//  SCMediaPicker
//
//  Created by Glenn Posadas on 10/1/24.
//

import UIKit

class SCVideoIndicatorView: UIView {

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var videoIcon: SCVideoIconView!
    @IBOutlet weak var slomoIcon: SCSlomoIconView!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Add gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.cgColor
        ]
        
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
}
