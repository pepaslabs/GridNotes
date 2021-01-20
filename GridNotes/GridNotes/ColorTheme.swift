//
//  Theme.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/18/21.
//

import UIKit


/// Dynamic colors with fallbacks for iOS < 13.
struct ColorTheme {
    
    static var background: UIColor {
        if #available(iOS 13, *) {
            return UIColor.systemBackground
        } else {
            return UIColor.white
        }
    }
    
    static var label: UIColor {
        if #available(iOS 13, *) {
            return UIColor.label
        } else {
            return UIColor.black
        }
    }

    static var separator: UIColor {
        if #available(iOS 13, *) {
            return UIColor.secondaryLabel
        } else {
            return UIColor(white: 0.15, alpha: 1)
        }
    }
    
    static var shadedKey: UIColor {
        if #available(iOS 13, *) {
            return UIColor.systemGray3
        } else {
            return UIColor(white: 0.85, alpha: 1)
        }
    }
    
    static var activeKey: UIColor {
        return UIColor.yellow
    }
}
