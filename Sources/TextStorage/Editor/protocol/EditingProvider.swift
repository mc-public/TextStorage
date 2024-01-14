//
//  CodeEditorProvider.swift
//
//
//  Created by 孟超 on 2023/12/28.
//

import Foundation

/// 提供可编辑操作的类所应当遵循的协议
protocol EditingProvider: AnyObject {
    
    /// 当前编辑器是否使用智能缩进判断
    var usingAutomaticIndent: Bool { get set }
    
    /// 当前编辑器是否使用语法高亮功能
    var usingSyntaxHighlight: Bool { get set }
    
    /// 当前编辑器是否使用自动补全功能
    var usingAutomaticCompletion: Bool { get set }
    
    /// 当前编辑器提供的补全命令列表
    
    
    
    /// 当前代码编辑器中存储的所有文本
    ///
    ///
    var text: String { get }
    
    /// 当前代码编辑器的抽象光标位置
    ///
    /// 遵循本协议的类应当维护一个抽象光标位置，在对编辑器进行相关的文本插入等操作时均依赖于此位置。
    var caretPosition: CaretPositionProvider { get }
    
    /// 当前代码编辑器拥有的总行数
    ///
    /// 实现本属性时应当保证，该值在每次更改了文本以后都会进行相应的更新。
    var lineCount: Int { get }
    
    /// 设置当前编辑器的光标位置
    ///
    /// - Parameter newPosition: 想要设置的目标位置。实现本方法时应注意，在给出不合法值时应当返回 `false`，而不是预先假设调用本类的客户端永远按照正确的参数范围调用本方法。
    /// - Returns: 返回设置的结果，`false` 表示设置失败。
    func setCaret(to newPosition: CaretPositionProvider) -> Bool
    
    /// 获取某行的具体文本内容
    ///
    /// - Parameter lineIndex: 想要获取文本内容的行指标。该指标基于 `0`。 实现本方法时应注意，在给出不合法值时应当返回 `nil`。
    /// 实现本协议的类应当实现本方法以提供某个行的所在信息。为了排版器的效率，调用此方法的时间复杂度应在 `O(log n)` 以内。
    func lineContent(for lineIndex: Int) -> String?
    
    
    /// 在当前光标处执行抽象的插入操作
    ///
    /// -
    func insert(_ text: String)
    
    
}
