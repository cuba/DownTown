//
//  File.swift
//  
//
//  Created by Jakub Sikorski on 2020-11-12.
//

import Foundation

struct Stack<Element> {
    private(set) var elements: [Element]
    var count: Int { return elements.count }
    var isEmpty: Bool { return elements.isEmpty }
    
    var peek: Element? {
        return elements.last
    }
    
    init(_ elements: [Element] = []) {
        self.elements = elements
    }
    
    mutating func push(_ element: Element) {
        elements.append(element)
    }
    
    @discardableResult
    mutating func pop() -> Element? {
        return elements.popLast()
    }
    
    @discardableResult
    mutating func pop(untilIndex index: Int) -> [Element] {
        var results: [Element] = []
        
        while (count - 1) >= index {
            guard let item = self.pop() else {
                assertionFailure("Cannot be empty!")
                continue
            }
            
            results.append(item)
        }
        
        return results
    }
    
    subscript (i: Int) -> Element {
        return elements[i]
    }
    
    func findBackwards(where callback: (Element) -> Bool) -> Element? {
        var index = count - 1
        while index >= 0 {
            if callback(self[index]) {
                return self[index]
            } else {
                index -= 1
            }
        }
        
        return nil
    }
}

extension Stack: CustomDebugStringConvertible {
    public var debugDescription: String {
        let string = elements.map({ String(reflecting: $0) }).joined(separator: ", ")
        return "[\(string)]"
    }
}
