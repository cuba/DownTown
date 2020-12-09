//
//  File.swift
//  
//
//  Created by Jakub Sikorski on 2020-12-02.
//

import Foundation

extension String {
    var length: Int {
        return count
    }

    subscript (i: Int) -> Substring {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> Substring {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> Substring {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> Substring {
        let range = Range(
            uncheckedBounds: (
                lower: max(0, min(length, r.lowerBound)),
                upper: min(length, max(0, r.upperBound))
            )
        )
        
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return self[start..<end]
    }
    
    subscript (r: ClosedRange<Int>) -> Substring {
        let range = Range(
            uncheckedBounds: (
                lower: max(0, min(length, r.lowerBound)),
                upper: min(length, max(0, r.upperBound))
            )
        )
        
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return self[start...end]
    }
    
    func isStartOfLine(atIndex index: Int) -> Bool {
        return index == 0 || (index > 1 && self[(index - 1)...index] == "\n")
    }
}
