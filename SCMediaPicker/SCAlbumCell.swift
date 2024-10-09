//
//  SCAlbumCell.swift
//  SCMediaPicker
//
//  Created by Glenn Posadas on 10/1/24.
//

import UIKit

class SCAlbumCell: UITableViewCell {

    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!

    var borderWidth: CGFloat = 0 {
        didSet {
            imageView1.layer.borderColor = UIColor.white.cgColor
            imageView1.layer.borderWidth = borderWidth

            imageView2.layer.borderColor = UIColor.white.cgColor
            imageView2.layer.borderWidth = borderWidth

            imageView3.layer.borderColor = UIColor.white.cgColor
            imageView3.layer.borderWidth = borderWidth
        }
    }
}
