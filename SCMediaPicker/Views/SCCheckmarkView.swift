//
//  SCCheckmarkView.swift
//  SCMediaPicker
//
//  Created by Glenn Posadas on 10/1/24.
//

import UIKit

@IBDesignable
class SCCheckmarkView: UIView {

    @IBInspectable var borderWidth: CGFloat = 1.0
    @IBInspectable var checkmarkLineWidth: CGFloat = 1.2
    
    @IBInspectable var borderColor: UIColor = .white
    @IBInspectable var bodyColor: UIColor = UIColor(red: 20.0 / 255.0, green: 111.0 / 255.0, blue: 223.0 / 255.0, alpha: 1.0)
    @IBInspectable var checkmarkColor: UIColor = .white
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set shadow
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 2.0
    }
    
    override func draw(_ rect: CGRect) {
        // Border
        borderColor.setFill()
        UIBezierPath(ovalIn: bounds).fill()
        
        // Body
        bodyColor.setFill()
        UIBezierPath(ovalIn: bounds.insetBy(dx: borderWidth, dy: borderWidth)).fill()
        
        // Checkmark
        let checkmarkPath = UIBezierPath()
        checkmarkPath.lineWidth = checkmarkLineWidth
        
        checkmarkPath.move(to: CGPoint(x: bounds.width * (6.0 / 24.0), y: bounds.height * (12.0 / 24.0)))
        checkmarkPath.addLine(to: CGPoint(x: bounds.width * (10.0 / 24.0), y: bounds.height * (16.0 / 24.0)))
        checkmarkPath.addLine(to: CGPoint(x: bounds.width * (18.0 / 24.0), y: bounds.height * (8.0 / 24.0)))
        
        checkmarkColor.setStroke()
        checkmarkPath.stroke()
    }
}
