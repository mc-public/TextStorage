//
//  TextAsyncStorage.swift
//
//
//  Created by 孟超 on 2024/1/18.
//

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
//
//@available(iOS 13.0, macOS 12.0, *)
//class TextAsyncStorage: TextStorageProvider {
//    
//    typealias TextLine = TextStorage.Line
//    typealias TextRange = TextStorage.TextRange
//    typealias TextBuffer = TextStorage.TextBuffer
//    typealias TextPosition = TextStorage.TextPosition
//    typealias TextCodeUnit = TextStorage.TextCodeUnit
//    typealias TextEncoding = TextStorage.TextEncoding
//    var textStorage: TextStorage
//    
//    var string: TextStorage.TextBuffer {
//        self.textStorage.string
//    }
//    
//    var lines: Array<TextStorage.Line> {
//        self.textStorage.lines
//    }
//    
//    var usedEncoding: TextStorage.TextEncoding {
//        self.textStorage.usedEncoding
//    }
//    
//    var length: Int {
//        self.textStorage.length
//    }
//    
//    func insert(text: TextStorage.TextBuffer, at position: TextStorage.TextPosition, respectComposedCharacter: Bool) throws -> (insertedFirstUnitIndex: TextStorage.TextPosition, movedFirstUnitIndex: TextStorage.TextPosition) {
//        try self.textStorage.insert(text: text, at: position, respectComposedCharacter: respectComposedCharacter)
//    }
//    
//    func delete(range: TextStorage.TextRange) throws -> TextStorage.TextRange {
//        try self.delete(range: range)
//    }
//    
//    func codeUnit(at position: TextStorage.TextPosition) throws -> TextStorage.TextCodeUnit {
//        try self.textStorage.codeUnit(at: position)
//    }
//    
//    func lineContent(unitIndex position: TextStorage.TextPosition) throws -> TextStorage.Line {
//        try self.textStorage.lineContent(unitIndex: position)
//    }
//    
//    func lineIndex(at position: TextStorage.TextPosition) throws -> Int {
//        <#code#>
//    }
//    
//    func enumerateLines(in range: TextStorage.TextRange, reverse: Bool, closure: (TextStorage.Line) -> Bool) throws {
//        <#code#>
//    }
//    
//    
//}
