//
//  File.swift
//  
//
//  Created by Jakub Sikorski on 2020-12-02.
//

import Foundation

public enum MarkdownSequence: Equatable {
    case italic
    case italicAlt
    case bold
    case boldAlt
    case strikethrough
    case codeBlock
    case codeSpan
    case boldAndItalic
    case boldAndItalicAlt
    case heading(level: UInt)
    
    var pattern: MarkdownPattern {
        switch self {
        case .bold: return .bold
        case .boldAlt: return .boldAlt
        case .boldAndItalic: return .boldAndItalic
        case .boldAndItalicAlt: return .boldAndItalicAlt
        case .codeBlock: return .codeBlock
        case .codeSpan: return .codeSpan
        case .heading: return .heading
        case .italic: return .italic
        case .italicAlt: return .italicAlt
        case .strikethrough: return .strikethrough
        }
    }
    
    func breakdown(using sequence: MarkdownSequence) -> MarkdownSequence? {
        switch self {
        case .bold: return nil
        case .boldAlt: return nil
        case .codeBlock: return nil
        case .codeSpan: return nil
        case .italic: return nil
        case .italicAlt: return nil
        case .strikethrough: return nil
        case .heading: return nil
        case .boldAndItalic:
            switch sequence {
            case .boldAndItalic: return .bold
            case .bold: return .italic
            case .italic: return .bold
            default: return nil
            }
        case .boldAndItalicAlt:
            switch sequence {
            case .boldAndItalicAlt: return .boldAlt
            case .boldAlt: return .italicAlt
            case .italicAlt: return .boldAlt
            default: return nil
            }
        }
    }
    
    func emphasisType(forClosingSequence closingSequence: MarkdownSequence) -> EmphasisType? {
        switch self {
        case .bold:
            switch closingSequence {
            case .bold:
                return .bold
            case .boldAndItalic:
                return .bold
            default:
                return nil
            }
        case .boldAlt:
            switch closingSequence {
            case .boldAlt:
                return .bold
            case .boldAndItalicAlt:
                return .bold
            default:
                return nil
            }
        case .italic:
            switch closingSequence {
            case .italic:
                return .italic
            case .boldAndItalic:
                return .italic
            default:
                return nil
            }
        case .italicAlt:
            switch closingSequence {
            case .italicAlt:
                return .italic
            case .boldAndItalicAlt:
                return .italic
            default:
                return nil
            }
        case .strikethrough:
            switch closingSequence {
            case .strikethrough:
                return .strikethrough
            default:
                return nil
            }
        case .boldAndItalic:
            switch closingSequence {
            case .boldAndItalic:
                return .italic
            case .bold:
                return .bold
            case .italic:
                return .italic
            default:
                return nil
            }
        case .boldAndItalicAlt:
            switch closingSequence {
            case .boldAndItalicAlt:
                return .italic
            case .boldAlt:
                return .bold
            case .italicAlt:
                return .italic
            default:
                return nil
            }
        default:
            return nil
        }
    }
}
