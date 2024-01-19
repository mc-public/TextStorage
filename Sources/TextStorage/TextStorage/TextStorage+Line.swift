//
//  TextStorage+LineType.swift
//  
//
//  Created by mc-public on 2024/1/18.
//

import Foundation
@_implementationOnly import PieceTree

@available(iOS 13.0, macOS 12.0, *)
extension TextStorage {
    
    /// 当前文本存储类支持的换行方式
    ///
    /// 当前类仅支持两种换行方式：CRLF 换行方式与 LF 换行方式。
    ///
    /// > CRLF 换行方式以 `\r\n` 作为换行符，常用于 Windows 等平台。
    ///
    /// > LF 换行方式以 `\n` 作为换行符，常用于 Unix 和现代 macOS 平台。
    public enum LineType: Int {
        /// 当前行的末端为 CRLF 换行符
        ///
        /// 即 `\r\n` 换行符
        case CRLF = 0
        /// 当前行的末端为 LF 换行符
        ///
        /// 即`\n` 换行符
        case LF = 1
        /// 当前行的末端没有换行符
        ///
        /// 即该行的行尾没有换行符，仅见于最后一行。
        case NO
        /// 当前枚举对应的换行符
        var lineBreak: String {
            switch self {
            case .CRLF:
                return "\r\n"
            case .LF:
                return "\n"
            case .NO:
                return ""
            }
        }
        
        static func fromBridge(_ type: CRLF_Type_t) -> Self {
            switch type.rawValue {
                case 0: return .LF
                case 1: return .CRLF
                case 2: return .NO
                default:
                    fatalError()
            }
        }
        
    }

    /// 在当前类中表示文本行的结构体
    ///
    /// 该结构体包含了文本存储中的某个文本行所具有的所有信息，包括行编号、行范围、换行符类型和所包含的字符串。
    ///
    /// > 如果在获取此对象后又对文本存储进行了更改，该结构体的值将无法反映当前的更改。
    public struct Line: CustomStringConvertible {
        /// 调试信息
        public var description: String {
            "Line[\(self.index)](range: \(self.range), type:\(self.type), stringLength: \(self.nsString.length), string: \(self.string))"
        }
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
    
}
