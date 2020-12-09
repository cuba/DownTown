import XCTest
@testable import DownTown

final class DownTownTests: XCTestCase {
    func testParsingItalicMarkdown() throws {
        let parser = MarkdownParser()
        let sample = "*text*"

        let result = parser.parsePattern(for: sample)
        let expectedSyntax: [MarkdownSyntax] = [.emphasis(type: .italic, body: [.body("text")])]

        print(result)
        XCTAssertEqual(result, expectedSyntax)
    }

    func testParsingItalicMarkdownWithPrefixAndSuffix() throws {
        let parser = MarkdownParser()
        let sample = "some prefix *text* some suffix"

        let result = parser.parsePattern(for: sample)
        let expectedSyntax: [MarkdownSyntax] = [.body("some prefix "), .emphasis(type: .italic, body: [.body("text")]), .body(" some suffix")]

        print(result)
        XCTAssertEqual(result, expectedSyntax)
    }
    
    func testParsingItalicAltMarkdown() throws {
        let parser = MarkdownParser()
        let sample = "_text_"

        let result = parser.parsePattern(for: sample)
        let expectedSyntax: [MarkdownSyntax] = [.emphasis(type: .italic, body: [.body("text")])]

        XCTAssertEqual(result, expectedSyntax)
    }
    
    func testParsingBoldMarkdown() throws {
        let parser = MarkdownParser()
        let sample = "**text**"

        let result = parser.parsePattern(for: sample)
        let expectedSyntax: [MarkdownSyntax] = [.emphasis(type: .bold, body: [.body("text")])]

        XCTAssertEqual(result, expectedSyntax)
    }
    
    func testParsingBoldAltMarkdown() throws {
        let parser = MarkdownParser()
        let sample = "__text__"

        let result = parser.parsePattern(for: sample)
        let expectedSyntax: [MarkdownSyntax] = [.emphasis(type: .bold, body: [.body("text")])]

        XCTAssertEqual(result, expectedSyntax)
    }
    
    func testParsingStrikethroughMarkdown() throws {
        let parser = MarkdownParser()
        let sample = "~~text~~"

        let result = parser.parsePattern(for: sample)
        let expectedSyntax: [MarkdownSyntax] = [.emphasis(type: .strikethrough, body: [.body("text")])]

        XCTAssertEqual(result, expectedSyntax)
    }

    func testParsingCodeMarkdown() throws {
        let parser = MarkdownParser()
        let sample = "`\n**text**\n`"

        let result = parser.parsePattern(for: sample)
        let expectedSyntax: [MarkdownSyntax] = [.codeSpan(rawText: "\n**text**\n")]

        XCTAssertEqual(result, expectedSyntax)
    }
    
    func testParsingCodeBlockMarkdown() throws {
        let parser = MarkdownParser()
        let sample = "```\n**text**\n```"

        let result = parser.parsePattern(for: sample)
        let expectedSyntax: [MarkdownSyntax] = [.codeBlock(rawText: "\n**text**\n")]

        XCTAssertEqual(result, expectedSyntax)
    }

    func testFlatMarkdown() throws {
        let parser = MarkdownParser()
        let sample = "*italic* **bold** `code`, ~~strikethrough~~"

        let result = parser.parsePattern(for: sample)
        let expected: [MarkdownSyntax] = [
            .emphasis(type: .italic, body: [.body("italic")]),
            .body(" "),
            .emphasis(type: .bold, body: [.body("bold")]),
            .body(" "),
            .codeSpan(rawText: "code"),
            .body(", "),
            .emphasis(type: .strikethrough, body: [.body("strikethrough")])
        ]

        XCTAssertEqual(result, expected)
    }
    
    func testHeading() throws {
        let parser = MarkdownParser()
        let sample = "### Some heading"

        let result = parser.parsePattern(for: sample)
        let expected: [MarkdownSyntax] = [
            .heading(level: 3, body: [.body("Some heading")])
        ]

        XCTAssertEqual(result, expected)
    }
    
    func testHeadingWithBody() throws {
        let parser = MarkdownParser()
        let sample = "### Some heading\nwith body"

        let result = parser.parsePattern(for: sample)
        let expected: [MarkdownSyntax] = [
            .heading(level: 3, body: [.body("Some heading")]),
            .newline,
            .body("with body")
        ]

        XCTAssertEqual(result, expected)
    }
    
    func testBoldAndItalicMarkdown() throws {
        let parser = MarkdownParser()
        let sample = "***bold and italic***"

        let result = parser.parsePattern(for: sample)
        let expected: [MarkdownSyntax] = [
            .emphasis(type: .bold, body: [
                .emphasis(type: .italic, body: [
                    .body("bold and italic")
                ])
            ])
        ]

        XCTAssertEqual(result, expected)
    }

    func testNestedMarkdown() throws {
        let parser = MarkdownParser()
        let sample = "*italic **bold and \nitalic*** and then \nwe have ***bold and italic** italic* and then we have ***bold and italic* bold** and then we have **bold and *bold and italic*** and finally we have ***bold and italic***"

        let result = parser.parsePattern(for: sample)
        let expected: [MarkdownSyntax] = [
            .emphasis(type: .italic, body: [
                .body("italic "),
                .emphasis(type: .bold, body: [
                    .body("bold and "),
                    .newline,
                    .body("italic"),
                ])
            ]),
            .body(" and then "),
            .newline,
            .body("we have "),
            .emphasis(type: .italic, body: [
                .emphasis(type: .bold, body: [
                    .body("bold and italic")
                ]),
                .body(" italic")
            ]),
            .body(" and then we have "),
            .emphasis(type: .bold, body: [
                .emphasis(type: .italic, body: [
                    .body("bold and italic")
                ]),
                .body(" bold")
            ]),
            .body(" and then we have "),
            .emphasis(type: .bold, body: [
                .body("bold and "),
                .emphasis(type: .italic, body: [
                    .body("bold and italic")
                ])
            ]),
            .body(" and finally we have "),
            .emphasis(type: .bold, body: [
                .emphasis(type: .italic, body: [
                    .body("bold and italic")
                ])
            ])
        ]

        XCTAssertEqual(result, expected)
    }
}
