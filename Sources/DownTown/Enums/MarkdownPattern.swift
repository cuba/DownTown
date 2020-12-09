//
//  File.swift
//  
//
//  Created by Jakub Sikorski on 2020-12-08.
//

import Foundation

enum MarkdownPattern: String, CaseIterable {
    case italic
    case italicAlt
    case bold
    case boldAlt
    case strikethrough
    case codeBlock
    case codeSpan
    case newline
    case boldAndItalic
    case boldAndItalicAlt
    case heading
    
    var type: MarkdownPatternType {
        switch self {
        case .bold: return .fixedCharacters("*", 2)
        case .boldAlt: return .fixedCharacters("_", 2)
        case .boldAndItalic: return .fixedCharacters("*", 3)
        case .boldAndItalicAlt: return .fixedCharacters("_", 3)
        case .codeBlock: return .fixedCharacters("`", 3)
        case .codeSpan: return .fixedCharacters("`", 1)
        case .heading: return .repeatingCharacter("#")
        case .italic: return .fixedCharacters("*", 1)
        case .italicAlt: return .fixedCharacters("_", 1)
        case .newline: return .fixedCharacters("\n", 1)
        case .strikethrough: return .fixedCharacters("~", 2)
        }
    }
    
    var mustBeStartOfLine: Bool {
        switch self {
        case .italic, .italicAlt, .bold, .boldAlt, .strikethrough, .codeSpan, .codeBlock, .newline, .boldAndItalic, .boldAndItalicAlt:
            return false
        case .heading:
            return true
        }
    }
    
    func makeSyntax(characterCount: UInt) -> MarkdownSyntax {
        switch self {
        case .bold:
            return .unclosedSequence(.bold)
        case .boldAlt:
            return .unclosedSequence(.boldAlt)
        case .boldAndItalic:
            return .unclosedSequence(.boldAndItalic)
        case .boldAndItalicAlt:
            return .unclosedSequence(.boldAndItalicAlt)
        case .codeBlock:
            return .unclosedSequence(.codeBlock)
        case .codeSpan:
            return .unclosedSequence(.codeSpan)
        case .heading:
            return .unclosedSequence(.heading(level: characterCount))
        case .italic:
            return .unclosedSequence(.italic)
        case .italicAlt:
            return .unclosedSequence(.italicAlt)
        case .newline:
            return .newline
        case .strikethrough:
            return .unclosedSequence(.strikethrough)
        }
    }
}
