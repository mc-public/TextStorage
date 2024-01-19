//
//  TextStorageTests.swift
//
//
//  Created by mc-public on 2024/1/18.

#if DEBUG
import XCTest
@testable
import TextStorage


final class TextStorageTests: XCTestCase {
    
    let testStrings: [String] = [
        "",/* empty string */
        "\n", "\r\n","\n\n\n\r\n", "\r\n\n\n\n",
        "🌏Hello,World!\n🌏Hell♪o,W🐥orld!\n🌏Hello🐥,World!\n🌏Hello,World!\n",
        "🌏Hello,World!\n🌏Hello,Wo🐥rld²!\n🌏²Hello,W\rorld!\n🌏Hello,World!\r\n\r",
        "🌏🇺🇸AHello,Woاَلْعَرَبِيَّةُ‎rld!²\n🌏BHello,✔️World!你好🇺🇸²世🐥界\n🌏CHello,World!\n🌏Hello,World!",
        "🌏Hello,World!\r\n🌏Heاَلْعَرَبِيَّةُ‎llo,🇺🇸World!\n🌏Hello,Woᠮᠣᠩᠭᠣᠯ ᠪᠢᠴᠢᠭ᠌rld!\r\n🌏Hello,World!🇺🇸"
    ]
    
    private func printTime(_ prompt: String, closure: @escaping () throws -> ()) rethrows {
        let time1 = CFAbsoluteTimeGetCurrent()
        
            try closure()
        
        
        let time2 = CFAbsoluteTimeGetCurrent()
        print(prompt + ":", "\((time2 - time1) * 1000) ms")
    }
    
    func testPerformance() throws {
        guard let path = Bundle.module.path(forResource: "sqlite3", ofType: "txt") else {
            XCTFail()
            return
        }
        let string = try NSString(contentsOfFile: path, encoding: NSUTF16LittleEndianStringEncoding).copy() as! NSString
        let string2 = try NSMutableString(contentsOfFile: path, encoding: NSUTF16LittleEndianStringEncoding)
        let string3 = try NSMutableString(contentsOfFile: path, encoding: NSUTF16LittleEndianStringEncoding)
        let string4 = try NSMutableString(contentsOfFile: path, encoding: NSUTF16LittleEndianStringEncoding)
        let string5 = try NSMutableString(contentsOfFile: path, encoding: NSUTF16LittleEndianStringEncoding)
        self.printTime("[TextStorage]Create Storage From sqlite3.c") {
            _ = TextStorage(string)
        }
        self.printTime("[TextStorage]Insert sqlite3.c to a empty storage") {
            let storage = TextStorage()
            storage.append(string)
        }
        let storage = TextStorage(string)
        let storage2 = TextStorage(string)
        let storage3 = TextStorage(string)
        let storage4 = TextStorage(string)
        let storage5 = TextStorage(string)
        self.printTime("[TextStorage]Insert sqlite3.c to top of sqlit3.c") {
            try! storage.insert(text: string, at: 0, respectComposedCharacter: false)
        }
        
        self.printTime("[TextStorage]Append sqlite3.c to sqlite3.c") {
            storage2.append(string)
        }
        self.printTime("[TextStorage]Insert single code unit to top of sqlit3.c") {
            _ = try? storage4.insert(text: "A", at: 0, respectComposedCharacter: false)
        }
        self.printTime("[TextStorage]Append single code unit to sqlit3.c") {
            storage5.append("A")
        }
        try self.printTime("[TextStorage]Access first, last and middle UTF-16 code unit") {
            _ = try storage3.codeUnit(at: 0)
            _ = try storage3.codeUnit(at: storage3.length - 1)
            _ = try storage3.codeUnit(at: storage3.length / 2)
        }
        try self.printTime("[TextStorage]Access all code unit") {
            for index in 0..<storage3.length {
                _ = try storage3.codeUnit(at: index)
            }
        }
        self.printTime("[NSMutableStrig]Insert sqlite3.c to top of sqlit3.c") {
            string2.insert(string as String, at: 0)
        }
        self.printTime("[NSMutableStrig]Insert single code unit to top of sqlit3.c") {
            string4.insert("H", at: 0)
        }
        self.printTime("[NSMutableStrig]Append single code unit to sqlit3.c") {
            string5.insert("H", at: string5.length - 1)
        }
        self.printTime("[NSMutableStrig]Append sqlite3.c to sqlite3.c") {
            string3.append(string as String)
        }
        self.printTime("[NSMutableStrig]Access first, last and middle UTF-16 code unit") {
            _ = string.character(at: 0)
            _ = string.character(at: storage3.length - 1)
            _ = string.character(at: storage3.length / 2)
        }
        self.printTime("[NSMutableStrig]Access all code unit") {
            for index in 0..<string.length {
                string.character(at: index)
            }
        }
        
    }
    
    
    func testCreateStorage() throws {
        self.testStrings.forEach { content in
            _ = TextStorage(content)
        }
    }
    
    func testUTF16Interaction() throws {
        try self.testStrings.forEach { content in
            self.testString(content)
            try self.testCodeUnit(content)
            self.testGetCharacter(content)
        }
    }
    
    func testLines() {
        self.testStrings.forEach { content in
            self.testLineCount(content)
            self.testLineContent(content)
            self.testLineRange(content)
            self.testLineBreak(content)
        }
    }
    
    func testInsertion() {
        self.testStrings.forEach { content in
            self.testInsertion(content)
        }
    }
    
    func testASCIICharacterInsert() throws {
        let content = "ABCDEFGHIJKLMNOPQRST"
        let storage = TextStorage(content)
        let testPairs = [
            (0, "1"), (2, "2"), (5, "3"), (0, "A"), (0, "A\n"), (2, "ABC\r\n"), (5, "ABC\r"), (content.utf16.count, "A\r\nABCSD\n"), (0, "ABCDEFGHIJKLM\r\nNOPQRS\nTUVWXYZ\r\n")
        ]
        for (insertIndex, insertString) in testPairs {
            XCTAssert((try storage.insert(text: insertString, at: insertIndex)) == (insertIndex, insertIndex + insertString.utf16.count))
        }
    }
    
    func testDeletion() throws {
        try self.testStrings.forEach { content in
            try self.testDeletion(content)
        }
    }
    
}

//MARK: - UTF-16 Interaction Tests
extension TextStorageTests {
    
    /// Test get entire string and calculate UTF-16 code unit length.
    func testString(_ content: String) {
        let storage = TextStorage(content)
        XCTAssert(storage.length == content.utf16.count)
        XCTAssert(storage.string == content)
    }
    
    /// Test get code unit.
    func testCodeUnit(_ content: String) throws {
        let content = content as NSString
        let storage = TextStorage(content)
        for utf16Index in 0..<storage.length {
            let unit = try storage.codeUnit(at: utf16Index)
            XCTAssert(unit == content.character(at: utf16Index))
        }
    }
    
    /// Test get character.
    func testGetCharacter(_ content: String) {
        let content = content as NSString
        let storage = TextStorage(content)
        for utf16Index in 0..<storage.length {
            let value = try? storage.character(at: utf16Index)
            XCTAssert(value != nil)
            let composedNSRange = content.rangeOfComposedCharacterSequence(at: utf16Index)
            let composedRange = composedNSRange.lowerBound..<composedNSRange.upperBound
            let string = content.substring(with: composedNSRange)
            XCTAssert(value?.character == Character(string))
            XCTAssert(value?.range == composedRange)
        }
    }
}

//MARK: - Line Tests
extension TextStorageTests {
    
    /// Test get line count
    func testLineCount(_ content: String) {
        let storage = TextStorage(content)
        XCTAssert(storage.lineCount == storage.lines.count, "\(storage.lineCount):\(storage.lines.count)")
        XCTAssert(storage.lineCount == content.lineCount,"[\(storage.lineCount):\( content.lineCount)]")
    }
    
    /// Test get line content
    func testLineContent(storage: TextStorage? = nil, _ content: String?) {
        let content = storage?.string ?? content ?? ""
        let storage = storage ?? TextStorage(content)
        var lineContent = [String]()
        var lineContent2 = [String]()
        for line in storage.lines {
            XCTAssert(line.string.last != "\n" && line.string.last != "\r\n")
            lineContent.append(line.string)
        }
        for lineIndex in 1...storage.lineCount {
            lineContent2.append(try! storage.lineContent(lineIndex: lineIndex).string)
        }
        XCTAssert(lineContent.count == content.lines.count,  "\(lineContent.count):\(content.lines.count)")
        XCTAssert(lineContent2 == content.lines)
    }
    
    /// Test line range
    func testLineRange(_ content: String) {
        let storage = TextStorage(content)
        for line in storage.lines {
            for unitIndex in line.range {
                XCTAssert(try storage.codeUnit(at: unitIndex) == (content as NSString).character(at: unitIndex), "[lineIndex: \(line.index), range: \(line.range)]")
                XCTAssert((try storage.character(at: unitIndex)).character != Character("\r\n"))
                XCTAssert((try storage.character(at: unitIndex)).character != Character("\n"))
            }
        }
    }
    
    /// Test line break type
    func testLineBreak(_ content: String) {
        let content = content as NSString
        let storage = TextStorage(content)
        self.testLineBreak(storage: storage)
    }
    
    /// Test line break type
    func testLineBreak(storage: TextStorage) {
        for line in storage.lines {
            switch line.type {
            case .CRLF:
                XCTAssert((try? storage.codeUnit(at: line.range.upperBound)) == ("\r" as NSString).character(at: 0), "\(storage.lines)")
                if (try? storage.codeUnit(at: line.range.upperBound)) == ("\r" as NSString).character(at: 0) {
                    
                } else {
                    print(storage.lines)
                }
                XCTAssert((try? storage.codeUnit(at: line.range.upperBound + 1)) == ("\n" as NSString).character(at: 0))
            case .LF:
                XCTAssert((try? storage.codeUnit(at: line.range.upperBound)) == ("\n" as NSString).character(at: 0))
            case .NO:
                XCTAssert(line.range.upperBound == storage.length)
            }
        }
    }
    
    
}

//MARK: - Insertion Tests

extension TextStorageTests {
    
    func testInsertion(_ content: String) {
        let content = content as NSString
        let insertContent: [String] = [
            "√","A","\r你","你好\r", "🌏", "🇺🇸\n", "\nABC\r\n", "\n", "\r\n", "\r\n\r\n","\n\n\n", "\n\n", "\n\r\n", "\r" /* "\r" cannot pass test */
        ]
        insertContent.forEach { insertContent in
            for u16Index in 0...content.length {
                let storage = TextStorage(content)
                for _ in 1...10 {
                    self.testInsertion(storage: storage, u16Index: u16Index, insertContent: insertContent)
                }
                self.testLineBreak(storage: storage)
                self.testLineContent(storage: storage, "")
            }
        }
    }
    
    
    func testInsertion(storage: TextStorage, u16Index: Int, insertContent: String) {
        guard let characterRange = (try? storage.character(at: u16Index))?.range else {
            XCTAssert(storage.length == 0 || u16Index < 0 || storage.length == u16Index)
            if storage.length == u16Index {
                guard let result = try? storage.insert(text: insertContent, at: u16Index) else {
                    XCTFail()
                    return
                }
                XCTAssert(result.movedFirstUnitIndex >= result.insertedFirstUnitIndex)
                XCTAssert(result.movedFirstUnitIndex - result.insertedFirstUnitIndex == (insertContent as NSString).length)
            }
            return
        }
        
        /* judge */
        guard let result = try? storage.insert(text: insertContent, at: u16Index) else {
            XCTFail()
            return
        }
        XCTAssert(result.movedFirstUnitIndex >= result.insertedFirstUnitIndex)
        XCTAssert(result.movedFirstUnitIndex - result.insertedFirstUnitIndex == (insertContent as NSString).length)
        XCTAssert(characterRange.lowerBound == result.insertedFirstUnitIndex)
    }
}

//MARK: - Deletion Tests
extension TextStorageTests {
    func testDeletion(_ content: String) throws {
        let content = content as NSString
        let storage = TextStorage(content)
        try self.testDeletion(storage: storage)
    }
    
    func testDeletion(storage: TextStorage) throws {
        let string = NSString(string: storage.string)
        /* test every place delete, O(n^2) */
        for i in 0..<string.length {
            for j in i..<string.length { /* 0<=i<=j<count */
                let storage = TextStorage(string)
                guard i < j else {
                    continue
                }
                guard j - i > 1 else {
                    let range = try? storage.delete(range: i..<j)
                    let i_range = try TextStorage(string).character(at: i).range//string.rangeOfComposedCharacterSequence(at: i)
                    XCTAssert(range == i_range.lowerBound..<i_range.upperBound)
                    continue
                }
                guard let range_1 = try? storage.character(at: i).range,
                      let range_2 = try? storage.character(at: j - 1).range,
                      let range = try? storage.delete(range: i..<j) else {
                    XCTFail()
                    continue
                }
                XCTAssert(range_1.lowerBound == range.lowerBound)
                XCTAssert(range_2.upperBound == range.upperBound)
            }
        }
        
    }
}

#endif
