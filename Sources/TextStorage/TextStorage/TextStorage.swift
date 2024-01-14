//
//  TextStorage.swift
//
//
//  Created by 孟超 on 2024/1/14.
//
#if os(iOS)
import Foundation
import fredbuf


/// 在 `TextEditor` 框架中用于存储文本的类
///
/// 此类使用 PieceTree 数据结构以实现对数级别时间复杂度的文本编辑器后备存储。详情可以查看以下链接：
///
///  `https://code.visualstudio.com/blogs/2018/03/23/text-buffer-reimplementation`
///
///  当前类使用 `UTF-16` 编码，所有和范围、索引有关的操作均是针对 `UTF-16` 编码单元来说的。增删查改的时间复杂度均是 `O(log n)`，但获取整体信息时的时间复杂度是 `O(n)`。
@available(iOS 13.0, *)
open class TextStorage: TextStorageProvider {
    
    /// `UTF-16` 编码单元的索引类型
    ///
    /// 请注意，由于 `UTF-16` 中代理对的存在，一个 `UTF-16` 编码单元不一定对应一个 `Unicode` 字符（以下简称字符），必须通过本类提供的各种方法进行转换。
    typealias TextPosition = Int
    /// 索引 `UTF-16` 编码单元的范围的类型
    ///
    /// 请注意，由于 `UTF-16` 中代理对的存在，一个 `UTF-16` 编码单元不一定对应一个 字符，必须通过本类提供的各种方法进行转换。
    typealias TextRange = Range<TextPosition>
    /// 当前类支持的 `Unicode` 编码
    typealias TextEncoding = AvailableEncoding
    /// 当前类使用的字符串类型
    typealias TextBuffer = String
    /// 当前类使用的文本行类型
    typealias TextLine = Line
    
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
        /// - Parameter lineCount: 所有行的总数
        case lineIndexOutOfRange(lineIndex: Int, lineCount: Int)
        /// 行号范围越界
        ///
        /// - Parameter lineRange: 越界的行编号范围。
        /// - Parameter lineCount: 所有行的总数
        case lineRangeOutOfRange(lineRange: ClosedRange<Int>, lineCount: Int)
    }
    
    /// 当前类中存储的字符串
    ///
    /// 将获取当前类中所有编码单元的有关信息。请注意，该操作将遍历整个内部数据结构，所以较为耗时。
    ///
    /// > 调用本属性的时间复杂度是 `O(n)`。
    public var string: String {
        self.fredBuf.string
    }
    
    /// 当前类中存储的字符串
    ///
    /// 将获取当前类中所有编码单元的有关信息。请注意，该操作将遍历整个内部数据结构，所以较为耗时。
    ///
    /// > 调用本属性的时间复杂度是 `O(n)`。
    public var nsString: NSString {
        self.fredBuf.string as NSString
    }
    
    
    /// 当前类中的所有文本行
    ///
    /// 将获取当前类中所有文本行的有关信息。请注意，该操作将遍历整个内部数据结构，所以较为耗时。
    ///
    /// > 调用本属性的时间复杂度是 `O(n)`。
    open var lines: [Line] {
        if self.length <= 0 {
            return []
        }
        var result = [TextLine]()
        try? self.enumerateLines(in: 0..<self.length, reverse: false) { line in
            result.append(line)
            return true
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
        self.fredBuf.length
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
    
    /// 当前文本存储类支持的换行方式
    ///
    /// 当前类仅支持两种换行方式：CRLF 换行方式与 LF 换行方式。
    ///
    /// > CRLF 换行方式以 `\r\n` 作为换行符，常用于 Windows 等平台。
    ///
    /// > LF 换行方式以 `\n` 作为换行符，常用于 Unix 和现代 macOS 平台。
    public enum LineType: Int {
        /// CRLF 换行符
        ///
        /// 即 `\r\n` 换行符
        case CRLF = 0
        /// LF 换行符
        ///
        /// 即`\n` 换行符
        case LF = 1
        
        /// 当前枚举对应的换行符
        var lineBreak: String {
            switch self {
            case .CRLF:
                return "\r\n"
            case .LF:
                return "\n"
            }
        }
    }

    /// 在当前类中表示文本行的结构体
    ///
    /// 该结构体包含了文本存储中的某个文本行所具有的所有信息，包括行编号、行范围、换行符类型和所包含的字符串。
    ///
    /// > 如果在获取此对象后又对文本存储进行了更改，该结构体的值将无法反映当前的更改。
    public struct Line {
        /// 当前行的行编号
        ///
        /// 行编号总是从 `1` 开始。
        public let index: Int
        /// 当前行的编码单元范围
        ///
        /// 该范围不包含任何换行符
        public let range: Range<Int>
        /// 当前行的实际换行类型
        public let type: LineType
        /// 当前行所包含的文本
        ///
        /// 该字符串不包含换行符
        public let nsString: NSString
        /// 当前行所包含的文本
        ///
        /// 该字符串不包含换行符
        public var string: String {
            self.nsString as String
        }
    }
    
    /// 当前类使用的 PieceTree 后备存储
    private var fredBuf: FredbufObjCBridge
    
    /// 使用指定的文本初始化当前类
    ///
    /// 使用指定的字符串初始化当前类，这将初始化一颗与 Visual Code Studio 相同的 PieceTree 文本存储数据结构以用于在 `O(log n)` 时间复杂度内提供所有的交互操作。
    ///
    /// > 此方法的时间复杂度为 `O(n)`，这是因为把 `Swift` 或者 `Objective-C` 的字符串转换为 C++ 的 `std::u16string` 字符串的时间复杂度是 `O(n)`。
    ///
    /// - Parameter string: 用于初始化的文本
    public init(_ string: String) {
        self.fredBuf = .init(string: string)
    }
    
    /// 使用指定的文本初始化当前类
    ///
    /// 使用指定的字符串初始化当前类，这将初始化一颗与 Visual Code Studio 相同的 PieceTree 文本存储数据结构以用于在 `O(log n)` 时间复杂度内提供所有的交互操作。
    ///
    /// > 此方法的时间复杂度为 `O(n)`，这是因为把 `Swift` 或者 `Objective-C` 的字符串转换为 C++ 的 `std::u16string` 字符串的时间复杂度是 `O(n)`。
    ///
    /// - Parameter string: 用于初始化的文本
    public init(_ string: NSString) {
        self.fredBuf = .init(string: string as String)
    }
    
    /// 使用空文本初始化当前类
    ///
    /// 初始化后，当前类中不含有任何 `UTF-16` 编码单元。
    public init() {
        self.fredBuf = .init()
    }

    /// 在指定的编码单元位置插入文本
    ///
    /// 此方法可能抛出 `Self.IndexError` 错误。
    ///
    /// > 时间复杂度关于 `self.length` 为 `O(log n)`，关于参数的 `text.length` 为 `O(n)`。
    ///
    /// - Parameter text: 想要插入的文本。
    /// - Parameter position: 想要插入的文本的期望字符单元位置。如果该位置位于某个字符对应的字符单元中间，将把该字符所对应的第一个字符单元作为期望字符单元位置。
    /// - Returns: 返回一个元组，元组的第一个分量为插入的文本的第一个编码单元所对应的索引，第二个分量为被后移的文本的第一个编码单元所对应的索引。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误 。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    open func insert(text: NSString, at position: Int) throws -> (Int, Int) {
        guard position >= 0 && position <= self.length else {
            throw Self.IndexError.codeUnitIndexOutOfRange(unitIndex: position, totalRange: 0..<self.length)
        }
        /* 获取对应的文本 */
        let characterRange = self.fredBuf.rangeOfComposedCharacterSequence(at: position)
        self.fredBuf.insertString(text as String, atOffset: characterRange.location)
        return (characterRange.location, characterRange.location + text.length)
    }
    
    /// 在指定的编码单元位置插入文本
    ///
    /// 此方法可能抛出 `Self.IndexError` 错误。
    ///
    /// > 时间复杂度关于 `self.length` 为 `O(1)`，关于参数的 `text.length` 为 `O(n)`。
    ///
    /// - Parameter text: 想要插入的文本。
    /// - Parameter position: 想要插入的文本的期望字符单元位置。如果该位置位于某个字符对应的字符单元中间，将把该字符所对应的第一个字符单元作为期望字符单元位置。
    /// - Returns: 返回一个元组，元组的第一个分量为插入的文本的第一个编码单元所对应的索引，第二个分量为被后移的文本的第一个编码单元所对应的索引。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误 。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    open func insert(text: String, at position: Int) throws -> (Int, Int) {
        try self.insert(text: text as NSString, at: position)
    }
    
    /// 删除指定的编码单元所对应的所有字符
    ///
    /// - Parameter range: 想要删除的编码单元对应的所有字符(含有交集的字符)所对应的编码单元索引范围。长度小于 `1` 时，此方法什么都不做。
    /// - Returns: 返回实际删除的编码单元字符范围，该范围可能比参数对应的范围要大。
    ///
    /// > 当前方法仅在范围越界时抛出 `IndexError` 错误 。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    open func delete(range: Range<Int>) throws -> Range<Int> {
        let nsRange = NSRange(range)
        guard nsRange.length > 0 else {
            return range
        }
        guard nsRange.location >= 0 && nsRange.upperBound <= self.length else {
            throw Self.IndexError.codeUnitRangeOutOfRange(unitRange: range.lowerBound..<range.upperBound, totalRange: 0..<self.length)
        }
        let first = self.fredBuf.rangeOfComposedCharacterSequence(at: nsRange.location).lowerBound
        let end = self.fredBuf.rangeOfComposedCharacterSequence(at: nsRange.upperBound - 1).upperBound
        let length = end - first
        self.fredBuf.remove(at: first, withLength: length)
        return first..<end
    }
    
    /// 获取某个编码单元的索引对应的字符及其对应的编码单元范围
    ///
    /// > 时间复杂度为关于当前编码单元总数的 `O(log n)`。
    /// - Parameter position: 想要获取对应字符的编码单元。该值不能越界，否则将抛出错误。
    /// - Returns: 返回包含对应字符以及对应编码单元的范围的元组。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误 。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    open func character(at position: Int) throws -> (Character, Range<Int>) {
        guard position >= 0 && position < self.length else {
            throw Self.IndexError.codeUnitIndexOutOfRange(unitIndex: position, totalRange: 0..<self.length)
        }
        return self.characterWithoutCheck(at: position)
    }
    
    /// 获取某个编码单元的索引值对应的编码单元
    ///
    /// > 此方法的时间复杂度为关于当前编码单元总数的 `O(log n)`。
    ///
    /// - Parameter position: 想要获取对应编码单元的索引。该值不能越界，否则将抛出错误。
    /// - Returns: 返回对应的编码单元。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误 。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    open func codeUnit(at position: Int) throws -> UInt16 {
        guard position >= 0 && position < self.length else {
            throw Self.IndexError.codeUnitIndexOutOfRange(unitIndex: position, totalRange: 0..<self.length)
        }
        return self.codeUnitWithoutCheck(at: position)
    }
    
    
    /// 获取某个编码单元的索引对应的编码单元
    ///
    /// 此方法不进行指标检查，因此具有更好的性能。
    private func codeUnitWithoutCheck(at position: Int) -> UInt16 {
        self.fredBuf.getCodeUnit(at: position)
    }
    
    /// 获取某个编码单元对应的字符及其对应的编码单元范围
    ///
    /// 该方法不检查索引是否越界，因此性能更高。
    private func characterWithoutCheck(at position: Int) -> (Character, Range<Int>) {
        var actualRange = NSRange()
        let string = self.fredBuf.substringOfComposedCharacterSequence(at: position, withActualRange: &actualRange)
        return (Character(string), actualRange.lowerBound..<actualRange.upperBound)
    }
    
    /// 获取某个编码单元所在的行的所有信息
    ///
    /// > 时间复杂度为关于当前类的编码单元总数的 `O(log n)`。
    /// - Parameter position: 想要获取所在行的信息的编码单元。该值不能越界，否则将抛出错误。
    /// - Returns: 返回编码单元所在行所对应的所有信息。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误 。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    open func lineContent(at position: Int) throws -> Line {
        guard position >= 0 && position < self.length else {
            throw Self.IndexError.codeUnitIndexOutOfRange(unitIndex: position, totalRange: 0..<self.length)
        }
        return self.lineContentWithoutCheck(at: position)
    }
    
    /// 获取某个编码单元所在的行的所有信息
    ///
    /// 本方法不进行任何额外检查，所以可以获取更高的性能。
    private func lineContentWithoutCheck(at position: Int) -> Line {
        let lineIndex = self.lineIndexWithoutCheck(at: position)
        var crlf_type_t: CRLF_Type_t = .init(0) /* CRFL */
        let content = self.fredBuf.getCRFLLineContent(atLineIndex: lineIndex, withActualCRFLType: &crlf_type_t)
        var lineType: LineType = .LF
        if crlf_type_t.rawValue == 0 {
            lineType = .CRLF
        }
        let lineRange = self.fredBuf.getLineRange(atLineIndex: lineIndex, withCRFLType: crlf_type_t)
        return .init(index: lineIndex, range: lineRange.lowerBound..<lineRange.upperBound, type: lineType, nsString: content as NSString)
    }
    
    
    /// 获取某个编码单元所在的行的编号
    ///
    /// 行的编号（又称行号）从 `1` 开始。
    ///
    /// > 时间复杂度为关于当前类的编码单元总数的 `O(log n)`。
    /// - Parameter position: 想要获取所在行的编号的编码单元。该值不能越界，否则将抛出错误。
    /// - Returns: 返回编码单元所在行的编号。
    ///
    /// > 当前方法仅在指标越界时抛出 `IndexError` 错误 。如果你完全确保参数对应的索引不越界，可以考虑使用 `try!` 语法。
    open func lineIndex(at position: Int) throws -> Int {
        guard position >= 0 && position < self.length else {
            throw Self.IndexError.codeUnitIndexOutOfRange(unitIndex: position, totalRange: 0..<self.length)
        }
        return self.lineIndexWithoutCheck(at: position)
    }
    
    /// 获取某个编码单元所在的行的编号
    ///
    /// 本方法不进行任何额外检查，所以具有更高的性能。
    private func lineIndexWithoutCheck(at position: Int) -> Int {
        return self.fredBuf.getLineIndex(at: position)
    }
    
    /// 枚举编码单元的索引范围所在的行
    ///
    /// 这将枚举覆盖所有范围内编码单元的最小行。如果范围越界将抛出错误。
    ///
    /// - Parameter range: 想要枚举所在行的编码单元的索引范围。
    /// - Parameter reverse: 指定是否从行号较大的行逆向地开始枚举，默认为 `false`。
    /// - Parameter closure: 枚举到某个行时执行的闭包，该闭包的返回值指示枚举是否继续，例如返回 `true` 时将继续枚举下一行。
    open func enumerateLines(in range: Range<Int>, reverse: Bool = false, closure: (Line) -> Bool) throws {
        let range = NSRange(range)
        guard range.location >= 0 && range.length >= 0 && range.upperBound <= self.length  else {
            throw Self.IndexError.codeUnitRangeOutOfRange(unitRange: range.lowerBound..<range.upperBound, totalRange: 0..<self.length)
        }
        if range.length <= 0 { return }
        let firstLineIndex = try self.lineIndex(at: range.lowerBound)
        let endLineIndex = try self.lineIndex(at: range.upperBound - 1)
        loop: for i in firstLineIndex...endLineIndex {
            let index = reverse ? endLineIndex + firstLineIndex - i : i
            if closure(self.lineContentWithoutCheck(at: index)) {
                continue loop
            }
            break loop
        }
    }
    
    /// 保存当前的状态以供撤销或者重做
    open func commitState() {
        self.fredBuf.quickCommitState()
    }
    
    /// 撤销到最近的上一个保存的状态
    ///
    /// - Returns: 返回是否成功撤销，`true` 表示撤销成功。
    open func undo() -> Bool {
        let result = self.fredBuf.quickUndo()
        return result.is_success.boolValue
    }
    
    /// 重做到最近的上一个被撤销的状态
    ///
    /// - Returns: 返回是否成功重做，`true` 表示重做成功。
    open func redo() -> Bool {
        let result = self.fredBuf.quickRedo()
        return result.is_success.boolValue
    }
}
#endif
