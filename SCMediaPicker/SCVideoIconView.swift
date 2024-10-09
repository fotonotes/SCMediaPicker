//
//  SCVideoIconView.swift
//  SCMediaPicker
//
//  Created by Glenn Posadas on 10/1/24.
//

import UIKit

@IBDesignable
class SCVideoIconView: UIView {

    @IBInspectable var iconColor: UIColor = .white

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set default values
        iconColor = .white
    }

    override func draw(_ rect: CGRect) {
        iconColor.setFill()
        
        // Draw triangle
        let trianglePath = UIBezierPath()
        trianglePath.move(to: CGPoint(x: bounds.maxX, y: bounds.minY))
        trianglePath.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        trianglePath.addLine(to: CGPoint(x: bounds.maxX - bounds.midY, y: bounds.midY))
        trianglePath.close()
        trianglePath.fill()
        
        // Draw rounded square
        let squarePath = UIBezierPath(roundedRect: CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width - bounds.midY - 1.0, height: bounds.height), cornerRadius: 2.0)
        squarePath.fill()
    }
}
