//
//  Array+.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/19/21.
//

import Foundation


extension Array {
    
    /// Returns an array containing the elements at the given indices.
    /// Crashes on index out-of-bounds.
    func elementsAt(indices: [Int]) -> [Element] {
        var elements: [Element] = []
        for i in indices {
            elements.append(self[i])
        }
        return elements
    }

    /// Returns an array containing the elements at the given indices.
    /// Out-of-bounds indices result in nil elements.
    func getAt(indices: [Int]) -> [Element] {
        var elements: [Element] = []
        for i in indices {
            if let element = self.get(index: i) {
                elements.append(element)
            }
        }
        return elements
    }

    /// Returns the element at the given index, or nil if out-of-bounds.
    func get(index: Int) -> Element? {
        guard index < self.count else { return nil }
        return self[index]
    }
}
