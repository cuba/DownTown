//
//  File.swift
//  
//
//  Created by Jakub Sikorski on 2020-12-02.
//

import Foundation

public indirect enum MarkdownSyntax: Equatable, CustomStringConvertible {
    case body(String)
    case heading(level: UInt, body: [MarkdownSyntax])
    case emphasis(type: EmphasisType, body: [MarkdownSyntax])
    case codeBlock(rawText: String)
    case codeSpan(rawText: String)
    case unclosedSequence(MarkdownSequence)
    case newline
    
    public static func == (lhs: MarkdownSyntax, rhs: MarkdownSyntax) -> Bool {
        switch (lhs, rhs) {
        case (.body(let lhsText), .body(let rhsText)):
            return lhsText == rhsText
        case (.heading(let lhsLevel, let lhsBody), .heading(let rhsLevel, let rhsBody)):
            return lhsLevel == rhsLevel && lhsBody == rhsBody
        case (.emphasis(let lhsType, let lhsBody), .emphasis(let rhsType, let rhsBody)):
            return lhsType == rhsType && lhsBody == rhsBody
        case (.codeBlock(let lhsText), .codeBlock(let rhsText)):
            return lhsText == rhsText
        case (.codeSpan(let lhsText), .codeSpan(let rhsText)):
            return lhsText == rhsText
        case (.unclosedSequence(let lhsText), .unclosedSequence(let rhsText)):
            return lhsText == rhsText
        case (.newline, .newline):
            return true
        default:
            return false
        }
    }
    
    public var description: String {
        switch self {
        case .body(let text):
            return "\"\(text)\""
        case .heading(let level, let body):
            let bodyString = body.map({ String(describing: $0) }).joined(separator: ", ")
            
            let hashes = (0..<level).map { _ -> String in
                return "#"
            }.joined()
            
            return "\(hashes)\(bodyString)"
        case .emphasis(let type, let body):
            let bodyString = body.map({ String(describing: $0) }).joined(separator: ", ")
            
            switch type {
            case .bold:
                return "**\(bodyString)**"
            case .italic:
                return "*\(bodyString)*"
            case .strikethrough:
                return "~~\(bodyString)~~"
            }
        case .codeBlock(let rawText):
            return "```\(rawText)```"
        case .newline:
            return "\n"
        case .codeSpan(let rawText):
            return "`\(rawText)`"
        case .unclosedSequence(let sequence):
            return "unclosed(\(sequence))"
        }
    }
}
