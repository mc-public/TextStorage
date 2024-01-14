//
//  CaretPositionProvider.swift
//  
//
//  Created by 孟超 on 2023/12/29.
//

import Foundation

/// 抽象代码编辑器中的光标位置所应当遵循的协议
///
/// 我们假定光标用行与列进行衡量，而不是基于文本的线性位置。
protocol CaretPositionProvider {
    /// 当前位置所存储的行信息
    ///
    /// 以 `0` 为开始值。值为 `0` 时，列的值也必定是 `0`，此时表示文本内容为空。
    var line: Int { get }
    /// 当前位置所存储的列信息
    ///
    /// 以 `0` 为开始值。值为 `0` 时表示光标位于某一行的最左侧。
    var column: Int { get }
}
