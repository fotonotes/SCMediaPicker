//
//  SCSlomoIconView.swift
//  SCMediaPicker
//
//  Created by Glenn Posadas on 10/1/24.
//

import UIKit

@IBDesignable
class SCSlomoIconView: UIView {

    @IBInspectable var iconColor: UIColor = .white

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set default values
        iconColor = .white
    }

    override func draw(_ rect: CGRect) {
        iconColor.setStroke()
        
        let width: CGFloat = 2.2
        let insetRect = rect.insetBy(dx: width / 2, dy: width / 2)
        
        // Draw dashed circle
        let circlePath = UIBezierPath(ovalIn: insetRect)
        circlePath.lineWidth = width
        
        let dashPattern: [CGFloat] = [0.75, 0.75]
        circlePath.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
        
        circlePath.stroke()
    }
}
