//
//  CGRect+.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/17/21.
//

import UIKit


extension CGRect {
    static func square(dimension: CGFloat) -> CGRect {
        return CGRect(x: 0, y: 0, width: dimension, height: dimension)
    }
    
    func centered(within containingRect: CGRect) -> CGRect {
        var centeredRect = self
        centeredRect.origin.x = (containingRect.width - width) / 2
        centeredRect.origin.y = (containingRect.height - height) / 2
        return centeredRect
    }
}
