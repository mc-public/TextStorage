//
//  TextStorage+Error.swift
//
//
//  Created by mc-public on 2024/1/18.
//

import Foundation

@available(iOS 13.0, macOS 12.0, *)
extension TextStorage {
    
    /// 本类可能抛出的所有索引级别错误
    public enum IndexError: Error {
        /// 编码单元的索引越界
        ///
        /// - Parameter unitIndex: 越界的索引。
        /// - Parameter totalRange: 可用的索引的范围。
        case codeUnitIndexOutOfRange(unitIndex: Int, totalRange: Range<Int>)
        /// 编码单元的范围越界
        ///
        /// - Parameter unitRange: 越界的索引范围。
        /// - Parameter totalRange:  可用的索引的范围。
        case codeUnitRangeOutOfRange(unitRange: Range<Int>, totalRange: Range<Int>)
        /// 行编号越界
        ///
        /// - Parameter lineIndex: 越界的行编号。
        /// - Parameter lineCount: 当前文本存储中所含有的行的总数。
        case lineIndexOutOfRange(lineIndex: Int, lineCount: Int)
        /// 行号范围越界
        ///
        /// - Parameter lineRange: 越界的行编号范围。
        /// - Parameter lineCount: 当前文本存储中所含有的行的总数。
        case lineRangeOutOfRange(lineRange: ClosedRange<Int>, lineCount: Int)
    }
}
