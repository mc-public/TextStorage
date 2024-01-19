//
//  TextStorageProvider.swift
//
//
//  Created by mc-public on 2024/1/6.
//

/**
 在 `TextEditor` 框架中提供文本存储的类所应当遵循的协议
 */
@available(iOS 13.0, macOS 12.0, *)
protocol TextStorageProvider: AnyObject {
    /**
     表示视觉上的文本行的关联类型
     */
    associatedtype TextLine
    /**
     在当前协议中表示文本范围的关联类型
     */
    associatedtype TextRange
    /**
     在当前协议中表示文本序列的关联类型
     */
    associatedtype TextBuffer
    /**
     在当前协议中表示某个 **编码单元** 对应的文本位置的关联类型
     
     > 请将其理解为 `Unicode` 编码单元，不能理解为用户可见的直观字符。
     */
    associatedtype TextPosition
    /**
     在当前协议中表示某个 **编码单元** 的关联类型
     */
    associatedtype TextCodeUnit
    /**
     在当前协议中表示文本编码的关联类型
     */
    associatedtype TextEncoding
    /**
     当前文本存储类所操作的文本
     
     实现本协议的类应当提供本属性以获取当前文本存储类所存储的所有纯文本内容。访问此属性时应当提供实际文本内容的副本。
     
     
     > 根据实现本协议时的不同方法（例如使用较为简单的数据结构（如 LineArray）实现本协议），获取本属性的值可能很耗时。
     */
    var string: TextBuffer { get }
    
    /**
     当前文本存储类所存储的所有行内容
     
     实现本协议的类应当提供本属性以获取当前文本存储类所存储的所有纯文本内容。
     */
    var lines: Array<TextLine> { get }
    
    /**
     获取文本的 `Unicode` 编码方式
     
     实现本协议的类应当实现本方法以提供当前类的 `Unicode` 编码方式。
     
     > 为了方便与 Cocoa 框架交互，我们强烈建议本协议的实现者使用 `UTF-16` 编码。
     
     > 实现本协议的类应当谨慎处理 `Unicode` 编码。请注意，`Unicode` 编码非常复杂。例如，可能出现两个 21 位 `Unicode` 标量对应一个字符（如 emoji 表情，这种情况下无法避免地会用两个 `UTF-16` 单元（一般为 16 位无符号整型）表示这个表情）。为了提升性能，实现本协议的类可以考虑在这些方面进行一些取舍。
     */
    var usedEncoding: TextEncoding { get }
    
    /**
     当前文本存储类所包含的编码单元的数量
     */
    var length: Int { get }
    
    //MARK: - 文本的增删查
    
    /**
     插入带有属性的文本
     
     实现本协议的类应当实现以下的两个方法，以在指定的指标位置对应的字符 **之前** 和 **之后** 插入文本。
     
     - Parameter text: 想要插入到指定编码位置的文本。
     - Parameter position: 插入文本时的锚点字符。插入后的文本的第一个字符将位于此位置所表示的字符或者编码单元处，原先在此位置及其后面的所有字符或者编码单元均会被后移至被插入的字符串的后边。
     - Parameter respectComposedCharacter: 是否按照组合字符的方式进行插入。值为 `true` 时将以组合字符为单位处理插入操作，值为 `false` 时将以编码单元为单位处理插入操作。
     - Returns: 返回插入的字符串的起始编码单元的实际位置以及被后移的文本的起始编码单元的实际位置所组成的元组。
     
     > 实现此方法时应在范围越界时抛出相应的错误，除此之外的错误应当触发断言。
     */
    func insert(text: TextBuffer, at position: TextPosition, respectComposedCharacter: Bool) throws -> (insertedFirstUnitIndex: TextPosition, movedFirstUnitIndex: TextPosition)
    
    /**
     删除指定范围的文本
     
     实现本协议的类应当实现此方法以移除与参数所对应的编码单元有交集的所有字符。
     
     - Parameter range: 想要删除的文本的编码单元范围
     - Returns: 实际删除的编码单元范围，该范围可能比参数指定的范围要大。
     
     > 实现此方法时应在范围越界时抛出相应的错误，除此之外的错误应当触发断言。
     */
    func delete(range: TextRange) throws -> TextRange
    
    /**
     获取指定索引处的编码单元
     
     - Parameter position: 想要获取对应的编码单元的索引
     - Returns: 返回索引所对应的编码单元
     
     > 实现此方法时应在范围越界时抛出相应的错误，除此之外的错误应当触发断言。
     */
    func codeUnit(at position: TextPosition) throws -> TextCodeUnit
    
    //MARK: - 和文本行交互的 API
    
    /**
     获取指定行号的文本的内容
     
     > **我们假设行号从 `0` 开始**（而不是类似于 Xcode 的代码编辑器的行号一样从 `1` 开始）。
     
     实现本协议的类需要实现本方法以获取指定行索引处的行内容。
     
     > 实现此方法时应在文本位置非法或者越界时抛出相应的错误，除此之外的错误应当触发断言。
     */
    func lineContent(unitIndex position: TextPosition) throws -> TextLine
    
    
    /**
     获取指定字符所在的行的行号
     
     > 实现此方法时应在文本位置非法或者越界时抛出相应的错误，除此之外的错误应当触发断言。
     */
    func lineIndex(at position: TextPosition) throws -> Int
    
    
    /**
     枚举覆盖了指定范围的最小数量的行对象
     
     实现本协议的类需要实现本方法以提供枚举指定范围内所有行的功能。实现本方法时每一个 `TextLine` 只能被调用一次参数的闭包。
     
     > 实现此方法时应在文本范围非法或者越界时抛出相应的错误，除此之外的错误应当触发断言。
     
     - Parameter range: 需要枚举所在行的文本范围。
     - Parameter reverse: 是否反向地进行枚举，否则将按照文本范围中字符的默认顺序进行枚举。
     - Parameter closure: 枚举过程中每次枚举到新的 `TextLine` 对象时执行的闭包，该闭包的返回值指示是否继续执行下一次枚举操作。
     */
    func enumerateLines(in range: TextRange, reverse: Bool, closure: (TextLine) -> Bool) throws
    
}



