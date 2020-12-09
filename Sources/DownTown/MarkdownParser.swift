//
//  File.swift
//  
//
//  Created by Jakub Sikorski on 2020-12-02.
//

import Foundation

private typealias SyntaxWithRange = (syntax: MarkdownSyntax, range: ClosedRange<Int>)
private typealias SequenceWithRange = (sequence: MarkdownSequence, range: ClosedRange<Int>)

class MarkdownParser {
    public func parsePattern(for string: String) -> [MarkdownSyntax] {
        var stack = Stack<SyntaxWithRange>()
        var currentIndex = 0
        
        guard let firstElement = fetchNextElement(for: string, startingAt: currentIndex) else {
            return []
        }
        
        currentIndex = firstElement.range.upperBound + 1
        stack.push(firstElement)
        
        while let next = fetchNextElement(for: string, startingAt: currentIndex) {
            if let previous = stack.peek {
                switch previous.syntax {
                case .unclosedSequence(let previousSequence):
                    switch previousSequence {
                    case .codeBlock:
                        switch next.syntax {
                        case .unclosedSequence(let nextSequence):
                            switch nextSequence {
                            case .codeBlock:
                                let range = (previous.range.upperBound + 1)...(next.range.lowerBound - 1)
                                let substring = string[range]
                                let syntax = MarkdownSyntax.codeBlock(rawText: String(substring))
                                stack.pop()
                                stack.push((syntax, previous.range.lowerBound...next.range.upperBound))
                            default:
                                // We ignore everything until we find the closing code block
                                break
                            }
                        default:
                            break
                        }
                    case .codeSpan:
                        switch next.syntax {
                        case .unclosedSequence(let nextSequence):
                            switch nextSequence {
                            case .codeSpan:
                                let range = (previous.range.upperBound + 1)...(next.range.lowerBound - 1)
                                let substring = string[range]
                                let syntax = MarkdownSyntax.codeSpan(rawText: String(substring))
                                stack.pop()
                                stack.push((syntax, previous.range.lowerBound...next.range.upperBound))
                            default:
                                // We ignore everything until we find the closing code block
                                break
                            }
                        default:
                            // We ignore everything until we find the closing of our code block
                            break
                        }
                    case .bold, .boldAlt, .boldAndItalic, .boldAndItalicAlt, .italic, .italicAlt, .strikethrough, .heading:
                        stack.push(next)
                        reduce(stack: &stack, finalize: false)
                    }
                default:
                    stack.push(next)
                    reduce(stack: &stack, finalize: false)
                }
            } else {
                stack.push(next)
            }
            
            currentIndex = next.range.upperBound + 1
        }
        
        reduce(stack: &stack, finalize: true)
        
        return stack.elements.map { syntaxWithRange -> MarkdownSyntax in
            return syntaxWithRange.syntax
        }
    }
    
    private func reduce(stack: inout Stack<SyntaxWithRange>, finalize: Bool) {
        var seen: [SyntaxWithRange] = []
        var currentIndex = stack.count - 1
        
        // Go backwards through this stack as long as we have at least 2 elements (can't reduce a stack with only 1 element)
        while currentIndex >= 0 {
            let startResult = stack[currentIndex]
            let endResult = stack[stack.count - 1]
            let range = startResult.range.lowerBound...endResult.range.upperBound
            
            switch startResult.syntax {
            case .unclosedSequence(let startSequence):
                switch startSequence {
                case .heading(let level):
                    switch endResult.syntax {
                    case .newline:
                        replaceElements(on: &stack, fromIndex: &currentIndex) { stack in
                            // We need to remove the first element added which was the newline
                            seen.removeFirst()
                            
                            addHeading(level: level, to: &stack, body: seen.extractBody(), range: range)
                            let syntax = MarkdownSyntax.newline
                            stack.push((syntax, range))
                        }
                    default:
                        if finalize {
                            replaceElements(on: &stack, fromIndex: &currentIndex) { stack in
                                addHeading(level: level, to: &stack, body: seen.extractBody(), range: range)
                            }
                        } else {
                            // if we hit a sequence that is not closed by the previous sequence or syntax, we stop.
                            // Its impossible to hit such a situation unless the closing for this sequence has not yet been discovered
                            // and is not on our stack yet
                            return
                        }
                    }
                default:
                    // We need at least 2 elements to close this sequence
                    guard currentIndex < stack.count - 1 else {
                        currentIndex -= 1
                        continue
                    }
                    
                    switch endResult.syntax {
                    case .unclosedSequence(let endSequence):
                        if let emphasisType = startSequence.emphasisType(forClosingSequence: endSequence) {
                            replaceElements(on: &stack, fromIndex: &currentIndex) { stack in
                                let start: SequenceWithRange = (startSequence, startResult.range)
                                let end: SequenceWithRange = (endSequence, endResult.range)
                                addEmphasis(of: emphasisType, to: &stack, body: seen.extractBody(), start: start, end: end, range: range)
                            }
                        } else {
                            // if we hit a sequence that is not closed by the previous sequence or syntax, we stop.
                            // Its impossible to hit such a situation unless the closing for this sequence has not yet been discovered
                            // and is not on our stack yet
                            return
                        }
                    default:
                        // For now, nothing can be closed
                        currentIndex -= 1
                    }
                }
            default:
                // All other syntaxes need to be added to seen
                seen.append(startResult)
                currentIndex -= 1
            }
        }
    }
    
    private func replaceElements(on stack: inout Stack<SyntaxWithRange>, fromIndex index: inout Int, with callback: (inout Stack<SyntaxWithRange>) -> Void) {
        stack.pop(untilIndex: index)
        callback(&stack)
        index = stack.count - 1
    }
    
    private func addHeading(level: UInt, to stack: inout Stack<SyntaxWithRange>, body: [MarkdownSyntax], range: ClosedRange<Int>) {
        let syntax = MarkdownSyntax.heading(level: level, body: body)
        stack.push((syntax, range))
    }
    
    private func addEmphasis(of emphasisType: EmphasisType, to stack: inout Stack<SyntaxWithRange>, body: [MarkdownSyntax], start: SequenceWithRange, end: SequenceWithRange, range: ClosedRange<Int>) {
        let startSequence = start.sequence
        let endSequence = end.sequence
        
        // Breakdown the start sequence using the end sequence if possible and add it to the stack
        // For example, `***` (italic and bold) will be broken down by an end sequence of `**` (bold) into a remaining `*` (italic)
        switch startSequence.pattern.type {
        case .fixedCharacters(_, let characterCount):
            if let sequence = startSequence.breakdown(using: endSequence) {
                let newRange = start.range.lowerBound...(start.range.lowerBound + Int(characterCount))
                let unclosedSequence = MarkdownSyntax.unclosedSequence(sequence)
                stack.push((unclosedSequence, newRange))
            }
        case .repeatingCharacter:
            // Repeating characters can't be broken down
            break
        }
        
        let syntax = MarkdownSyntax.emphasis(type: emphasisType, body: body)
        stack.push((syntax, range))
        
        // Breakdown the end sequence using the start sequence if possible and add it to the stack
        // For example, `***` (italic and bold) will be broken down by a start sequence of `*` (italic) into a remaining `**` (bold)
        switch startSequence.pattern.type {
        case .fixedCharacters(_, let characterCount):
            if let sequence = endSequence.breakdown(using: startSequence) {
                let newRange = (end.range.upperBound - Int(characterCount))...end.range.upperBound
                let unclosedSequence = MarkdownSyntax.unclosedSequence(sequence)
                stack.push((unclosedSequence, newRange))
            }
        case .repeatingCharacter:
            // Repeating characters can't be broken down
            break
        }
    }
    
    private func fetchNextElement(for string: String, startingAt startIndex: Int) -> (syntax: MarkdownSyntax, range: ClosedRange<Int>)? {
        guard startIndex < string.count else {
            return nil
        }
        
        // First check if there is any sequence ahead. We may just have no remaining markdown
        guard let next = advanceUntilNextSequence(for: string, startingAt: startIndex) else {
            // There is no sequence ahead...the whole remaining string is plain text
            let range = startIndex...(string.count - 1)
            let text = String(string[range])
            
            return (.body(text), range)
        }
        
        // Next check if there is plain text ahead of our next element and return that plain string instead
        if startIndex < next.range.lowerBound {
            // We found plain text
            let range = startIndex...(next.range.lowerBound - 1)
            let text = String(string[range])
            
            return (.body(text), range)
        } else {
            return next
        }
    }
    
    private func advanceUntilNextSequence(for string: String, startingAt startIndex: Int) -> (syntax: MarkdownSyntax, range: ClosedRange<Int>)? {
        var currentIndex = startIndex
        var candidates = advanceToPossibleCandidateType(for: string, currentIndex: &currentIndex)
        var sequenceOffsets: [MarkdownPattern: UInt] = [:]
        var confirmed: [(syntax: MarkdownSyntax, range: ClosedRange<Int>)] = []
        
        // Since we have the candidates, point to the first character in the sequence
        for candidate in candidates {
            sequenceOffsets[candidate] = 0
        }
        
        // Go through each character and see if we found anything for each applicable sequence
        while currentIndex < string.count && !candidates.isEmpty {
            let currentCharacter = string[currentIndex]
            var nextCandidates: [MarkdownPattern] = []
            var newConfirmed: [(syntax: MarkdownSyntax, range: ClosedRange<Int>)] = []
            
            for pattern in candidates {
                guard let offset = sequenceOffsets[pattern] else {
                    // This candidate is no longer valid, or is already confirmed. skip it
                    continue
                }
                
                switch pattern.type {
                case .fixedCharacters(let character, let count):
                    guard offset < count && character == currentCharacter else {
                        // Remove this as a valid candidate since this character in the sequence no longer matches or we're outside
                        // its range
                        sequenceOffsets.removeValue(forKey: pattern)
                        continue
                    }
                    
                    // We've reached the end of this sequence. Add it to our confirmed list
                    if offset == (count - 1) {
                        let syntax = pattern.makeSyntax(characterCount: offset + 1)
                        let range = (currentIndex - Int(offset))...currentIndex
                        newConfirmed.append((syntax, range))
                        sequenceOffsets.removeValue(forKey: pattern)
                        continue
                    }
                case .repeatingCharacter(let character):
                    guard character == currentCharacter else {
                        // Check if the previous offset was larger than 0
                        if offset > 0 {
                            // We don't add 1 since we want the previous iteration
                            let syntax = pattern.makeSyntax(characterCount: offset)
                            let range = (currentIndex - Int(offset))...currentIndex
                            newConfirmed.append((syntax, range))
                        }
                        
                        sequenceOffsets.removeValue(forKey: pattern)
                        continue
                    }
                }
                
                // Add this as a candidate since we're not done with this sequence]
                nextCandidates.append(pattern)
            }
            
            if !newConfirmed.isEmpty {
                // If we have new confirmed sequences, we can remove the old ones (replace them) since they are longer
                // then the previous candidates and longer candidates always win. For example a found bold (`**`) wins over a an italic (`*`)
                confirmed = newConfirmed
            }
            
            candidates = nextCandidates
            
            for candidate in candidates {
                // Increment the offsets on each potential sequence since they got through this level
                sequenceOffsets[candidate] = (sequenceOffsets[candidate] ?? 0) + 1
            }
            
            currentIndex += 1
        }
        
        // We've landed on multiple confirmed sequences. Only one wins.
        // This shouldn't happen in theory because that means 2 sequences have the exact same length and characters
        // (i.e. they are not unique) which should be impossible
        if let found = confirmed.first {
            return found
        } else {
            return nil
        }
    }
    
    private func advanceToPossibleCandidateType(for string: String, currentIndex: inout Int) -> [MarkdownPattern] {
        // Find candidate sequences. We stop when we find a single candidate for any index.
        // This is because the first candidates we find is the start of something and we should handle it
        // Every sequence after this doesn't matter
        while currentIndex < string.count && currentIndex < string.count {
            var candidates: [MarkdownPattern] = []
            let currentCharacter = string[currentIndex]
            let isAtStartOfLine = string.isStartOfLine(atIndex: currentIndex)
            
            for pattern in MarkdownPattern.allCases {
                guard !pattern.mustBeStartOfLine || isAtStartOfLine else {
                    // Ensure that this sequence doesn't need to be at the start of a line
                    continue
                }
                
                switch pattern.type {
                case .fixedCharacters(let character, _):
                    if currentCharacter == character {
                        // Found candidate add it to the list
                        candidates.append(pattern)
                    }
                case .repeatingCharacter(let character):
                    if currentCharacter == character {
                        // Found candidate add it to the list
                        candidates.append(pattern)
                    }
                }
            }
            
            guard candidates.isEmpty else {
                // When we find something we return all the candidates right away so the index
                // doesn't increase and points to the start of these candidates
                return candidates
            }
            
            currentIndex += 1
        }
        
        return []
    }
}

private extension Array where Element == SyntaxWithRange {
    mutating func extractBody() -> [MarkdownSyntax] {
        var body: [MarkdownSyntax] = []
        while !isEmpty { body.append(removeLast().syntax) }
        return body
    }
}
