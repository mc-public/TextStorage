//
//  String+Lines.swift
//
//
//  Created by mc-public on 2024/1/18.
//

import Foundation

extension String {
    /// Get line count by LineFeed character `\n`.
    ///
    /// Time complexity is `O(n)`.
    var lineCount: Int {
        var lineNumberResult = 1
        if self.utf16.count == 0 {
            lineNumberResult = 1
        } else {
            for index in 0..<self.utf16.count {
                if (self as NSString).character(at: index) == 10 {
                    lineNumberResult += 1
                }
            }
        }
        return lineNumberResult
    }
    /// Get lines by LineFeed character `\n`.
    ///
    /// Time complexity is `O(n)`.
    var lines: [String] {
        var lineResult = [String]()
        guard self.utf16.count > 0 else {
            lineResult = [""]
            return lineResult
        }
        /* Get All Line Break Index */
        var lineFeedIndexs = [Int]()
        for index in 0..<self.utf16.count {
            if (self as NSString).character(at: index) == 10 {
                lineFeedIndexs.append(index)
            }
        }
        var ranges = [NSRange]()
        if (lineFeedIndexs.count == 1) { /* only one LF */
            ranges.append(NSRange(location: 0, length: lineFeedIndexs[0]))
            ranges.append(NSRange(location: lineFeedIndexs[0] + 1, length: self.utf16.count - lineFeedIndexs[0] - 1))
        } else if (lineFeedIndexs.count == 0) { /* no LF */
            ranges.append(NSRange(location: 0, length: self.utf16.count))
        } else { /* a lot of LF */
            ranges.append(NSRange(location: 0, length: lineFeedIndexs[0]))
            for i in 0..<(lineFeedIndexs.count - 1) {
                ranges.append(NSRange(location: lineFeedIndexs[i] + 1, length: lineFeedIndexs[i+1] - lineFeedIndexs[i] - 1))
            }
            ranges.append(NSRange(location: lineFeedIndexs[lineFeedIndexs.count - 1] + 1, length: self.utf16.count - lineFeedIndexs[lineFeedIndexs.count - 1] - 1))
        }
        for (range_index, range) in ranges.enumerated() {
            var lineContent = (self as NSString).substring(with: range) as NSString
            if lineContent.length >= 1 && range_index <= (ranges.count - 2) && lineContent.character(at: lineContent.length - 1) == 13 {
                lineContent = lineContent.substring(with: .init(location: 0, length: lineContent.length - 1)) as NSString
            }
            lineResult.append(lineContent as String)
        }
        return lineResult
    }
}


extension NSString {
    func rangeOfComposedCharacterSequence_CRLF(at index: Int) -> NSRange {
        if index >= 1 && self.character(at: index - 1) == 13 && self.character(at: index) == 10 {
            return NSRange(location: index - 1, length: 2)
        } else if index + 1 < self.length && self.character(at: index) == 13 && self.character(at: index + 1) == 10 {
            return NSRange(location: index, length: 2)
        } else {
            return self.rangeOfComposedCharacterSequence(at: index)
        }
    }
}
