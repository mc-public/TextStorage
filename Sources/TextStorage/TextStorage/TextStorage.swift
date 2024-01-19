//
//  TextStorage.swift
//
//
//  Created by mc-public on 2024/1/14.
//
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

import Foundation
@_implementationOnly import PieceTree

//MARK: - Properties And Init

/// 在 `TextEditor` 框架中用于存储文本的类
///
/// 此类使用 PieceTree 数据结构以实现对数级别时间复杂度的文本编辑器后备存储。详情可以查看以下链接：
///
///  `https://code.visualstudio.com/blogs/2018/03/23/text-buffer-reimplementation`
///
///  当前类使用 `UTF-16` 编码，所有和范围、索引有关的操作均是针对 `UTF-16` 编码单元来说的。大部分操作的时间复杂度不高于 `O(log n)`，但获取整体信息时的时间复杂度是 `O(n)`。
@available(iOS 13.0, macOS 12.0, *)
public class TextStorage: TextStorageProvider {
    
    /// `UTF-16` 编码单元的索引类型
    ///
    /// 请注意，由于 `UTF-16` 中代理对的存在，一个 `UTF-16` 编码单元不一定对应一个 `Unicode` 字符（以下简称字符），必须通过本类提供的各种方法进行转换。
    typealias TextPosition = Int
    /// 索引 `UTF-16` 编码单元的范围的类型
    ///
    /// 由于 `UTF-16` 代理对，一个 `UTF-16` 编码单元不一定对应一个 字符，必须通过本类提供的各种方法进行转换。
    typealias TextRange = Range<TextPosition>
    /// 当前类支持的 `Unicode` 编码
    typealias TextEncoding = AvailableEncoding
    /// 当前类使用的字符串类型
    typealias TextBuffer = String
    /// 当前类使用的文本行类型
    typealias TextLine = Line
    /// 当前类使用的 `Unicode` 编码的编码单元类型
    typealias TextCodeUnit = UInt16
    /// 当前类使用的 PieceTree 后备存储
    var pieceTree: PieceTreeStorage
    
    /// 当前类中存储的字符串
    ///
    /// 该操作将遍历整个内部数据结构，所以较为耗时。
    ///
    /// > 调用本属性的时间复杂度是 `O(n)`。
    public var string: String {
        self.pieceTree.string
    }
    
    /// 当前类中存储的字符串
    ///
    /// 将获取当前类中所有编码单元的有关信息。请注意，该操作将遍历整个内部数据结构，所以较为耗时。
    ///
    /// > 调用本属性的时间复杂度是 `O(n)`。
    public var nsString: NSString {
        self.pieceTree.string as NSString
    }
    
    
    /// 当前类中的所有文本行
    ///
    /// 将获取当前类中所有文本行的有关信息。请注意，该操作将遍历整个内部数据结构，所以较为耗时。
    ///
    /// > 请注意，如果文本以 `\n` 或者 `\r\n` 结尾，将认为最后一行为空行，仍然将这个空行统计到行的总数中并添加到此列表中。
    ///
    /// > 调用本属性的时间复杂度是 `O(n)`。
    public var lines: [Line] {
        if self.length <= 0 || self.lineCount <= 0 {
            return [.init(index: 1, range: 0..<0, type: .NO, nsString: NSString())]
        }
        var result = [TextLine]()
        for i in 1...self.lineCount {
            guard let line = try? self.lineContent(lineIndex: i) else {
                continue
            }
            result.append(line)
        }
        return result
    }
    /// 当前类所使用的编码
    ///
    /// 本属性只会返回 `utf16`，当前类所使用的编码为 `UTF-16`，这是由多种因素决定的。例如，本类的使用者一定想使用 CoreText 框架去绘制文本，为了方便本类的使用者调用 Cocoa 或者 Cocoa Touch 框架的相关 API。
    public var usedEncoding: AvailableEncoding {
        .utf16
    }
    
    /// 当前类所含有的 `UTF-16` 编码单元的个数
    ///
    /// 当前类内部的 PieceTree 数据结构使用了 `UTF-16` 编码。本属性将返回所包含的 `UTF-16` 编码单元的总数。该值可能为 `0`。
    ///
    /// > 访问此属性的时间复杂度为 `O(1)`。
    public var length: Int {
        self.pieceTree.length
    }
    
    /// 当前类所含有的行的总数
    ///
    /// 该值可能为 `0`。
    ///
    /// > 请注意，如果文本以 `\n` 或者 `\r\n` 结尾，将认为最后一行为空行，仍然将这个空行统计到行的总数中。
    ///
    /// > 访问此属性的时间复杂度为 `O(1)`。
    public var lineCount: Int {
        self.pieceTree.lineCount
    }
    
    /// 当前文本存储类支持的编码方式
    ///
    /// 当前仅支持 UTF-16 编码标准。这是因为当前类的使用者一般会想要使用 CoreText 框架绘制文本，使用 UTF-16 编码格式将更方便 CoreText 框架的使用。
    public enum AvailableEncoding {
        /// UTF-16 编码标准
        ///
        /// 此编码标准使用一个 16 位编码单元或者两个 16 位编码单元表示一个 Unicode 字符。也就是说，UTF-16 编码标准是变长编码。
        case utf16
    }
    
    /// 使用指定的文本初始化当前类
    ///
    /// 使用指定的字符串初始化当前类，这将初始化一颗与 Visual Code Studio 相同的 PieceTree 文本存储数据结构以用于在 `O(log n)` 时间复杂度内提供所有的交互操作。
    ///
    /// > 此方法的时间复杂度为 `O(n)`，这是因为把 `Swift` 或者 `Objective-C` 的字符串转换为 C++ 的 `std::u16string` 字符串的时间复杂度是 `O(n)`。
    ///
    /// - Parameter string: 用于初始化的文本
    public init(_ string: String) {
        self.pieceTree = .init(string: string)
    }
    
    /// 使用指定的文本初始化当前类
    ///
    /// 使用指定的字符串初始化当前类，这将初始化一颗与 Visual Code Studio 相同的 PieceTree 文本存储数据结构以用于在 `O(log n)` 时间复杂度内提供所有的交互操作。
    ///
    /// > 此方法的时间复杂度为 `O(n)`，这是因为把 `Swift` 或者 `Objective-C` 的字符串转换为 C++ 的 `std::u16string` 字符串的时间复杂度是 `O(n)`。
    ///
    /// - Parameter string: 用于初始化的文本
    public init(_ string: NSString) {
        self.pieceTree = .init(string: string as String)
    }
    
    /// 使用空文本初始化当前类
    ///
    /// 初始化后，当前类中不含有任何 `UTF-16` 编码单元。
    public init() {
        self.pieceTree = .init()
    }
    
}

//MARK: - Text And UTF-16 Interaction APIs

@available(iOS 13.0, macOS 12.0, *)
extension TextStorage {
    
    /// 将字符串添加到当前文本存储的最后面
    ///
    /// > 时间复杂度关于被插入的字符串长度是 `O(m)`，关于当前文本存储中所含编码单元的个数为 `O(log n)`。
    public func append(_ string: NSString) {
        _ = self.insertWithoutCheck(text: string, at: self.length, respectComposedCharacter: false)
    }
    
    /// 将字符串添加到当前文本存储的最后面
    ///
    /// > 时间复杂度关于被插入的字符串长度是 `O(m)`，关于当前文本存储中所含编码单元的个数为 `O(log n)`。
    public func append(_ string: String) {
        _ = self.insertWithoutCheck(text: string as NSString, at: self.length, respectComposedCharacter: false)
    }
    
    public static func +=(lhs: TextStorage, right: String) {
        lhs.append(right)
    }
    
    /// 在指定的编码单元位置插入文本
    ///
    /// 此方法可能抛出 `Self.IndexError` 错误。
    ///
    /// > 时间复杂度关于 `self.length` 为 `O(log n)`，关于参数的 `text.length` 为 `O(m)`。
    ///
    /// - Parameter text: 想要插入的文本。
    /// - Parameter position: 想要插入的文本的期望编码单元位置。
    /// - Parameter respectComposedCharacter: 是否按照组合字符的方式进行插入。值为 `true` 时将以组合字符为单位处理插入操作，值为 `false` 时将以编码单元为单位处理插入操作。
    /// - Returns: 返回一个元组，元组的第一个分量为插入的文本的第一个编码单元所对应的索引，第二个分量为被后移的文本的第一个编码单元所对应的索引。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    @discardableResult
    public func insert(text: NSString, at position: Int, respectComposedCharacter: Bool = true) throws -> (insertedFirstUnitIndex: Int, movedFirstUnitIndex: Int) {
        guard position >= 0 && position <= self.length else {
            throw Self.IndexError.codeUnitIndexOutOfRange(unitIndex: position, totalRange: 0..<self.length)
        }
        return self.insertWithoutCheck(text: text, at: position, respectComposedCharacter: respectComposedCharacter)
    }
    
    
    /// 在指定的编码单元位置插入文本
    ///
    /// 此方法可能抛出 `Self.IndexError` 错误。
    ///
    /// > 时间复杂度关于 `self.length` 为 `O(log n)`，关于参数的 `text.length` 为 `O(m)`。
    ///
    /// - Parameter text: 想要插入的文本。
    /// - Parameter position: 想要插入的文本的期望编码单元位置。
    /// - Parameter respectComposedCharacter: 是否按照组合字符的方式进行插入。值为 `true` 时将以组合字符为单位处理插入操作，值为 `false` 时将以编码单元为单位处理插入操作。
    /// - Returns: 返回一个元组，元组的第一个分量为插入的文本的第一个编码单元所对应的索引，第二个分量为被后移的文本的第一个编码单元所对应的索引。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误 。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    @discardableResult
    public func insert(text: String, at position: Int, respectComposedCharacter: Bool = true) throws -> (insertedFirstUnitIndex: Int, movedFirstUnitIndex: Int) {
        try self.insert(text: text as NSString, at: position, respectComposedCharacter: respectComposedCharacter)
    }
    
    
    
    /// 删除指定的编码单元所对应的所有字符
    ///
    /// - Parameter range: 想要删除的编码单元对应的所有字符(含有交集的字符)所对应的编码单元索引范围。长度小于 `1` 时，此方法什么都不做。
    /// - Returns: 返回实际删除的编码单元字符范围，该范围可能比参数对应的范围要大。
    ///
    /// > 当前方法仅在范围越界时抛出 `IndexError` 错误。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    @discardableResult
    public func delete(range: Range<Int>) throws -> Range<Int> {
        let nsRange = NSRange(range)
        guard nsRange.length > 0 else {
            return range
        }
        guard nsRange.lowerBound >= 0 && nsRange.upperBound <= self.length else {
            throw Self.IndexError.codeUnitRangeOutOfRange(unitRange: range, totalRange: 0..<self.length)
        }
        return self.deleteWithoutCheck(range: range)
    }
    
    /// 获取某个编码单元的索引值对应的编码单元
    ///
    /// > 此方法的时间复杂度为关于当前编码单元总数的 `O(log n)`。
    ///
    /// - Parameter position: 想要获取对应编码单元的索引。该值不能越界，否则将抛出错误。
    /// - Returns: 返回对应的编码单元。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误 。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    public func codeUnit(at position: Int) throws -> UInt16 {
        guard position >= 0 && position < self.length else {
            throw Self.IndexError.codeUnitIndexOutOfRange(unitIndex: position, totalRange: 0..<self.length)
        }
        return self.codeUnitWithoutCheck(at: position)
    }
    
    
    /// 获取某个编码单元的索引对应的字符及其对应的编码单元范围
    ///
    /// > 时间复杂度为关于当前编码单元总数的 `O(log n)`。
    /// - Parameter position: 想要获取对应字符的编码单元。该值不能越界，否则将抛出错误。
    /// - Parameter composeCRLFCharacter: 是否把 `\r\n` 组合为一个字符，默认值为 `false`。值为 `false` 时此方法返回的范围与 `NSString` 的 `rangeOfComposedCharacterSequence` 方法返回的范围相同。
    /// - Returns: 返回包含对应字符以及对应编码单元的范围的元组。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    public func character(at position: Int, composeCRLFCharacter: Bool = false) throws -> (character: Character, range: Range<Int>) {
        guard position >= 0 && position < self.length else {
            throw Self.IndexError.codeUnitIndexOutOfRange(unitIndex: position, totalRange: 0..<self.length)
        }
        return self.characterWithoutCheck(at: position, composeCRLFCharacter: composeCRLFCharacter)
    }
    
}

//MARK: - Line APIs

@available(iOS 13.0, macOS 12.0, *)
extension TextStorage {
    
    /// 获取某个编码单元所在的行的所有信息
    ///
    /// > 时间复杂度为关于当前类的编码单元总数的 `O(log n)`。
    /// - Parameter position: 想要获取所在行的信息的编码单元。该值不能越界，否则将抛出错误。
    /// - Returns: 返回编码单元所在行所对应的所有信息。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    public func lineContent(unitIndex position: Int) throws -> Line {
        guard position >= 0 && position < self.length else {
            throw Self.IndexError.codeUnitIndexOutOfRange(unitIndex: position, totalRange: 0..<self.length)
        }
        return self.lineContentWithoutCheck(unitIndex: position)
    }
    
    
    /// 获取某行编号所对应的行的所有信息
    ///
    /// > 时间复杂度为关于当前类的编码单元总数的 `O(log n)`。
    /// - Parameter position: 想要获取所在行的信息的行编号。该值不能越界，否则将抛出错误。
    /// - Returns: 返回此行所对应的所有信息。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    public func lineContent(lineIndex: Int) throws -> Line {
        guard lineIndex >= 1 && lineIndex <= self.lineCount else {
            throw Self.IndexError.lineIndexOutOfRange(lineIndex: lineIndex, lineCount: self.lineCount)
        }
        return self.lineContentWithoutCheck(lineIndex: lineIndex)
    }
    
    
    /// 获取某个编码单元所在的行的编号
    ///
    /// 行的编号（又称行号）从 `1` 开始。
    ///
    /// > 时间复杂度为关于当前类的编码单元总数的 `O(log n)`。
    /// - Parameter position: 想要获取所在行的编号的编码单元。该值不能越界，否则将抛出错误。
    /// - Returns: 返回编码单元所在行的编号。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    public func lineIndex(at position: Int) throws -> Int {
        guard position >= 0 && position < self.length else {
            throw Self.IndexError.codeUnitIndexOutOfRange(unitIndex: position, totalRange: 0..<self.length)
        }
        return self.lineIndexWithoutCheck(at: position)
    }
    
    
    
    /// 枚举编码单元的索引范围所在的行
    ///
    /// 这将枚举覆盖所有范围内编码单元的最小行。如果范围越界将抛出错误。
    ///
    /// - Parameter range: 想要枚举所在行的编码单元的索引范围。
    /// - Parameter reverse: 指定是否从行号较大的行逆向地开始枚举，默认为 `false`。
    /// - Parameter closure: 枚举到某个行时执行的闭包，该闭包的返回值指示枚举是否继续，例如返回 `true` 时将继续枚举下一行。
    public func enumerateLines(in range: Range<Int>, reverse: Bool = false, closure: (Line) -> Bool) throws {
        let nsRange = NSRange(range)
        guard nsRange.location >= 0 && nsRange.length >= 0 && nsRange.upperBound <= self.length  else {
            throw Self.IndexError.codeUnitRangeOutOfRange(unitRange: nsRange.lowerBound..<nsRange.upperBound, totalRange: 0..<self.length)
        }
        self.enumerateLinesWithoutCheck(in: range, reverse: reverse, closure: closure)
    }
    
}


//MARK: - Undo And Redo APIs

@available(iOS 13.0, macOS 12.0, *)
extension TextStorage {
    
    /// 保存当前的状态以供撤销或者重做
    public func commitState() {
        self.pieceTree.quickCommitState()
    }
    
    /// 撤销到最近的上一个保存的状态
    ///
    /// - Returns: 返回是否成功撤销，`true` 表示撤销成功。
    public func undo() -> Bool {
        let result = self.pieceTree.quickUndo()
        return result.is_success.boolValue
    }
    
    /// 重做到最近的上一个被撤销的状态
    ///
    /// - Returns: 返回是否成功重做，`true` 表示重做成功。
    public func redo() -> Bool {
        let result = self.pieceTree.quickRedo()
        return result.is_success.boolValue
    }
    
    
    /// 复制一份当前的文本存储
    ///
    /// > 时间复杂度关于当前文本存储中所含编码单元的个数为 `O(n)`。
    ///
    /// - Returns: 复制后得到文本存储对象，它与原来的文本存储对象不是一个实例。
    public func copy() -> TextStorage {
        return .init(self.nsString)
    }
}
