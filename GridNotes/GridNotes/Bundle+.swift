//
//  Bundle+.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/17/21.
//

import UIKit


extension Bundle {
    var marketingVersion: String {
        return infoDictionary!["CFBundleShortVersionString"] as! String
    }
}
